import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { QueryNotificationsDto } from './dto/query-notifications.dto';
import { UpdateNotificationPrefsDto } from './dto/update-notification-prefs.dto';
import { RegisterDeviceTokenDto } from './dto/register-device-token.dto';

/**
 * Notifications are currently generated server-side by other modules
 * (plan reminders, wardrobe-gap alerts) via `create()`, and delivered
 * to the client on-demand through this list API. Device tokens are
 * stored so a FUTURE push-delivery worker (FCM/APNs) can target
 * specific devices — no push is actually sent yet (no spam, no
 * unimplemented promises), this is purely the storage/preference layer
 * requested by the spec ("architecture ready for future push").
 */
@Injectable()
export class NotificationsService {
  constructor(private readonly prisma: PrismaService) {}

  async list(userId: string, query: QueryNotificationsDto) {
    // Simple, index-friendly query: filter by userId (and optionally
    // isRead, which is covered by the existing [userId, isRead] index),
    // then sort/paginate. No orderBy+where combination requires a new
    // composite index beyond what's already declared in schema.prisma.
    const where: any = { userId };
    if (query.unreadOnly) where.isRead = false;

    const [items, total] = await this.prisma.$transaction([
      this.prisma.notification.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        take: query.limit ?? 30,
        skip: query.offset ?? 0,
      }),
      this.prisma.notification.count({ where }),
    ]);
    return { items, total, limit: query.limit ?? 30, offset: query.offset ?? 0 };
  }

  async unreadCount(userId: string) {
    const count = await this.prisma.notification.count({ where: { userId, isRead: false } });
    return { count };
  }

  async create(userId: string, data: { title: string; body: string; type: string }) {
    return this.prisma.notification.create({
      data: { userId, title: data.title, body: data.body, type: data.type },
    });
  }

  async markRead(userId: string, id: string) {
    const notif = await this.prisma.notification.findFirst({ where: { id } });
    if (!notif) throw new NotFoundException('Notification not found.');
    if (notif.userId !== userId) throw new ForbiddenException('You do not have access to this notification.');
    return this.prisma.notification.update({ where: { id }, data: { isRead: true } });
  }

  async markAllRead(userId: string) {
    const result = await this.prisma.notification.updateMany({
      where: { userId, isRead: false },
      data: { isRead: true },
    });
    return { updated: result.count };
  }

  async remove(userId: string, id: string) {
    const notif = await this.prisma.notification.findFirst({ where: { id } });
    if (!notif) throw new NotFoundException('Notification not found.');
    if (notif.userId !== userId) throw new ForbiddenException('You do not have access to this notification.');
    await this.prisma.notification.delete({ where: { id } });
    return { success: true };
  }

  // --- Preferences ---

  async getPreferences(userId: string) {
    const prefs = await this.prisma.notificationPreference.upsert({
      where: { userId },
      create: { userId },
      update: {},
    });
    return prefs;
  }

  async updatePreferences(userId: string, dto: UpdateNotificationPrefsDto) {
    return this.prisma.notificationPreference.upsert({
      where: { userId },
      create: { userId, ...dto },
      update: { ...dto },
    });
  }

  // --- Device tokens (future push delivery) ---

  async registerDeviceToken(userId: string, dto: RegisterDeviceTokenDto) {
    // Token is globally unique; if the same physical device token was
    // previously registered by another account (e.g. app reinstall
    // under a different login), re-associate it with the current user
    // rather than erroring — this mirrors typical FCM re-registration
    // handling and avoids leaking a 409 that reveals another account's
    // presence.
    return this.prisma.deviceToken.upsert({
      where: { token: dto.token },
      create: { userId, token: dto.token, platform: dto.platform },
      update: { userId, platform: dto.platform, lastSeenAt: new Date() },
    });
  }

  async removeDeviceToken(userId: string, token: string) {
    const existing = await this.prisma.deviceToken.findUnique({ where: { token } });
    if (!existing || existing.userId !== userId) {
      // Idempotent from the caller's perspective — nothing to do if it
      // doesn't exist or already isn't theirs.
      return { success: true };
    }
    await this.prisma.deviceToken.delete({ where: { token } });
    return { success: true };
  }
}
