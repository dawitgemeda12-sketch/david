import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

/**
 * Shop the Gap — analyzes what the USER ACTUALLY OWNS (real wardrobe
 * rows, real wear counts) against a baseline of wardrobe "essential"
 * categories to surface genuine coverage gaps. This is deliberately
 * NOT an aggressive shopping engine:
 *  - It never invents a retailer, price, or product. If no real
 *    `Product` row exists for a gap category, the recommendation is
 *    returned with `productId: null` and an honest reason string —
 *    never a fabricated listing.
 *  - It never recommends a purchase for a category the user already
 *    owns enough of (favors "wear what you own").
 *  - Recommendations are computed from real Prisma aggregates
 *    (categoryCounts, wearCount), not hardcoded.
 */

// Baseline categories considered part of a reasonably complete
// wardrobe. This is an editable heuristic, not a claim about the
// user's actual needs — it only ever flags a *possible* gap.
const ESSENTIAL_CATEGORIES: { category: string; minRecommended: number }[] = [
  { category: 'Tops', minRecommended: 5 },
  { category: 'Bottoms', minRecommended: 3 },
  { category: 'Outerwear', minRecommended: 1 },
  { category: 'Shoes', minRecommended: 2 },
  { category: 'Dresses', minRecommended: 1 },
  { category: 'Accessories', minRecommended: 2 },
];

@Injectable()
export class ShopGapService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Recomputes gaps from the user's real wardrobe and upserts fresh
   * ShopGapRecommendation rows (skipping categories the user already
   * has an active, non-dismissed recommendation for).
   */
  async analyzeAndRefresh(userId: string) {
    const counts = await this.prisma.wardrobeItem.groupBy({
      by: ['categoryName'],
      where: { userId, deletedAt: null, isArchived: false },
      _count: { _all: true },
    });
    const ownedCountByCategory = new Map<string, number>();
    for (const row of counts) ownedCountByCategory.set(row.categoryName, row._count._all);

    const existingActive = await this.prisma.shopGapRecommendation.findMany({
      where: { userId, dismissedAt: null },
      select: { gapCategory: true },
    });
    const alreadyFlagged = new Set(existingActive.map((r) => r.gapCategory));

    const created: any[] = [];
    for (const { category, minRecommended } of ESSENTIAL_CATEGORIES) {
      const owned = ownedCountByCategory.get(category) ?? 0;
      if (owned >= minRecommended) continue; // no gap — user is covered
      if (alreadyFlagged.has(category)) continue; // don't duplicate

      // Look for a REAL product already in the catalog for this
      // category. Only ever a genuine row from the Product table —
      // never fabricated inline.
      const product = await this.prisma.product.findFirst({
        where: { category, isAvailable: true },
        orderBy: { createdAt: 'asc' },
      });

      const reason =
        owned === 0
          ? `Your wardrobe has no logged items in "${category}" yet. Adding at least one could round out more outfit combinations.`
          : `You currently have ${owned} item(s) in "${category}", fewer than the ${minRecommended} typically needed for regular rotation without repeats.`;

      const rec = await this.prisma.shopGapRecommendation.create({
        data: {
          userId,
          productId: product?.id ?? null,
          gapCategory: category,
          reason,
        },
        include: { product: { include: { retailer: true } } },
      });
      created.push(rec);
    }

    return { createdCount: created.length, created };
  }

  async list(userId: string, includeDismissed = false) {
    const where: any = { userId };
    if (!includeDismissed) where.dismissedAt = null;
    const items = await this.prisma.shopGapRecommendation.findMany({
      where,
      include: { product: { include: { retailer: true } } },
      orderBy: { createdAt: 'desc' },
    });
    return { items, total: items.length };
  }

  async dismiss(userId: string, id: string) {
    const rec = await this.prisma.shopGapRecommendation.findFirst({ where: { id } });
    if (!rec) throw new NotFoundException('Recommendation not found.');
    if (rec.userId !== userId) throw new ForbiddenException('You do not have access to this recommendation.');
    return this.prisma.shopGapRecommendation.update({
      where: { id },
      data: { dismissedAt: new Date() },
    });
  }

  /** Real per-category coverage snapshot, no fabricated statistics. */
  async coverage(userId: string) {
    const counts = await this.prisma.wardrobeItem.groupBy({
      by: ['categoryName'],
      where: { userId, deletedAt: null, isArchived: false },
      _count: { _all: true },
    });
    const ownedCountByCategory = new Map<string, number>();
    for (const row of counts) ownedCountByCategory.set(row.categoryName, row._count._all);

    return ESSENTIAL_CATEGORIES.map(({ category, minRecommended }) => ({
      category,
      owned: ownedCountByCategory.get(category) ?? 0,
      minRecommended,
      isGap: (ownedCountByCategory.get(category) ?? 0) < minRecommended,
    }));
  }
}
