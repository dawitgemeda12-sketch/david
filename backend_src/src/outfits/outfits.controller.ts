import { Body, Controller, Delete, Get, Param, Patch, Post, Put, Query, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { OutfitsService } from './outfits.service';
import { CreateOutfitDto } from './dto/create-outfit.dto';
import { UpdateOutfitDto } from './dto/update-outfit.dto';
import { ReplaceOutfitItemsDto } from './dto/replace-outfit-items.dto';
import { QueryOutfitsDto } from './dto/query-outfits.dto';

@UseGuards(JwtAuthGuard)
@Controller('outfits')
export class OutfitsController {
  constructor(private readonly outfitsService: OutfitsService) {}

  @Get()
  list(@CurrentUser('id') userId: string, @Query() query: QueryOutfitsDto) {
    return this.outfitsService.list(userId, query);
  }

  @Get(':id')
  findOne(@CurrentUser('id') userId: string, @Param('id') id: string) {
    return this.outfitsService.findOneOwned(userId, id);
  }

  @Post()
  create(@CurrentUser('id') userId: string, @Body() dto: CreateOutfitDto) {
    return this.outfitsService.create(userId, dto);
  }

  @Patch(':id')
  update(
    @CurrentUser('id') userId: string,
    @Param('id') id: string,
    @Body() dto: UpdateOutfitDto,
  ) {
    return this.outfitsService.update(userId, id, dto);
  }

  @Put(':id/items')
  replaceItems(
    @CurrentUser('id') userId: string,
    @Param('id') id: string,
    @Body() dto: ReplaceOutfitItemsDto,
  ) {
    return this.outfitsService.replaceItems(userId, id, dto);
  }

  @Post(':id/favorite')
  toggleFavorite(@CurrentUser('id') userId: string, @Param('id') id: string) {
    return this.outfitsService.toggleFavorite(userId, id);
  }

  @Delete(':id')
  remove(@CurrentUser('id') userId: string, @Param('id') id: string) {
    return this.outfitsService.remove(userId, id);
  }
}
