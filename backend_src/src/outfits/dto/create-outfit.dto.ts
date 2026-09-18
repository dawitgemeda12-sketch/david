import { ArrayMinSize, IsArray, IsBoolean, IsOptional, IsString, MaxLength, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';

export class OutfitItemInputDto {
  @IsString() wardrobeItemId: string;
  @IsString() @MaxLength(40) slot: string; // Top, Bottom, Shoes, Outerwear, Bag, Accessories
}

export class CreateOutfitDto {
  @IsString() @MaxLength(120) name: string;
  @IsOptional() @IsString() occasion?: string;
  @IsOptional() @IsString() weather?: string;
  @IsOptional() @IsString() notes?: string;
  @IsOptional() @IsBoolean() isFavorite?: boolean;

  // Every wardrobeItemId referenced here MUST belong to the requesting
  // user — enforced in OutfitsService, never trusted from the client.
  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => OutfitItemInputDto)
  items: OutfitItemInputDto[];
}
