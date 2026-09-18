# Stylish Backend — Production Dockerfile
# Multi-stage build: compile TypeScript in a build stage, then run
# only the compiled output + production deps in a slim runtime image.
# No secrets are baked into the image — all configuration is supplied
# at container runtime via environment variables (see .env.example).

# ---------- Build stage ----------
FROM node:22-slim AS build
WORKDIR /app

COPY package*.json ./
COPY prisma ./prisma
RUN npm ci

COPY tsconfig*.json ./
COPY src ./src
RUN npx prisma generate
RUN npm run build

# ---------- Runtime stage ----------
FROM node:22-slim AS runtime
WORKDIR /app
ENV NODE_ENV=production

COPY package*.json ./
COPY prisma ./prisma
RUN npm ci --omit=dev && npx prisma generate

COPY --from=build /app/dist ./dist

# Non-root user for defense-in-depth.
RUN groupadd -r stylish && useradd -r -g stylish stylish \
  && mkdir -p /app/uploads && chown -R stylish:stylish /app
USER stylish

EXPOSE 3000

# Container-level health check hits the real /api/health endpoint
# (which itself queries Postgres) — orchestrators can use this to
# detect a genuinely broken DB connection, not just "process alive".
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/api/health', r => process.exit(r.statusCode===200?0:1)).on('error', () => process.exit(1))"

CMD ["node", "dist/main.js"]
