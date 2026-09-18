import { IsArray, IsBoolean, IsDateString, IsNumber, IsOptional, IsString, MaxLength } from 'class-validator';

export class CreateWardrobeItemDto {
  @IsString() @MaxLength(120) name: string;
  @IsString() @MaxLength(60) categoryName: string;
  @IsOptional() @IsString() subcategory?: string;
  @IsOptional() @IsString() color?: string;
  @IsOptional() @IsString() secondaryColor?: string;
  @IsOptional() @IsString() pattern?: string;
  @IsOptional() @IsString() material?: string;
  @IsOptional() @IsString() style?: string;
  @IsOptional() @IsArray() seasons?: string[];
  @IsOptional() @IsArray() occasions?: string[];
  @IsOptional() @IsString() formality?: string;
  @IsOptional() @IsString() brand?: string;
  @IsOptional() @IsString() size?: string;
  @IsOptional() @IsDateString() purchaseDate?: string;
  @IsOptional() @IsNumber() purchasePriceEtb?: number;
  @IsOptional() @IsString() condition?: string;
  @IsOptional() @IsBoolean() isFavorite?: boolean;
  @IsOptional() @IsString() notes?: string;
  @IsOptional() @IsArray() tags?: string[];
}
