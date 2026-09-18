import { IsOptional, IsString, MaxLength } from 'class-validator';

export class SendMessageDto {
  @IsString() @MaxLength(2000) message: string;
  // If omitted, a new conversation is created.
  @IsOptional() @IsString() conversationId?: string;
}
