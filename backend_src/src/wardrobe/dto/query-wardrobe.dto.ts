import { Type } from 'class-transformer';
import { IsBoolean, IsIn, IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

export class QueryWardrobeDto {
  @IsOptional() @IsString() q?: string;
  @IsOptional() @IsString() category?: string;
  @IsOptional() @IsString() color?: string;
  @IsOptional()
  @Type(() => Boolean)
  @IsBoolean()
  favoritesOnly?: boolean;

  @IsOptional()
  @Type(() => Boolean)
  @IsBoolean()
  includeArchived?: boolean;

  @IsOptional() @Type(() => Number) @IsInt() @Min(1) @Max(100) limit?: number = 30;
  @IsOptional() @Type(() => Number) @IsInt() @Min(0) offset?: number = 0;

  @IsOptional() @IsIn(['updatedAt', 'createdAt', 'name']) sortBy?: string = 'updatedAt';
}
