import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In } from 'typeorm';
import { Video } from './entities/video.entity';
import { Progress } from './entities/progress.entity';
import { Favorite } from './entities/favorite.entity';
import { YoutubeService } from './youtube.service';

@Injectable()
export class VideosService {
  constructor(
    @InjectRepository(Video)
    private videoRepository: Repository<Video>,
    @InjectRepository(Progress)
    private progressRepository: Repository<Progress>,
    @InjectRepository(Favorite)
    private favoriteRepository: Repository<Favorite>,
    private youtubeService: YoutubeService,
  ) {}

  async getLatestVideos(channelId?: string, maxResults: number = 50, category?: string) {
    const targetChannelId = channelId || process.env.YOUTUBE_CHANNEL_ID;
    if (!targetChannelId) {
      throw new Error('YouTube channel ID not configured');
    }

    console.log(`📺 VideosService: Fetching videos for category: ${category || 'all'}`);
    const videos = await this.youtubeService.getLatestVideos(targetChannelId, maxResults, category);
    console.log(`✅ VideosService: Received ${videos.length} videos from YouTube for category: ${category || 'all'}`);

    // Save to database for offline access, but don't re-query
    for (const videoData of videos) {
      await this.videoRepository.upsert(videoData, ['videoId']);
    }

    // Return the YouTube results directly to preserve the correct order
    return videos;
  }

  async searchVideos(query: string, maxResults: number = 20) {
    const videos = await this.youtubeService.searchVideos(query, maxResults);

    for (const videoData of videos) {
      await this.videoRepository.upsert(videoData, ['videoId']);
    }

    return videos;
  }

  async getVideoById(videoId: string) {
    return this.videoRepository.findOne({ where: { videoId } });
  }

  async saveProgress(userId: string, videoId: string, positionSeconds: number, completedPercent: number) {
    const progress = await this.progressRepository.findOne({
      where: { userId, videoId },
    });

    if (progress) {
      progress.positionSeconds = positionSeconds;
      progress.completedPercent = completedPercent;
      progress.synced = true;
      return this.progressRepository.save(progress);
    }

    return this.progressRepository.save({
      userId,
      videoId,
      positionSeconds,
      completedPercent,
      synced: true,
    });
  }

  async getProgress(userId: string, videoId?: string) {
    if (videoId) {
      return this.progressRepository.findOne({ where: { userId, videoId } });
    }
    return this.progressRepository.find({ where: { userId } });
  }

  async toggleFavorite(userId: string, videoId: string) {
    const existing = await this.favoriteRepository.findOne({
      where: { userId, videoId },
    });

    if (existing) {
      await this.favoriteRepository.remove(existing);
      return { isFavorite: false };
    }

    await this.favoriteRepository.save({
      userId,
      videoId,
      synced: true,
    });
    return { isFavorite: true };
  }

  async getFavorites(userId: string) {
    return this.favoriteRepository.find({
      where: { userId },
      relations: ['video'],
    });
  }

  async getVideoComments(videoId: string, maxResults: number = 20) {
    return this.youtubeService.getVideoComments(videoId, maxResults);
  }
}
