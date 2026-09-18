import { Controller, Get, ServiceUnavailableException } from '@nestjs/common';
import { AppService } from './app.service';
import { PrismaService } from './prisma/prisma.service';

@Controller()
export class AppController {
  constructor(
    private readonly appService: AppService,
    private readonly prisma: PrismaService,
  ) {}

  @Get()
  getHello(): string {
    return this.appService.getHello();
  }

  /**
   * Real health check — actually queries PostgreSQL rather than
   * unconditionally returning "ok". Used by container orchestration /
   * uptime monitoring. Never returns secrets, tokens, or user data.
   */
  @Get('health')
  async health() {
    const startedAt = Date.now();
    try {
      await this.prisma.$queryRaw`SELECT 1`;
      return {
        status: 'ok',
        db: 'connected',
        uptimeMs: process.uptime() * 1000,
        checkedInMs: Date.now() - startedAt,
        timestamp: new Date().toISOString(),
      };
    } catch (err) {
      throw new ServiceUnavailableException({
        status: 'error',
        db: 'unreachable',
        timestamp: new Date().toISOString(),
      });
    }
  }
}
