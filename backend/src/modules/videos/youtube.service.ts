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
    try {
      // Special handling: global trending (not limited to channel)
      if (category === 'trending') {
        const videosResponse = await firstValueFrom(
          this.httpService.get('https://www.googleapis.com/youtube/v3/videos', {
            params: {
              key: process.env.YOUTUBE_API_KEY,
              chart: 'mostPopular',
              regionCode: process.env.YOUTUBE_REGION_CODE || 'US',
              maxResults: Math.min(maxResults, 50),
              part: 'snippet,contentDetails,statistics',
              videoCategoryId: process.env.YOUTUBE_VIDEO_CATEGORY_ID || undefined,
            },
          }),
        );

        return videosResponse.data.items.map((item: YouTubeVideo) => {
          const thumbnails = item.snippet.thumbnails as any;
          return {
            videoId: item.id,
            title: item.snippet.title,
            description: item.snippet.description,
            thumbnailUrl: thumbnails?.high?.url || thumbnails?.medium?.url || thumbnails?.default?.url || '',
            channelId: item.snippet.channelId,
            channelTitle: item.snippet.channelTitle,
            publishedAt: new Date(item.snippet.publishedAt),
            durationSeconds: this.parseDuration(item.contentDetails.duration),
            viewCount: parseInt(item.statistics?.viewCount || '0', 10),
            likeCount: parseInt(item.statistics?.likeCount || '0', 10),
            commentCount: parseInt(item.statistics?.commentCount || '0', 10),
          };
        });
      }

      // Determine order parameter based on category
      // For 'all': use relevance (most relevant videos)
      // For 'new': use date for newest videos
      // For 'popular': use viewCount for most viewed
      let order = 'relevance'; // default for 'all': most relevant
      if (category === 'new') {
        order = 'date';
      } else if (category === 'popular') {
        order = 'viewCount';
      }

      // To provide variety on refresh, we'll shuffle the order parameter occasionally
      // This gives different results without pagination complexity
      const shouldShuffle = Math.random() > 0.5;
      
      // Use a broad search query instead of channelId to get diverse content
      // This searches for music/entertainment videos globally
      const searchQuery = 'music OR entertainment OR gaming OR sports';
      
      console.log(`🔍 Fetching videos for category: ${category || 'all'}, order: ${order}, query: ${searchQuery}, shuffle: ${shouldShuffle}`);

      const searchResponse = await firstValueFrom(
        this.httpService.get('https://www.googleapis.com/youtube/v3/search', {
          params: {
            key: process.env.YOUTUBE_API_KEY,
            q: searchQuery, // Global search instead of channelId
            part: 'id',
            order,
            maxResults: 50, // YouTube API max
            type: 'video',
            videoDuration: 'medium', // Exclude shorts (medium = 4-20 min, long = >20 min)
            relevanceLanguage: 'en', // Prefer English content
            safeSearch: 'moderate', // Filter inappropriate content
          },
        }),
      );

      // Get all video IDs
      let allVideoIds = searchResponse.data.items.map((item: any) => item.id.videoId);
      
      // Shuffle the array if needed to provide variety on refresh
      if (shouldShuffle) {
        // Fisher-Yates shuffle algorithm
        for (let i = allVideoIds.length - 1; i > 0; i--) {
          const j = Math.floor(Math.random() * (i + 1));
          [allVideoIds[i], allVideoIds[j]] = [allVideoIds[j], allVideoIds[i]];
        }
        console.log(`🎲 Shuffled ${allVideoIds.length} videos for variety`);
      }
      
      // Take only what we need
      const selectedVideoIds = allVideoIds.slice(0, maxResults);
      const videoIds = selectedVideoIds.join(',');

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

      const videos = videosResponse.data.items.map((item: YouTubeVideo) => {
        const thumbnails = item.snippet.thumbnails as any;
        const statistics = item.statistics as any;
        return {
          videoId: item.id,
          title: item.snippet.title,
          description: item.snippet.description,
          thumbnailUrl: thumbnails?.high?.url || thumbnails?.medium?.url || thumbnails?.default?.url || '',
          channelId: item.snippet.channelId,
          channelTitle: item.snippet.channelTitle,
          publishedAt: new Date(item.snippet.publishedAt),
          durationSeconds: this.parseDuration(item.contentDetails.duration),
          viewCount: parseInt(statistics?.viewCount || '0', 10),
          likeCount: parseInt(statistics?.likeCount || '0', 10),
          commentCount: parseInt(statistics?.commentCount || '0', 10),
        };
      });

      console.log(`✅ Returning ${videos.length} videos for category: ${category || 'all'}, order: ${order}`);
      console.log(`📹 First 3 video titles: ${videos.slice(0, 3).map(v => v.title).join(' | ')}`);

      return videos;
    } catch (error) {
      console.error('YouTube API Error:', error);
      if (error.response?.data) {
        console.error('YouTube Error Details:', JSON.stringify(error.response.data, null, 2));
      }
      throw error;
    }
  }

  async searchVideos(query: string, maxResults: number = 20) {
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

  async getVideoComments(videoId: string, maxResults: number = 20) {
    try {
      const commentsResponse = await firstValueFrom(
        this.httpService.get('https://www.googleapis.com/youtube/v3/commentThreads', {
          params: {
            key: process.env.YOUTUBE_API_KEY,
            videoId,
            part: 'snippet',
            maxResults: Math.min(maxResults, 100),
            order: 'relevance', // or 'time' for newest first
            textFormat: 'plainText',
          },
        }),
      );

      return commentsResponse.data.items.map((item: any) => ({
        commentId: item.id,
        text: item.snippet.topLevelComment.snippet.textDisplay,
        authorName: item.snippet.topLevelComment.snippet.authorDisplayName,
        authorProfileImageUrl: item.snippet.topLevelComment.snippet.authorProfileImageUrl,
        likeCount: item.snippet.topLevelComment.snippet.likeCount,
        publishedAt: new Date(item.snippet.topLevelComment.snippet.publishedAt),
        updatedAt: new Date(item.snippet.topLevelComment.snippet.updatedAt),
      }));
    } catch (error) {
      console.error('YouTube Comments API Error:', error);
      // Comments might be disabled for the video
      return [];
    }
  }
}
