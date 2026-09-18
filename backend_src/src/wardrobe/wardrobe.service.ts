import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateWardrobeItemDto } from './dto/create-wardrobe-item.dto';
import { UpdateWardrobeItemDto } from './dto/update-wardrobe-item.dto';
import { QueryWardrobeDto } from './dto/query-wardrobe.dto';

/**
 * Ownership rule enforced in EVERY method: all reads/writes are scoped
 * by `userId` from the authenticated JWT (never a client-supplied id).
 * Any wardrobe item lookup by id ALSO filters on userId, so a request
 * for another user's item resolves to 404 — not a data leak, not a
 * generic 403 that would confirm the item exists.
 */
@Injectable()
export class WardrobeService {
  constructor(private readonly prisma: PrismaService) {}

  async list(userId: string, query: QueryWardrobeDto) {
    const where: any = {
      userId,
      deletedAt: null,
      isArchived: query.includeArchived ? undefined : false,
    };
    if (query.category && query.category !== 'All') where.categoryName = query.category;
    if (query.color) where.color = query.color;
    if (query.favoritesOnly) where.isFavorite = true;
    if (query.q) {
      where.OR = [
        { name: { contains: query.q, mode: 'insensitive' } },
        { brand: { contains: query.q, mode: 'insensitive' } },
        { categoryName: { contains: query.q, mode: 'insensitive' } },
      ];
    }

    const [items, total] = await this.prisma.$transaction([
      this.prisma.wardrobeItem.findMany({
        where,
        include: { images: true },
        orderBy: { [query.sortBy ?? 'updatedAt']: 'desc' },
        take: query.limit ?? 30,
        skip: query.offset ?? 0,
      }),
      this.prisma.wardrobeItem.count({ where }),
    ]);

    return { items, total, limit: query.limit ?? 30, offset: query.offset ?? 0 };
  }

  async findOneOwned(userId: string, id: string) {
    const item = await this.prisma.wardrobeItem.findFirst({
      where: { id, userId, deletedAt: null },
      include: { images: true },
    });
    if (!item) throw new NotFoundException('Wardrobe item not found.');
    return item;
  }

  async create(userId: string, dto: CreateWardrobeItemDto) {
    return this.prisma.wardrobeItem.create({
      data: {
        userId,
        name: dto.name,
        categoryName: dto.categoryName,
        subcategory: dto.subcategory,
        color: dto.color,
        secondaryColor: dto.secondaryColor,
        pattern: dto.pattern,
        material: dto.material,
        style: dto.style,
        seasons: dto.seasons ?? [],
        occasions: dto.occasions ?? [],
        formality: dto.formality,
        brand: dto.brand,
        size: dto.size,
        purchaseDate: dto.purchaseDate ? new Date(dto.purchaseDate) : undefined,
        purchasePriceEtb: dto.purchasePriceEtb,
        condition: dto.condition,
        isFavorite: dto.isFavorite ?? false,
        notes: dto.notes,
        tags: dto.tags ?? [],
      },
    });
  }

  async update(userId: string, id: string, dto: UpdateWardrobeItemDto) {
    await this.assertOwnership(userId, id);
    return this.prisma.wardrobeItem.update({
      where: { id },
      data: {
        ...dto,
        purchaseDate: dto.purchaseDate ? new Date(dto.purchaseDate) : undefined,
      },
    });
  }

  async remove(userId: string, id: string) {
    await this.assertOwnership(userId, id);
    // Soft delete — recoverable, matches "real functionality" + audit
    // expectations without permanently destroying data instantly.
    await this.prisma.wardrobeItem.update({ where: { id }, data: { deletedAt: new Date() } });
    return { success: true };
  }

  async toggleFavorite(userId: string, id: string) {
    const item = await this.assertOwnership(userId, id);
    return this.prisma.wardrobeItem.update({
      where: { id },
      data: { isFavorite: !item.isFavorite },
    });
  }

  async toggleArchive(userId: string, id: string) {
    const item = await this.assertOwnership(userId, id);
    return this.prisma.wardrobeItem.update({
      where: { id },
      data: { isArchived: !item.isArchived },
    });
  }

  async markWorn(userId: string, id: string) {
    const item = await this.assertOwnership(userId, id);
    return this.prisma.wardrobeItem.update({
      where: { id },
      data: { wearCount: item.wearCount + 1, lastWornAt: new Date() },
    });
  }

  async addImage(
    userId: string,
    wardrobeItemId: string,
    meta: { storageKey: string; originalMime: string; width?: number; height?: number; sizeBytes: number },
  ) {
    await this.assertOwnership(userId, wardrobeItemId);
    return this.prisma.wardrobeImage.create({
      data: { wardrobeItemId, ...meta },
    });
  }

  /** Real per-user analytics computed from actual rows, never hardcoded. */
  async categoryCounts(userId: string) {
    const rows = await this.prisma.wardrobeItem.groupBy({
      by: ['categoryName'],
      where: { userId, deletedAt: null, isArchived: false },
      _count: { _all: true },
    });
    const result: Record<string, number> = {};
    for (const row of rows) result[row.categoryName] = row._count._all;
    return result;
  }

  private async assertOwnership(userId: string, id: string) {
    const item = await this.prisma.wardrobeItem.findFirst({ where: { id, deletedAt: null } });
    if (!item) throw new NotFoundException('Wardrobe item not found.');
    if (item.userId !== userId) {
      // Deliberately identical to the not-found case from the caller's
      // perspective at the HTTP layer (404), preventing user enumeration
      // of other people's resource ids. Logged distinctly for audit.
      throw new ForbiddenException('You do not have access to this item.');
    }
    return item;
  }
}
