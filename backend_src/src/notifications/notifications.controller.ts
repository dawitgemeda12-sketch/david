import { Body, Controller, Delete, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { NotificationsService } from './notifications.service';
import { QueryNotificationsDto } from './dto/query-notifications.dto';
import { UpdateNotificationPrefsDto } from './dto/update-notification-prefs.dto';
import { RegisterDeviceTokenDto } from './dto/register-device-token.dto';

@UseGuards(JwtAuthGuard)
@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Get()
  list(@CurrentUser('id') userId: string, @Query() query: QueryNotificationsDto) {
    return this.notificationsService.list(userId, query);
  }

  @Get('unread-count')
  unreadCount(@CurrentUser('id') userId: string) {
    return this.notificationsService.unreadCount(userId);
  }

  @Patch(':id/read')
  markRead(@CurrentUser('id') userId: string, @Param('id') id: string) {
    return this.notificationsService.markRead(userId, id);
  }

  @Patch('read-all')
  markAllRead(@CurrentUser('id') userId: string) {
    return this.notificationsService.markAllRead(userId);
  }

  @Delete(':id')
  remove(@CurrentUser('id') userId: string, @Param('id') id: string) {
    return this.notificationsService.remove(userId, id);
  }

  @Get('preferences')
  getPreferences(@CurrentUser('id') userId: string) {
    return this.notificationsService.getPreferences(userId);
  }

  @Patch('preferences')
  updatePreferences(@CurrentUser('id') userId: string, @Body() dto: UpdateNotificationPrefsDto) {
    return this.notificationsService.updatePreferences(userId, dto);
  }

  @Post('device-tokens')
  registerDeviceToken(@CurrentUser('id') userId: string, @Body() dto: RegisterDeviceTokenDto) {
    return this.notificationsService.registerDeviceToken(userId, dto);
  }

  @Delete('device-tokens/:token')
  removeDeviceToken(@CurrentUser('id') userId: string, @Param('token') token: string) {
    return this.notificationsService.removeDeviceToken(userId, token);
  }
}
