import { Injectable } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';

export interface JwtPayload {
  sub: string; // userId
  email?: string;
  isGuest: boolean;
  isAdmin: boolean;
}

/**
 * Validates the short-lived ACCESS token on every protected request.
 * Only the payload's `sub` (user id) is trusted — never any user id
 * supplied elsewhere in the request body/query.
 */
@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy, 'jwt') {
  constructor(config: ConfigService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: config.get<string>('JWT_ACCESS_SECRET')!,
    });
  }

  async validate(payload: JwtPayload) {
    return { id: payload.sub, email: payload.email, isGuest: payload.isGuest, isAdmin: payload.isAdmin };
  }
}
