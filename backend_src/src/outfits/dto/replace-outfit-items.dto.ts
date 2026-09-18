import { ArrayMinSize, IsArray, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { OutfitItemInputDto } from './create-outfit.dto';

export class ReplaceOutfitItemsDto {
  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => OutfitItemInputDto)
  items: OutfitItemInputDto[];
}
