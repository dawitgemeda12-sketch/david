import { Type } from 'class-transformer';
import { IsBoolean, IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

export class QueryOutfitsDto {
  @IsOptional() @IsString() occasion?: string;
  @IsOptional() @Type(() => Boolean) @IsBoolean() favoritesOnly?: boolean;
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) @Max(100) limit?: number = 30;
  @IsOptional() @Type(() => Number) @IsInt() @Min(0) offset?: number = 0;
}
