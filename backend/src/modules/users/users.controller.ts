import { Controller, Post, Delete, Patch, Param, Body, UseGuards, Req, Get } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('users')
@Controller('users')
export class UsersController {
  constructor(private usersService: UsersService) {}

  @Get('fcm-tokens')
  @ApiOperation({ summary: 'Get all FCM tokens (admin only - no auth for demo)' })
  async getAllFcmTokens() {
    return this.usersService.getAllFcmTokens();
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update user profile' })
  async updateProfile(
    @Param('id') userId: string,
    @Body() body: { name?: string; email?: string },
    @Req() req: any,
  ) {
    if (req.user.userId !== userId) {
      throw new Error('Unauthorized');
    }
    return this.usersService.updateProfile(userId, body);
  }

  @Post(':id/fcmToken')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Register FCM token' })
  async registerFcmToken(
    @Param('id') userId: string,
    @Body() body: { token: string; platform?: string },
    @Req() req: any,
  ) {
    if (req.user.userId !== userId) {
      throw new Error('Unauthorized');
    }
    return this.usersService.registerFcmToken(userId, body.token, body.platform);
  }

  @Delete(':id/fcmToken')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Remove FCM token' })
  async removeFcmToken(
    @Param('id') userId: string,
    @Body() body: { token: string },
    @Req() req: any,
  ) {
    if (req.user.userId !== userId) {
      throw new Error('Unauthorized');
    }
    await this.usersService.removeFcmToken(userId, body.token);
    return { success: true };
  }
}
