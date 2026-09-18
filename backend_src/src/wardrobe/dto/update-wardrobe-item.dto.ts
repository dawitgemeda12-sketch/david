import { PartialType } from '@nestjs/mapped-types';
import { CreateWardrobeItemDto } from './create-wardrobe-item.dto';
import { IsBoolean, IsOptional } from 'class-validator';

export class UpdateWardrobeItemDto extends PartialType(CreateWardrobeItemDto) {
  @IsOptional() @IsBoolean() isArchived?: boolean;
}
