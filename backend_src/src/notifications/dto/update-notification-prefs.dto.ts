import { IsBoolean, IsOptional } from 'class-validator';

export class UpdateNotificationPrefsDto {
  @IsOptional() @IsBoolean() pushEnabled?: boolean;
  @IsOptional() @IsBoolean() planReminders?: boolean;
  @IsOptional() @IsBoolean() weatherTips?: boolean;
  @IsOptional() @IsBoolean() wardrobeGapAlerts?: boolean;
}
