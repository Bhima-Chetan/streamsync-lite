import { Controller, Post, Delete, Patch, Param, Body, UseGuards, Req } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('users')
@Controller('users')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class UsersController {
  constructor(private usersService: UsersService) {}

  @Patch(':id')
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
