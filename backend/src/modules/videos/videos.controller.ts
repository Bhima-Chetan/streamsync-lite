import { Controller, Get, Post, Delete, Body, Query, Param, UseGuards, Req } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { VideosService } from './videos.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('videos')
@Controller('videos')
export class VideosController {
  constructor(private videosService: VideosService) {}

  @Get('latest')
  @ApiOperation({ summary: 'Get latest videos from YouTube channel' })
  @ApiQuery({ name: 'channelId', required: false })
  @ApiQuery({ name: 'maxResults', required: false, description: 'Number of videos to fetch (default: 50, max: 50)' })
  @ApiQuery({ name: 'category', required: false, description: 'Category filter: all, trending, new, popular' })
  async getLatestVideos(
    @Query('channelId') channelId?: string,
    @Query('maxResults') maxResults?: string,
    @Query('category') category?: string,
  ) {
    const limit = maxResults ? Math.min(parseInt(maxResults, 10), 50) : 50;
    return this.videosService.getLatestVideos(channelId, limit, category);
  }

  @Get('search')
  @ApiOperation({ summary: 'Search YouTube videos' })
  @ApiQuery({ name: 'q', required: true, description: 'Search query' })
  @ApiQuery({ name: 'maxResults', required: false, description: 'Number of videos to fetch (default: 20, max: 50)' })
  async searchVideos(
    @Query('q') query: string,
    @Query('maxResults') maxResults?: string,
  ) {
    const limit = maxResults ? Math.min(parseInt(maxResults, 10), 50) : 20;
    return this.videosService.searchVideos(query, limit);
  }

  @Get(':videoId')
  @ApiOperation({ summary: 'Get single video by ID' })
  async getVideo(@Param('videoId') videoId: string) {
    return this.videosService.getVideoById(videoId);
  }

  @Post('progress')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Save video progress' })
  async saveProgress(
    @Body() body: { userId: string; videoId: string; positionSeconds: number; completedPercent: number },
    @Req() req: any,
  ) {
    if (req.user.userId !== body.userId) {
      throw new Error('Unauthorized');
    }
    return this.videosService.saveProgress(
      body.userId,
      body.videoId,
      body.positionSeconds,
      body.completedPercent,
    );
  }

  @Get('progress')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get user progress' })
  @ApiQuery({ name: 'userId', required: true })
  @ApiQuery({ name: 'videoId', required: false })
  async getProgress(@Query('userId') userId: string, @Query('videoId') videoId?: string, @Req() req?: any) {
    if (req.user.userId !== userId) {
      throw new Error('Unauthorized');
    }
    return this.videosService.getProgress(userId, videoId);
  }

  @Post('favorites')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Toggle favorite' })
  async toggleFavorite(@Body() body: { userId: string; videoId: string }, @Req() req: any) {
    if (req.user.userId !== body.userId) {
      throw new Error('Unauthorized');
    }
    return this.videosService.toggleFavorite(body.userId, body.videoId);
  }

  @Get('favorites')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get user favorites' })
  @ApiQuery({ name: 'userId', required: true })
  async getFavorites(@Query('userId') userId: string, @Req() req: any) {
    if (req.user.userId !== userId) {
      throw new Error('Unauthorized');
    }
    return this.videosService.getFavorites(userId);
  }
}
