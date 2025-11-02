import 'package:drift/drift.dart';
import '../local/database.dart';
import '../remote/api_client.dart';

class VideoRepository {
  final ApiClient _apiClient;
  final AppDatabase _database;

  VideoRepository(this._apiClient, this._database);

  Future<List<Video>> getLatestVideos({
    bool forceRefresh = false,
    int maxResults = 50,
    String? channelId,
    String? category,
  }) async {
    print('🌐 Fetching videos from YouTube API (maxResults: $maxResults, category: ${category ?? 'all'})');
    final response = await _apiClient.getLatestVideos(channelId, maxResults, category);
    print('✅ Received ${response.length} videos from API for category: ${category ?? 'all'}');

    // Convert response to Video objects
    final List<Video> videos = [];
    for (final videoData in response) {
      final durationSeconds = videoData['durationSeconds'];
      final viewCount = videoData['viewCount'];
      final likeCount = videoData['likeCount'];
      final commentCount = videoData['commentCount'];
      
      videos.add(Video(
        videoId: videoData['videoId'] as String,
        title: videoData['title'] as String,
        description: videoData['description'] as String?,
        thumbnailUrl: videoData['thumbnailUrl'] as String,
        channelId: videoData['channelId'] as String,
        channelTitle: videoData['channelTitle'] as String,
        publishedAt: DateTime.parse(videoData['publishedAt'] as String),
        createdAt: DateTime.now(),
        durationSeconds: durationSeconds is int 
            ? durationSeconds 
            : int.parse(durationSeconds.toString()),
        viewCount: viewCount != null
            ? BigInt.from(viewCount is int ? viewCount : int.parse(viewCount.toString()))
            : null,
        likeCount: likeCount != null
            ? BigInt.from(likeCount is int ? likeCount : int.parse(likeCount.toString()))
            : null,
        commentCount: commentCount != null
            ? BigInt.from(commentCount is int ? commentCount : int.parse(commentCount.toString()))
            : null,
      ));
      
      // Also save to database for offline access
      await _database.insertVideo(
        VideosCompanion.insert(
          videoId: videoData['videoId'] as String,
          title: videoData['title'] as String,
          description: Value(videoData['description'] as String?),
          thumbnailUrl: videoData['thumbnailUrl'] as String,
          channelId: videoData['channelId'] as String,
          channelTitle: videoData['channelTitle'] as String,
          publishedAt: DateTime.parse(videoData['publishedAt'] as String),
          durationSeconds: durationSeconds is int 
              ? durationSeconds 
              : int.parse(durationSeconds.toString()),
          viewCount: Value(viewCount != null
              ? BigInt.from(viewCount is int ? viewCount : int.parse(viewCount.toString()))
              : null),
          likeCount: Value(likeCount != null
              ? BigInt.from(likeCount is int ? likeCount : int.parse(likeCount.toString()))
              : null),
          commentCount: Value(commentCount != null
              ? BigInt.from(commentCount is int ? commentCount : int.parse(commentCount.toString()))
              : null),
        ),
      );
    }

    return videos;
  }

  Future<void> saveProgress(String userId, String videoId, int positionSeconds,
      int completedPercent) async {
    await _database.upsertProgress(
      ProgressCompanion.insert(
        id: '$userId-$videoId',
        userId: userId,
        videoId: videoId,
        positionSeconds: Value(positionSeconds),
        completedPercent: Value(completedPercent),
        synced: const Value(false),
      ),
    );

    try {
      await _apiClient.saveProgress({
        'userId': userId,
        'videoId': videoId,
        'positionSeconds': positionSeconds,
        'completedPercent': completedPercent,
      });
    } catch (e) {
      // Queue for sync later
    }
  }
}
