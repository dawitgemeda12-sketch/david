import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { AiService } from './ai.service';
import { SendMessageDto } from './dto/send-message.dto';

@UseGuards(JwtAuthGuard)
@Controller('ai')
export class AiController {
  constructor(private readonly aiService: AiService) {}

  @Get('conversations')
  listConversations(@CurrentUser('id') userId: string) {
    return this.aiService.listConversations(userId);
  }

  @Get('conversations/:id')
  getConversation(@CurrentUser('id') userId: string, @Param('id') id: string) {
    return this.aiService.getConversation(userId, id);
  }

  @Post('messages')
  // Extra throttle on top of the global limit — AI calls are the most
  // expensive/metered upstream resource in this system.
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  sendMessage(@CurrentUser('id') userId: string, @Body() dto: SendMessageDto) {
    return this.aiService.sendMessage(userId, dto.message, dto.conversationId);
  }
}
