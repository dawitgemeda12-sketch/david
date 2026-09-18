import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from './../src/app.module';
import { PrismaService } from './../src/prisma/prisma.service';

/**
 * SECURITY-CRITICAL end-to-end test: verifies that one authenticated
 * user ("User A") can NEVER read, modify, delete, or otherwise access
 * another authenticated user's ("User B") private data — the core
 * ownership-boundary requirement of the whole backend.
 *
 * Runs against the REAL configured Postgres database (via PrismaService
 * from the actual AppModule) — not a mock — so it genuinely exercises
 * WardrobeService/OutfitsService/PlansService's `assertOwnership` logic
 * end-to-end through HTTP, exactly as a real attacker would.
 */
describe('Cross-user data isolation (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  const rand = () => Math.random().toString(36).slice(2, 10);
  const emailA = `isoA_${rand()}@example.com`;
  const emailB = `isoB_${rand()}@example.com`;
  const password = 'Passw0rd123';

  let tokenA: string;
  let tokenB: string;
  let userAId: string;
  let userBId: string;
  let wardrobeItemAId: string;
  let outfitAId: string;
  let planAId: string;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.setGlobalPrefix('api');
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));
    await app.init();
    prisma = app.get(PrismaService);

    // Register two independent users.
    const regA = await request(app.getHttpServer())
      .post('/api/auth/register')
      .send({ name: 'Isolation Test A', email: emailA, password })
      .expect(201);
    tokenA = regA.body.accessToken;
    userAId = regA.body.user.id;

    const regB = await request(app.getHttpServer())
      .post('/api/auth/register')
      .send({ name: 'Isolation Test B', email: emailB, password })
      .expect(201);
    tokenB = regB.body.accessToken;
    userBId = regB.body.user.id;

    // User A creates a wardrobe item, an outfit built from it, and a plan.
    const item = await request(app.getHttpServer())
      .post('/api/wardrobe')
      .set('Authorization', `Bearer ${tokenA}`)
      .send({ name: 'Isolation Test Shirt', categoryName: 'Tops', color: 'Red' })
      .expect(201);
    wardrobeItemAId = item.body.id;

    const outfit = await request(app.getHttpServer())
      .post('/api/outfits')
      .set('Authorization', `Bearer ${tokenA}`)
      .send({ name: 'Isolation Test Outfit', items: [{ wardrobeItemId: wardrobeItemAId, slot: 'Top' }] })
      .expect(201);
    outfitAId = outfit.body.id;

    const plan = await request(app.getHttpServer())
      .post('/api/plans')
      .set('Authorization', `Bearer ${tokenA}`)
      .send({ outfitId: outfitAId, date: '2099-01-15' })
      .expect(201);
    planAId = plan.body.id;
  });

  afterAll(async () => {
    // Best-effort cleanup of the rows this test created, so re-running
    // the suite doesn't accumulate junk in the real database.
    await prisma.plan.deleteMany({ where: { userId: { in: [userAId, userBId] } } });
    await prisma.outfitItem.deleteMany({ where: { outfit: { userId: { in: [userAId, userBId] } } } });
    await prisma.outfit.deleteMany({ where: { userId: { in: [userAId, userBId] } } });
    await prisma.wardrobeItem.deleteMany({ where: { userId: { in: [userAId, userBId] } } });
    await prisma.user.deleteMany({ where: { id: { in: [userAId, userBId] } } });
    await app.close();
  });

  it('User B cannot GET User A wardrobe item', async () => {
    await request(app.getHttpServer())
      .get(`/api/wardrobe/${wardrobeItemAId}`)
      .set('Authorization', `Bearer ${tokenB}`)
      .expect(404); // not found from B's perspective — no existence leak
  });

  it('User B cannot PATCH User A wardrobe item', async () => {
    const res = await request(app.getHttpServer())
      .patch(`/api/wardrobe/${wardrobeItemAId}`)
      .set('Authorization', `Bearer ${tokenB}`)
      .send({ name: 'Hacked by B' });
    expect(res.status).toBe(403);
  });

  it('User B cannot DELETE User A wardrobe item', async () => {
    const res = await request(app.getHttpServer())
      .delete(`/api/wardrobe/${wardrobeItemAId}`)
      .set('Authorization', `Bearer ${tokenB}`);
    expect(res.status).toBe(403);
  });

  it('User B cannot toggle-favorite User A wardrobe item', async () => {
    const res = await request(app.getHttpServer())
      .post(`/api/wardrobe/${wardrobeItemAId}/favorite`)
      .set('Authorization', `Bearer ${tokenB}`);
    expect(res.status).toBe(403);
  });

  it("User A's wardrobe item is unmodified after all of User B's attempts", async () => {
    const res = await request(app.getHttpServer())
      .get(`/api/wardrobe/${wardrobeItemAId}`)
      .set('Authorization', `Bearer ${tokenA}`)
      .expect(200);
    expect(res.body.name).toBe('Isolation Test Shirt');
    expect(res.body.isFavorite).toBe(false);
  });

  it('User B cannot GET User A outfit', async () => {
    await request(app.getHttpServer())
      .get(`/api/outfits/${outfitAId}`)
      .set('Authorization', `Bearer ${tokenB}`)
      .expect(404);
  });

  it('User B cannot DELETE User A outfit', async () => {
    const res = await request(app.getHttpServer())
      .delete(`/api/outfits/${outfitAId}`)
      .set('Authorization', `Bearer ${tokenB}`);
    expect(res.status).toBe(403);
  });

  it('User B cannot attach User A wardrobe item into their own new outfit', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/outfits')
      .set('Authorization', `Bearer ${tokenB}`)
      .send({ name: 'Stolen Outfit', items: [{ wardrobeItemId: wardrobeItemAId, slot: 'Top' }] });
    expect(res.status).toBe(400);
  });

  it('User B cannot GET User A plan', async () => {
    await request(app.getHttpServer())
      .get(`/api/plans/${planAId}`)
      .set('Authorization', `Bearer ${tokenB}`)
      .expect(404);
  });

  it("User B's own wardrobe list never contains User A's items", async () => {
    const res = await request(app.getHttpServer())
      .get('/api/wardrobe')
      .set('Authorization', `Bearer ${tokenB}`)
      .expect(200);
    const ids = res.body.items.map((i: any) => i.id);
    expect(ids).not.toContain(wardrobeItemAId);
  });

  it('Requests without a JWT are rejected with 401', async () => {
    await request(app.getHttpServer()).get('/api/wardrobe').expect(401);
    await request(app.getHttpServer()).get('/api/users/me').expect(401);
  });

  it('Login with wrong password is rejected with 401', async () => {
    await request(app.getHttpServer())
      .post('/api/auth/login')
      .send({ email: emailA, password: 'WrongPassword123' })
      .expect(401);
  });

  it('Registration rejects weak passwords', async () => {
    await request(app.getHttpServer())
      .post('/api/auth/register')
      .send({ name: 'Weak', email: `weak_${rand()}@example.com`, password: 'weak' })
      .expect(400);
  });

  it('Mass-assignment of unexpected fields is rejected', async () => {
    await request(app.getHttpServer())
      .post('/api/wardrobe')
      .set('Authorization', `Bearer ${tokenA}`)
      .send({ name: 'Test', categoryName: 'Tops', userId: 'someone-else', isAdmin: true })
      .expect(400);
  });
});
