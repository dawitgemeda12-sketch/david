import { ForbiddenException, Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateOutfitDto } from './dto/create-outfit.dto';
import { UpdateOutfitDto } from './dto/update-outfit.dto';
import { ReplaceOutfitItemsDto } from './dto/replace-outfit-items.dto';
import { QueryOutfitsDto } from './dto/query-outfits.dto';

/**
 * Same ownership pattern as WardrobeService: every read/write is scoped
 * by the authenticated userId. Additionally, when creating/replacing
 * outfit items, every referenced wardrobeItemId is verified to belong
 * to the SAME user before it is attached — otherwise a malicious client
 * could stitch another user's wardrobe items into their own outfit.
 */
@Injectable()
export class OutfitsService {
  constructor(private readonly prisma: PrismaService) {}

  async list(userId: string, query: QueryOutfitsDto) {
    const where: any = { userId, deletedAt: null };
    if (query.occasion) where.occasion = query.occasion;
    if (query.favoritesOnly) where.isFavorite = true;

    const [items, total] = await this.prisma.$transaction([
      this.prisma.outfit.findMany({
        where,
        include: { items: { include: { wardrobeItem: true } } },
        orderBy: { updatedAt: 'desc' },
        take: query.limit ?? 30,
        skip: query.offset ?? 0,
      }),
      this.prisma.outfit.count({ where }),
    ]);
    return { items, total, limit: query.limit ?? 30, offset: query.offset ?? 0 };
  }

  async findOneOwned(userId: string, id: string) {
    const outfit = await this.prisma.outfit.findFirst({
      where: { id, userId, deletedAt: null },
      include: { items: { include: { wardrobeItem: true } } },
    });
    if (!outfit) throw new NotFoundException('Outfit not found.');
    return outfit;
  }

  async create(userId: string, dto: CreateOutfitDto) {
    await this.assertItemsOwnedByUser(userId, dto.items.map((i) => i.wardrobeItemId));

    return this.prisma.outfit.create({
      data: {
        userId,
        name: dto.name,
        occasion: dto.occasion,
        weather: dto.weather,
        notes: dto.notes,
        isFavorite: dto.isFavorite ?? false,
        items: {
          create: dto.items.map((i) => ({ wardrobeItemId: i.wardrobeItemId, slot: i.slot })),
        },
      },
      include: { items: { include: { wardrobeItem: true } } },
    });
  }

  async update(userId: string, id: string, dto: UpdateOutfitDto) {
    await this.assertOwnership(userId, id);
    return this.prisma.outfit.update({
      where: { id },
      data: { ...dto },
      include: { items: { include: { wardrobeItem: true } } },
    });
  }

  async replaceItems(userId: string, id: string, dto: ReplaceOutfitItemsDto) {
    await this.assertOwnership(userId, id);
    await this.assertItemsOwnedByUser(userId, dto.items.map((i) => i.wardrobeItemId));

    // Transaction: delete old links, insert new ones atomically so an
    // outfit is never left with zero items mid-update on failure.
    return this.prisma.$transaction(async (tx) => {
      await tx.outfitItem.deleteMany({ where: { outfitId: id } });
      await tx.outfitItem.createMany({
        data: dto.items.map((i) => ({ outfitId: id, wardrobeItemId: i.wardrobeItemId, slot: i.slot })),
      });
      return tx.outfit.findUnique({
        where: { id },
        include: { items: { include: { wardrobeItem: true } } },
      });
    });
  }

  async toggleFavorite(userId: string, id: string) {
    const outfit = await this.assertOwnership(userId, id);
    return this.prisma.outfit.update({
      where: { id },
      data: { isFavorite: !outfit.isFavorite },
    });
  }

  async remove(userId: string, id: string) {
    await this.assertOwnership(userId, id);
    await this.prisma.outfit.update({ where: { id }, data: { deletedAt: new Date() } });
    return { success: true };
  }

  private async assertOwnership(userId: string, id: string) {
    const outfit = await this.prisma.outfit.findFirst({ where: { id, deletedAt: null } });
    if (!outfit) throw new NotFoundException('Outfit not found.');
    if (outfit.userId !== userId) {
      throw new ForbiddenException('You do not have access to this outfit.');
    }
    return outfit;
  }

  /** Prevents a user from attaching someone else's wardrobe items to their outfit. */
  private async assertItemsOwnedByUser(userId: string, wardrobeItemIds: string[]) {
    const unique = [...new Set(wardrobeItemIds)];
    const owned = await this.prisma.wardrobeItem.findMany({
      where: { id: { in: unique }, userId, deletedAt: null },
      select: { id: true },
    });
    if (owned.length !== unique.length) {
      throw new BadRequestException('One or more wardrobe items are invalid or not owned by you.');
    }
  }
}
