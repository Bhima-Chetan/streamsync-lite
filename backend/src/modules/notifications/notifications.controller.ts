import {
  Controller,
  Get,
  Post,
  Delete,
  Body,
  Query,
  Param,
  UseGuards,
  Req,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { NotificationsService } from './notifications.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CreateNotificationDto, SendTestPushDto, MarkReadDto } from './dto/notification.dto';

@ApiTags('notifications')
@Controller('notifications')
export class NotificationsController {
  constructor(private notificationsService: NotificationsService) {}

  @Get()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get user notifications' })
  @ApiQuery({ name: 'userId', required: true })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'since', required: false, type: String })
  async getUserNotifications(
    @Query('userId') userId: string,
    @Query('limit') limit?: number,
    @Query('since') since?: string,
    @Req() req?: any,
  ) {
    if (req.user.userId !== userId) {
      throw new Error('Unauthorized');
    }
    const sinceDate = since ? new Date(since) : undefined;
    return this.notificationsService.getUserNotifications(userId, limit, sinceDate);
  }

  @Post()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create notification (admin only)' })
  async createNotification(@Body() dto: CreateNotificationDto) {
    return this.notificationsService.createNotification(
      dto.userId,
      dto.title,
      dto.body,
      dto.metadata,
    );
  }

  @Post('send-test')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @ApiOperation({ summary: 'Send test push notification to self' })
  async sendTestPush(@Body() dto: SendTestPushDto, @Req() req: any) {
    return this.notificationsService.sendTestPush(req.user.userId, dto.title, dto.body);
  }

  @Post('mark-read')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Mark notifications as read' })
  async markAsRead(@Body() dto: MarkReadDto, @Req() req: any) {
    if (req.user.userId !== dto.userId) {
      throw new Error('Unauthorized');
    }
    return this.notificationsService.markAsRead(dto.userId, dto.notificationIds);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Delete notification' })
  @ApiQuery({ name: 'userId', required: true })
  async deleteNotification(
    @Param('id') notificationId: string,
    @Query('userId') userId: string,
    @Req() req: any,
  ) {
    if (req.user.userId !== userId) {
      throw new Error('Unauthorized');
    }
    return this.notificationsService.deleteNotification(userId, notificationId);
  }
}
