import { Module } from '@nestjs/common';
import { ShopGapService } from './shopgap.service';
import { ShopGapController } from './shopgap.controller';

@Module({
  controllers: [ShopGapController],
  providers: [ShopGapService],
  exports: [ShopGapService],
})
export class ShopGapModule {}
