import { IsDateString, IsOptional } from 'class-validator';

export class QueryPlansDto {
  // Simple range filter — no orderBy combined with where on a
  // non-indexed-pair field, so no composite index is required; results
  // are naturally few per user (one plan per day) and sorted in memory.
  @IsOptional() @IsDateString() from?: string;
  @IsOptional() @IsDateString() to?: string;
}
