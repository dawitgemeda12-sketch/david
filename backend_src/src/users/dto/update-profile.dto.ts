import { IsArray, IsBoolean, IsIn, IsNumber, IsOptional, IsString, MaxLength } from 'class-validator';

export class UpdateProfileDto {
  @IsOptional() @IsString() @MaxLength(120) name?: string;
  @IsOptional() @IsIn(['Women', 'Men', 'Children', 'Other']) gender?: string;
  @IsOptional() @IsString() @MaxLength(80) city?: string;
  @IsOptional() @IsString() @MaxLength(3) currency?: string;
  @IsOptional() @IsNumber() monthlyBudget?: number;
  @IsOptional() @IsString() @MaxLength(60) sizeInfo?: string;
  @IsOptional() @IsBoolean() aiPersonalizationOn?: boolean;
  @IsOptional() @IsArray() favoriteColors?: string[];
  @IsOptional() @IsArray() preferredOccasions?: string[];
}
