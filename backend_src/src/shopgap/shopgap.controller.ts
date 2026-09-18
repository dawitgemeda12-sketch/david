import { Controller, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { ShopGapService } from './shopgap.service';
import { QueryRecommendationsDto } from './dto/query-recommendations.dto';

@UseGuards(JwtAuthGuard)
@Controller('shop-gap')
export class ShopGapController {
  constructor(private readonly shopGapService: ShopGapService) {}

  @Get('recommendations')
  list(@CurrentUser('id') userId: string, @Query() query: QueryRecommendationsDto) {
    return this.shopGapService.list(userId, query.includeDismissed);
  }

  @Post('recommendations/refresh')
  refresh(@CurrentUser('id') userId: string) {
    return this.shopGapService.analyzeAndRefresh(userId);
  }

  @Patch('recommendations/:id/dismiss')
  dismiss(@CurrentUser('id') userId: string, @Param('id') id: string) {
    return this.shopGapService.dismiss(userId, id);
  }

  @Get('coverage')
  coverage(@CurrentUser('id') userId: string) {
    return this.shopGapService.coverage(userId);
  }
}
