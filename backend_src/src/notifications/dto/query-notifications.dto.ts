import { Type } from 'class-transformer';
import { IsBoolean, IsInt, IsOptional, Max, Min } from 'class-validator';

export class QueryNotificationsDto {
  @IsOptional() @Type(() => Boolean) @IsBoolean() unreadOnly?: boolean;
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) @Max(100) limit?: number = 30;
  @IsOptional() @Type(() => Number) @IsInt() @Min(0) offset?: number = 0;
}
