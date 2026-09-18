# Backend Tests

Run with: `npx jest --config ./test/jest-e2e.json --runInBand`
(runInBand avoids parallel workers colliding on the same Postgres DB.)

All tests run against the REAL configured PostgreSQL database via the
actual `AppModule`/`PrismaService` — not mocks — so they genuinely
exercise the HTTP layer, JWT auth, and ownership-enforcement logic.

- `app.e2e-spec.ts` — root route + `/api/health` (real DB connectivity check).
- `isolation.e2e-spec.ts` — the SECURITY-CRITICAL suite: registers two
  independent users (A and B) and verifies User B can never read,
  modify, delete, or attach User A's wardrobe items/outfits/plans;
  confirms 401 without a JWT, 401 on wrong password, 400 on weak
  password, and 400 on mass-assignment of unexpected fields
  (`forbidNonWhitelisted`). Cleans up its own rows in `afterAll`.

Current status: **16/16 passing.**

Note: `@nestjs/mapped-types` was pinned to `2.0.6` (down from an
initially-installed `12.0.0`) because that release ships a dual
ESM/CJS build that ts-jest's default CJS transform cannot parse. 2.0.6
is fully compatible with NestJS 10 / Nest CLI 10 used throughout this
backend.
