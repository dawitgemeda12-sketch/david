import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { APP_GUARD } from '@nestjs/core';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { WardrobeModule } from './wardrobe/wardrobe.module';
import { OutfitsModule } from './outfits/outfits.module';
import { PlansModule } from './plans/plans.module';
import { NotificationsModule } from './notifications/notifications.module';
import { ShopGapModule } from './shopgap/shopgap.module';
import { AiModule } from './ai/ai.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, envFilePath: '.env' }),
    ThrottlerModule.forRoot([{ ttl: 60000, limit: 60 }]),
    PrismaModule,
    AuthModule,
    UsersModule,
    WardrobeModule,
    OutfitsModule,
    PlansModule,
    NotificationsModule,
    ShopGapModule,
    AiModule,
  ],
  controllers: [AppController],
  providers: [
    AppService,
    // Global default rate limit (60 req/min/IP); individual sensitive
    // routes (register/login/password-reset) apply stricter @Throttle
    // overrides on top of this baseline.
    { provide: APP_GUARD, useClass: ThrottlerGuard },
  ],
})
export class AppModule {}
