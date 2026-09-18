import { Type } from 'class-transformer';
import { IsBoolean, IsOptional } from 'class-validator';

export class QueryRecommendationsDto {
  @IsOptional() @Type(() => Boolean) @IsBoolean() includeDismissed?: boolean;
}
