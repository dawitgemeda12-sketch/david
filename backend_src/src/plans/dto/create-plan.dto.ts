import { IsBoolean, IsDateString, IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

export class CreatePlanDto {
  @IsString() outfitId: string;
  @IsDateString() date: string; // ISO date, e.g. "2026-09-20"
  @IsOptional() @IsString() occasion?: string;
  @IsOptional() @IsString() notes?: string;
  @IsOptional() @IsBoolean() reminderEnabled?: boolean;
  @IsOptional() @IsInt() @Min(0) @Max(1440) reminderMinutesBefore?: number;
}
