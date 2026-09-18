import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateProfileDto } from './dto/update-profile.dto';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async me(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { profile: true, preferences: true, notifPrefs: true },
    });
    if (!user || user.deletedAt) throw new NotFoundException('User not found.');
    return this.serialize(user);
  }

  async updateProfile(userId: string, dto: UpdateProfileDto) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user || user.deletedAt) throw new NotFoundException('User not found.');

    await this.prisma.$transaction([
      this.prisma.user.update({
        where: { id: userId },
        data: { name: dto.name },
      }),
      this.prisma.profile.upsert({
        where: { userId },
        create: {
          userId,
          gender: dto.gender,
          city: dto.city,
          currency: dto.currency,
          monthlyBudget: dto.monthlyBudget,
          sizeInfo: dto.sizeInfo,
          aiPersonalizationOn: dto.aiPersonalizationOn,
        },
        update: {
          gender: dto.gender,
          city: dto.city,
          currency: dto.currency,
          monthlyBudget: dto.monthlyBudget,
          sizeInfo: dto.sizeInfo,
          aiPersonalizationOn: dto.aiPersonalizationOn,
        },
      }),
      this.prisma.stylePreference.upsert({
        where: { userId },
        create: {
          userId,
          favoriteColors: dto.favoriteColors ?? [],
          preferredOccasions: dto.preferredOccasions ?? [],
        },
        update: {
          favoriteColors: dto.favoriteColors,
          preferredOccasions: dto.preferredOccasions,
        },
      }),
    ]);

    return this.me(userId);
  }

  private serialize(user: any) {
    return {
      id: user.id,
      name: user.name,
      email: user.email,
      isGuest: user.isGuest,
      emailVerified: user.emailVerified,
      profile: user.profile,
      preferences: user.preferences,
      notificationPreferences: user.notifPrefs,
    };
  }
}
