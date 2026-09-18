import {
  BadRequestException,
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import * as crypto from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { AuthProvider } from '@prisma/client';

const BCRYPT_ROUNDS = 12;
const MAX_FAILED_ATTEMPTS = 8;
const FAILED_WINDOW_MINUTES = 15;

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
  ) {}

  // ---------------------------------------------------------------
  // Registration
  // ---------------------------------------------------------------
  async register(dto: RegisterDto, ipAddress?: string) {
    const email = dto.email.trim().toLowerCase();
    const existing = await this.prisma.user.findUnique({ where: { email } });
    if (existing) {
      throw new ConflictException('An account with this email already exists.');
    }

    const passwordHash = await bcrypt.hash(dto.password, BCRYPT_ROUNDS);
    const user = await this.prisma.user.create({
      data: {
        email,
        name: dto.name.trim(),
        passwordHash,
        authProvider: AuthProvider.EMAIL,
        emailVerified: false,
        profile: { create: {} },
        preferences: { create: {} },
        notifPrefs: { create: {} },
      },
    });

    await this.audit(user.id, 'register_success', ipAddress);
    const tokens = await this.issueTokens(user.id, user.email, false, user.isAdmin, ipAddress);
    return { user: this.publicUser(user), ...tokens };
  }

  // ---------------------------------------------------------------
  // Login
  // ---------------------------------------------------------------
  async login(dto: LoginDto, ipAddress?: string) {
    const email = dto.email.trim().toLowerCase();
    await this.assertNotRateLimited(email, ipAddress);

    const user = await this.prisma.user.findUnique({ where: { email } });
    if (!user || !user.passwordHash || user.deletedAt) {
      await this.audit(null, 'login_failed', ipAddress, { email });
      throw new UnauthorizedException('Incorrect email or password.');
    }

    const valid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!valid) {
      await this.audit(user.id, 'login_failed', ipAddress, { email });
      throw new UnauthorizedException('Incorrect email or password.');
    }

    if (!user.isActive) {
      throw new UnauthorizedException('This account has been disabled.');
    }

    await this.audit(user.id, 'login_success', ipAddress);
    const tokens = await this.issueTokens(user.id, user.email, false, user.isAdmin, ipAddress);
    return { user: this.publicUser(user), ...tokens };
  }

  async continueAsGuest(ipAddress?: string) {
    const user = await this.prisma.user.create({
      data: {
        name: 'Guest',
        isGuest: true,
        authProvider: AuthProvider.GUEST,
        profile: { create: {} },
        preferences: { create: {} },
        notifPrefs: { create: {} },
      },
    });
    await this.audit(user.id, 'guest_session_created', ipAddress);
    const tokens = await this.issueTokens(user.id, null, true, false, ipAddress);
    return { user: this.publicUser(user), ...tokens };
  }

  // ---------------------------------------------------------------
  // Google Sign-In (requires GOOGLE_CLIENT_ID configuration)
  // ---------------------------------------------------------------
  async googleLogin(_idToken: string): Promise<never> {
    const clientId = this.config.get<string>('GOOGLE_CLIENT_ID');
    if (!clientId) {
      throw new BadRequestException(
        'Google Sign-In is not configured on this server yet. ' +
          'Set GOOGLE_CLIENT_ID/GOOGLE_CLIENT_SECRET in the backend environment to enable it.',
      );
    }
    // Real implementation (once configured) would verify _idToken via
    // google-auth-library against Google's public certs, then find-or-
    // create a User + AuthIdentity(provider=GOOGLE) row.
    throw new BadRequestException('Google Sign-In verification is not yet implemented.');
  }

  // ---------------------------------------------------------------
  // Token refresh (rotation + reuse detection)
  // ---------------------------------------------------------------
  async refresh(refreshToken: string, ipAddress?: string) {
    let payload: { sub: string };
    try {
      payload = this.jwt.verify(refreshToken, {
        secret: this.config.get<string>('JWT_REFRESH_SECRET'),
      });
    } catch {
      throw new UnauthorizedException('Session expired. Please sign in again.');
    }

    const tokenHash = this.hashToken(refreshToken);
    const session = await this.prisma.session.findFirst({
      where: { userId: payload.sub, refreshTokenHash: tokenHash },
    });

    if (!session || session.revokedAt || session.expiresAt < new Date()) {
      // Reuse of a revoked/expired token is a strong signal of theft —
      // revoke ALL sessions for this user as a precaution.
      if (session) {
        await this.prisma.session.updateMany({
          where: { userId: payload.sub, revokedAt: null },
          data: { revokedAt: new Date() },
        });
        await this.audit(payload.sub, 'refresh_reuse_detected', ipAddress);
      }
      throw new UnauthorizedException('Session expired. Please sign in again.');
    }

    const user = await this.prisma.user.findUnique({ where: { id: payload.sub } });
    if (!user || !user.isActive || user.deletedAt) {
      throw new UnauthorizedException('Session expired. Please sign in again.');
    }

    // Rotate: revoke the used refresh token, issue a brand new pair.
    await this.prisma.session.update({
      where: { id: session.id },
      data: { revokedAt: new Date() },
    });

    const tokens = await this.issueTokens(user.id, user.email, user.isGuest, user.isAdmin, ipAddress);
    return { user: this.publicUser(user), ...tokens };
  }

  async logout(userId: string, refreshToken?: string) {
    if (refreshToken) {
      const tokenHash = this.hashToken(refreshToken);
      await this.prisma.session.updateMany({
        where: { userId, refreshTokenHash: tokenHash, revokedAt: null },
        data: { revokedAt: new Date() },
      });
    } else {
      // No token supplied — revoke all sessions for safety.
      await this.prisma.session.updateMany({
        where: { userId, revokedAt: null },
        data: { revokedAt: new Date() },
      });
    }
    await this.audit(userId, 'logout', undefined);
    return { success: true };
  }

  // ---------------------------------------------------------------
  // Password reset (request never reveals whether an email exists)
  // ---------------------------------------------------------------
  async requestPasswordReset(email: string) {
    const normalized = email.trim().toLowerCase();
    const user = await this.prisma.user.findUnique({ where: { email: normalized } });
    if (!user) {
      return { success: true }; // do not leak account existence
    }
    const rawToken = crypto.randomBytes(32).toString('hex');
    const tokenHash = this.hashToken(rawToken);
    await this.prisma.passwordResetToken.create({
      data: {
        userId: user.id,
        tokenHash,
        expiresAt: new Date(Date.now() + 30 * 60 * 1000), // 30 minutes
      },
    });
    // Production: send `rawToken` via a transactional email provider
    // (never log it, never return it in the API response).
    await this.audit(user.id, 'password_reset_requested');
    return { success: true };
  }

  async confirmPasswordReset(token: string, newPassword: string) {
    const tokenHash = this.hashToken(token);
    const record = await this.prisma.passwordResetToken.findFirst({
      where: { tokenHash, usedAt: null, expiresAt: { gt: new Date() } },
    });
    if (!record) {
      throw new BadRequestException('This reset link is invalid or has expired.');
    }
    const passwordHash = await bcrypt.hash(newPassword, BCRYPT_ROUNDS);
    await this.prisma.$transaction([
      this.prisma.user.update({ where: { id: record.userId }, data: { passwordHash } }),
      this.prisma.passwordResetToken.update({ where: { id: record.id }, data: { usedAt: new Date() } }),
      this.prisma.session.updateMany({ where: { userId: record.userId, revokedAt: null }, data: { revokedAt: new Date() } }),
    ]);
    await this.audit(record.userId, 'password_reset_completed');
    return { success: true };
  }

  async changePassword(userId: string, currentPassword: string, newPassword: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user || !user.passwordHash) {
      throw new BadRequestException('Password change is not available for this account.');
    }
    const valid = await bcrypt.compare(currentPassword, user.passwordHash);
    if (!valid) {
      throw new UnauthorizedException('Current password is incorrect.');
    }
    const passwordHash = await bcrypt.hash(newPassword, BCRYPT_ROUNDS);
    await this.prisma.user.update({ where: { id: userId }, data: { passwordHash } });
    await this.audit(userId, 'password_changed');
    return { success: true };
  }

  // ---------------------------------------------------------------
  // Account deletion (real, cascading — see Prisma onDelete: Cascade)
  // ---------------------------------------------------------------
  async deleteAccount(userId: string) {
    await this.prisma.session.updateMany({ where: { userId }, data: { revokedAt: new Date() } });
    await this.prisma.user.update({
      where: { id: userId },
      data: {
        deletedAt: new Date(),
        isActive: false,
        email: null,
        name: 'Deleted User',
        passwordHash: null,
      },
    });
    // Cascade-configured child rows (wardrobe, outfits, plans, etc.)
    // are removed by the DB when the user row itself is later purged
    // by the scheduled hard-delete job (see backend/README "Privacy").
    await this.audit(userId, 'account_deleted');
    return { success: true };
  }

  // ---------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------
  private async issueTokens(
    userId: string,
    email: string | null,
    isGuest: boolean,
    isAdmin: boolean,
    ipAddress?: string,
  ): Promise<AuthTokens> {
    const payload = { sub: userId, email: email ?? undefined, isGuest, isAdmin };

    const accessToken = this.jwt.sign(payload, {
      secret: this.config.get<string>('JWT_ACCESS_SECRET'),
      expiresIn: this.config.get<string>('JWT_ACCESS_EXPIRES_IN') ?? '15m',
    });
    const refreshExpiresIn = this.config.get<string>('JWT_REFRESH_EXPIRES_IN') ?? '30d';
    const refreshToken = this.jwt.sign(payload, {
      secret: this.config.get<string>('JWT_REFRESH_SECRET'),
      expiresIn: refreshExpiresIn,
    });

    await this.prisma.session.create({
      data: {
        userId,
        refreshTokenHash: this.hashToken(refreshToken),
        ipAddress,
        expiresAt: new Date(Date.now() + this.parseDurationMs(refreshExpiresIn)),
      },
    });

    return { accessToken, refreshToken, expiresIn: 15 * 60 };
  }

  private hashToken(token: string): string {
    return crypto.createHash('sha256').update(token).digest('hex');
  }

  private parseDurationMs(duration: string): number {
    const match = duration.match(/^(\d+)([smhd])$/);
    if (!match) return 30 * 24 * 60 * 60 * 1000;
    const value = parseInt(match[1], 10);
    const unit = match[2];
    const multipliers: Record<string, number> = { s: 1000, m: 60000, h: 3600000, d: 86400000 };
    return value * multipliers[unit];
  }

  private async assertNotRateLimited(email: string, ipAddress?: string) {
    const since = new Date(Date.now() - FAILED_WINDOW_MINUTES * 60 * 1000);
    const recentFailures = await this.prisma.auditLog.count({
      where: {
        action: 'login_failed',
        createdAt: { gt: since },
        metadata: { path: ['email'], equals: email },
      },
    });
    if (recentFailures >= MAX_FAILED_ATTEMPTS) {
      throw new UnauthorizedException('Too many failed attempts. Please try again later.');
    }
  }

  private async audit(userId: string | null, action: string, ipAddress?: string, metadata?: Record<string, unknown>) {
    await this.prisma.auditLog.create({
      data: { userId: userId ?? undefined, action, ipAddress, metadata: metadata as any },
    });
  }

  private publicUser(user: {
    id: string;
    name: string;
    email: string | null;
    isGuest: boolean;
    emailVerified: boolean;
    authProvider: AuthProvider;
  }) {
    return {
      id: user.id,
      name: user.name,
      email: user.email,
      isGuest: user.isGuest,
      emailVerified: user.emailVerified,
      authProvider: user.authProvider,
    };
  }
}
