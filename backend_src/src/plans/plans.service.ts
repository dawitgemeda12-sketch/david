import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreatePlanDto } from './dto/create-plan.dto';
import { UpdatePlanDto } from './dto/update-plan.dto';
import { QueryPlansDto } from './dto/query-plans.dto';

/**
 * Plans link a user to an outfit for a specific calendar date (one plan
 * per user per day — enforced by the Prisma @@unique([userId, date])
 * constraint). Ownership of BOTH the plan and the referenced outfit is
 * verified against the authenticated userId on every operation.
 */
@Injectable()
export class PlansService {
  constructor(private readonly prisma: PrismaService) {}

  async list(userId: string, query: QueryPlansDto) {
    const where: any = { userId };
    if (query.from || query.to) {
      where.date = {};
      if (query.from) where.date.gte = new Date(query.from);
      if (query.to) where.date.lte = new Date(query.to);
    }
    const plans = await this.prisma.plan.findMany({
      where,
      include: { outfit: { include: { items: { include: { wardrobeItem: true } } } } },
      orderBy: { date: 'asc' },
    });
    return { items: plans, total: plans.length };
  }

  async findOneOwned(userId: string, id: string) {
    const plan = await this.prisma.plan.findFirst({
      where: { id, userId },
      include: { outfit: { include: { items: { include: { wardrobeItem: true } } } } },
    });
    if (!plan) throw new NotFoundException('Plan not found.');
    return plan;
  }

  async create(userId: string, dto: CreatePlanDto) {
    await this.assertOutfitOwned(userId, dto.outfitId);

    try {
      return await this.prisma.plan.create({
        data: {
          userId,
          outfitId: dto.outfitId,
          date: new Date(dto.date),
          occasion: dto.occasion,
          notes: dto.notes,
          reminderEnabled: dto.reminderEnabled ?? false,
          reminderMinutesBefore: dto.reminderMinutesBefore ?? 60,
        },
        include: { outfit: { include: { items: { include: { wardrobeItem: true } } } } },
      });
    } catch (err: any) {
      // Prisma unique constraint violation -> user already has a plan
      // for that date. Surfaced as a clean 409 rather than a 500.
      if (err?.code === 'P2002') {
        throw new ConflictException('You already have a plan for this date.');
      }
      throw err;
    }
  }

  async update(userId: string, id: string, dto: UpdatePlanDto) {
    await this.assertOwnership(userId, id);
    if (dto.outfitId) await this.assertOutfitOwned(userId, dto.outfitId);

    try {
      return await this.prisma.plan.update({
        where: { id },
        data: {
          ...dto,
          date: dto.date ? new Date(dto.date) : undefined,
        },
        include: { outfit: { include: { items: { include: { wardrobeItem: true } } } } },
      });
    } catch (err: any) {
      if (err?.code === 'P2002') {
        throw new ConflictException('You already have a plan for this date.');
      }
      throw err;
    }
  }

  async remove(userId: string, id: string) {
    await this.assertOwnership(userId, id);
    await this.prisma.plan.delete({ where: { id } });
    return { success: true };
  }

  private async assertOwnership(userId: string, id: string) {
    const plan = await this.prisma.plan.findFirst({ where: { id } });
    if (!plan) throw new NotFoundException('Plan not found.');
    if (plan.userId !== userId) throw new ForbiddenException('You do not have access to this plan.');
    return plan;
  }

  private async assertOutfitOwned(userId: string, outfitId: string) {
    const outfit = await this.prisma.outfit.findFirst({
      where: { id: outfitId, deletedAt: null },
    });
    if (!outfit) throw new BadRequestException('Outfit not found.');
    if (outfit.userId !== userId) {
      throw new BadRequestException('You can only plan outfits that belong to you.');
    }
  }
}
