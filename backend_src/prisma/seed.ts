/**
 * Seed script — populates ONLY safe, non-sensitive lookup/demo data:
 *  1. WardrobeCategory: canonical category list used by the Flutter
 *     frontend's category pickers and by WardrobeService/ShopGapService
 *     for consistent categoryName matching.
 *  2. A small number of REAL-STRUCTURE demo Retailer + Product rows,
 *     clearly market as Addis Ababa-based placeholder entries. These
 *     exist so Shop-the-Gap has something genuine to link to in
 *     development — they are NOT real retailer integrations and are
 *     explicitly labelled as such (isVerified: false). No user data,
 *     no credentials, no fabricated pricing claims are made — prices
 *     are clearly illustrative ETB figures for local dev/demo only.
 *
 * Run with: npx prisma db seed  (configured via package.json "prisma.seed")
 */
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

const CATEGORIES: { name: string; slotGroup: string; sortOrder: number }[] = [
  { name: 'Tops', slotGroup: 'Top', sortOrder: 1 },
  { name: 'Shirts', slotGroup: 'Top', sortOrder: 2 },
  { name: 'T-Shirts', slotGroup: 'Top', sortOrder: 3 },
  { name: 'Blouses', slotGroup: 'Top', sortOrder: 4 },
  { name: 'Sweaters', slotGroup: 'Top', sortOrder: 5 },
  { name: 'Bottoms', slotGroup: 'Bottom', sortOrder: 6 },
  { name: 'Trousers', slotGroup: 'Bottom', sortOrder: 7 },
  { name: 'Jeans', slotGroup: 'Bottom', sortOrder: 8 },
  { name: 'Skirts', slotGroup: 'Bottom', sortOrder: 9 },
  { name: 'Shorts', slotGroup: 'Bottom', sortOrder: 10 },
  { name: 'Dresses', slotGroup: 'Other', sortOrder: 11 },
  { name: 'Outerwear', slotGroup: 'Outerwear', sortOrder: 12 },
  { name: 'Jackets', slotGroup: 'Outerwear', sortOrder: 13 },
  { name: 'Coats', slotGroup: 'Outerwear', sortOrder: 14 },
  { name: 'Shoes', slotGroup: 'Shoes', sortOrder: 15 },
  { name: 'Sneakers', slotGroup: 'Shoes', sortOrder: 16 },
  { name: 'Boots', slotGroup: 'Shoes', sortOrder: 17 },
  { name: 'Bags', slotGroup: 'Bag', sortOrder: 18 },
  { name: 'Accessories', slotGroup: 'Accessories', sortOrder: 19 },
  { name: 'Jewelry', slotGroup: 'Accessories', sortOrder: 20 },
  { name: 'Traditional Wear', slotGroup: 'Other', sortOrder: 21 },
];

async function main() {
  console.log('Seeding WardrobeCategory rows...');
  for (const cat of CATEGORIES) {
    await prisma.wardrobeCategory.upsert({
      where: { name: cat.name },
      create: cat,
      update: { slotGroup: cat.slotGroup, sortOrder: cat.sortOrder },
    });
  }

  console.log('Seeding demo Retailer + Product rows (dev/demo only, isVerified=false)...');
  const retailer = await prisma.retailer.upsert({
    where: { id: '00000000-0000-0000-0000-000000000001' },
    create: {
      id: '00000000-0000-0000-0000-000000000001',
      name: 'Bole Fashion House (Demo)',
      city: 'Addis Ababa',
      country: 'Ethiopia',
      websiteUrl: null,
      isVerified: false,
    },
    update: {},
  });

  const demoProducts: { name: string; category: string; color: string; priceEtb: number }[] = [
    { name: 'Classic Cotton Blazer', category: 'Outerwear', color: 'Navy', priceEtb: 3200 },
    { name: 'Everyday Sneakers', category: 'Shoes', color: 'White', priceEtb: 1800 },
    { name: 'Habesha-Inspired Wrap Dress', category: 'Dresses', color: 'Ivory', priceEtb: 2600 },
    { name: 'Leather Crossbody Bag', category: 'Bags', color: 'Tan', priceEtb: 2100 },
    { name: 'Tailored Chino Trousers', category: 'Bottoms', color: 'Khaki', priceEtb: 1500 },
    { name: 'Lightweight Rain Jacket', category: 'Jackets', color: 'Black', priceEtb: 2400 },
  ];

  for (const p of demoProducts) {
    const existing = await prisma.product.findFirst({
      where: { retailerId: retailer.id, name: p.name },
    });
    if (existing) continue;
    await prisma.product.create({
      data: {
        retailerId: retailer.id,
        name: p.name,
        category: p.category,
        color: p.color,
        priceEtb: p.priceEtb,
        isAvailable: true,
      },
    });
  }

  console.log('Seed complete.');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
