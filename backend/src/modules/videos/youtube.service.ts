import { Injectable } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';

interface YouTubeVideo {
  id: string;
  snippet: {
    title: string;
    description: string;
    thumbnails: {
      high: { url: string };
    };
    channelId: string;
    channelTitle: string;
    publishedAt: string;
  };
  contentDetails: {
    duration: string;
  };
  statistics: {
    viewCount: string;
    likeCount: string;
    commentCount: string;
  };
}

@Injectable()
export class YoutubeService {
  private cache: Map<string, { data: any; timestamp: number }> = new Map();
  private readonly cacheTtl: number;

  constructor(private httpService: HttpService) {
    this.cacheTtl = parseInt(process.env.YOUTUBE_CACHE_TTL || '600', 10) * 1000;
  }

  async getLatestVideos(channelId: string, maxResults: number = 50, category?: string) {
    const cacheKey = `latest_${channelId}_${maxResults}_${category || 'all'}`;
    const cached = this.cache.get(cacheKey);

    if (cached && Date.now() - cached.timestamp < this.cacheTtl) {
      return cached.data;
    }

    try {
      // Determine order parameter based on category
      let order = 'date'; // default: newest first
      if (category === 'popular') {
        order = 'viewCount';
      } else if (category === 'trending') {
        order = 'rating';
      }

      const searchResponse = await firstValueFrom(
        this.httpService.get('https://www.googleapis.com/youtube/v3/search', {
          params: {
            key: process.env.YOUTUBE_API_KEY,
            channelId,
            part: 'id',
            order,
            maxResults: Math.min(maxResults, 50), // Cap at 50 per YouTube API limits
            type: 'video',
            videoDuration: 'medium', // Exclude shorts (medium = 4-20 min, long = >20 min)
          },
        }),
      );

      const videoIds = searchResponse.data.items.map((item: any) => item.id.videoId).join(',');

      if (!videoIds) {
        return [];
      }

      const videosResponse = await firstValueFrom(
        this.httpService.get('https://www.googleapis.com/youtube/v3/videos', {
          params: {
            key: process.env.YOUTUBE_API_KEY,
            id: videoIds,
            part: 'snippet,contentDetails,statistics',
          },
        }),
      );

      const videos = videosResponse.data.items.map((item: YouTubeVideo) => ({
        videoId: item.id,
        title: item.snippet.title,
        description: item.snippet.description,
        thumbnailUrl: item.snippet.thumbnails.high.url,
        channelId: item.snippet.channelId,
        channelTitle: item.snippet.channelTitle,
        publishedAt: new Date(item.snippet.publishedAt),
        durationSeconds: this.parseDuration(item.contentDetails.duration),
        viewCount: parseInt(item.statistics.viewCount || '0', 10),
        likeCount: parseInt(item.statistics.likeCount || '0', 10),
        commentCount: parseInt(item.statistics.commentCount || '0', 10),
      }));

      this.cache.set(cacheKey, { data: videos, timestamp: Date.now() });
      return videos;
    } catch (error) {
      console.error('YouTube API Error:', error);
      throw error;
    }
  }

  async searchVideos(query: string, maxResults: number = 20) {
    const cacheKey = `search_${query}_${maxResults}`;
    const cached = this.cache.get(cacheKey);

    if (cached && Date.now() - cached.timestamp < this.cacheTtl) {
      return cached.data;
    }

    try {
      const searchResponse = await firstValueFrom(
        this.httpService.get('https://www.googleapis.com/youtube/v3/search', {
          params: {
            key: process.env.YOUTUBE_API_KEY,
            q: query,
            part: 'id',
            maxResults: Math.min(maxResults, 50),
            type: 'video',
            videoDuration: 'medium', // Exclude shorts
          },
        }),
      );

      const videoIds = searchResponse.data.items.map((item: any) => item.id.videoId).join(',');

      if (!videoIds) {
        return [];
      }

      const videosResponse = await firstValueFrom(
        this.httpService.get('https://www.googleapis.com/youtube/v3/videos', {
          params: {
            key: process.env.YOUTUBE_API_KEY,
            id: videoIds,
            part: 'snippet,contentDetails,statistics',
          },
        }),
      );

      const videos = videosResponse.data.items.map((item: YouTubeVideo) => ({
        videoId: item.id,
        title: item.snippet.title,
        description: item.snippet.description,
        thumbnailUrl: item.snippet.thumbnails.high.url,
        channelId: item.snippet.channelId,
        channelTitle: item.snippet.channelTitle,
        publishedAt: new Date(item.snippet.publishedAt),
        durationSeconds: this.parseDuration(item.contentDetails.duration),
        viewCount: parseInt(item.statistics.viewCount || '0', 10),
        likeCount: parseInt(item.statistics.likeCount || '0', 10),
        commentCount: parseInt(item.statistics.commentCount || '0', 10),
      }));

      this.cache.set(cacheKey, { data: videos, timestamp: Date.now() });
      return videos;
    } catch (error) {
      console.error('YouTube Search API Error:', error);
      throw error;
    }
  }

  private parseDuration(duration: string): number {
    const match = duration.match(/PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?/);
    if (!match) return 0;
    const hours = parseInt(match[1] || '0', 10);
    const minutes = parseInt(match[2] || '0', 10);
    const seconds = parseInt(match[3] || '0', 10);
    return hours * 3600 + minutes * 60 + seconds;
  }
}
