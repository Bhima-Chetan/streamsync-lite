import 'package:drift/drift.dart';
import 'database.dart';

class DatabaseSeeder {
  final AppDatabase _database;

  DatabaseSeeder(this._database);

  Future<void> seedMockData() async {
    // Check if data already exists
    final existingVideos = await _database.getAllVideos();
    if (existingVideos.isNotEmpty) {
      print('Database already seeded');
      return;
    }

    print('Seeding database with mock data...');

    // Seed videos
    await _seedVideos();

    // Seed notifications for demo user
    await _seedNotifications('demo-user-123');

    print('Database seeding complete!');
  }

  Future<void> _seedVideos() async {
    final mockVideos = [
      {
        'videoId': 'dQw4w9WgXcQ',
        'title': 'Flutter Tutorial - Complete Course for Beginners',
        'description':
            'Learn Flutter from scratch in this complete tutorial for beginners.',
        'thumbnailUrl': 'https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
        'channelId': 'UC_channel_1',
        'channelTitle': 'Tech Academy',
        'publishedAt': DateTime.now().subtract(const Duration(days: 5)),
        'durationSeconds': 3665,
        'viewCount': BigInt.from(1250000),
      },
      {
        'videoId': 'x7X9w_GIm1s',
        'title': 'Building Amazing Apps with Flutter and Firebase',
        'description': 'Step by step guide to create production-ready apps.',
        'thumbnailUrl': 'https://i.ytimg.com/vi/x7X9w_GIm1s/hqdefault.jpg',
        'channelId': 'UC_channel_2',
        'channelTitle': 'Code Masters',
        'publishedAt': DateTime.now().subtract(const Duration(days: 3)),
        'durationSeconds': 2430,
        'viewCount': BigInt.from(850000),
      },
      {
        'videoId': 'V1gU9I3xJYc',
        'title': 'State Management in Flutter - BLoC Pattern',
        'description':
            'Master the BLoC pattern for state management in Flutter.',
        'thumbnailUrl': 'https://i.ytimg.com/vi/V1gU9I3xJYc/hqdefault.jpg',
        'channelId': 'UC_channel_1',
        'channelTitle': 'Tech Academy',
        'publishedAt': DateTime.now().subtract(const Duration(days: 1)),
        'durationSeconds': 1820,
        'viewCount': BigInt.from(420000),
      },
      {
        'videoId': 'pTJJsmejUOQ',
        'title': 'Flutter Animation Masterclass',
        'description': 'Create beautiful animations in Flutter apps.',
        'thumbnailUrl': 'https://i.ytimg.com/vi/pTJJsmejUOQ/hqdefault.jpg',
        'channelId': 'UC_channel_3',
        'channelTitle': 'Design & Code',
        'publishedAt': DateTime.now().subtract(const Duration(hours: 12)),
        'durationSeconds': 2145,
        'viewCount': BigInt.from(310000),
      },
      {
        'videoId': 'Lf6tNnw87PY',
        'title': 'Advanced Flutter Widgets You Need to Know',
        'description': 'Explore powerful Flutter widgets for complex UIs.',
        'thumbnailUrl': 'https://i.ytimg.com/vi/Lf6tNnw87PY/hqdefault.jpg',
        'channelId': 'UC_channel_2',
        'channelTitle': 'Code Masters',
        'publishedAt': DateTime.now().subtract(const Duration(hours: 6)),
        'durationSeconds': 1560,
        'viewCount': BigInt.from(195000),
      },
      {
        'videoId': 'QhBVeZf966o',
        'title': 'Flutter Performance Optimization Tips',
        'description': 'Make your Flutter apps faster and more efficient.',
        'thumbnailUrl': 'https://i.ytimg.com/vi/QhBVeZf966o/hqdefault.jpg',
        'channelId': 'UC_channel_1',
        'channelTitle': 'Tech Academy',
        'publishedAt': DateTime.now().subtract(const Duration(days: 7)),
        'durationSeconds': 1925,
        'viewCount': BigInt.from(670000),
      },
      {
        'videoId': 'fjUGC2MJffE',
        'title': 'Building a Full Stack App with Flutter & Node.js',
        'description': 'Complete tutorial on creating full-stack applications.',
        'thumbnailUrl': 'https://i.ytimg.com/vi/fjUGC2MJffE/hqdefault.jpg',
        'channelId': 'UC_channel_3',
        'channelTitle': 'Design & Code',
        'publishedAt': DateTime.now().subtract(const Duration(days: 2)),
        'durationSeconds': 4320,
        'viewCount': BigInt.from(520000),
      },
      {
        'videoId': 'X3lKZ4QSBgQ',
        'title': 'Flutter Testing - Unit, Widget & Integration Tests',
        'description': 'Comprehensive guide to testing Flutter applications.',
        'thumbnailUrl': 'https://i.ytimg.com/vi/X3lKZ4QSBgQ/hqdefault.jpg',
        'channelId': 'UC_channel_2',
        'channelTitle': 'Code Masters',
        'publishedAt': DateTime.now().subtract(const Duration(hours: 18)),
        'durationSeconds': 2680,
        'viewCount': BigInt.from(280000),
      },
    ];

    for (final video in mockVideos) {
      await _database.insertVideo(
        VideosCompanion.insert(
          videoId: video['videoId'] as String,
          title: video['title'] as String,
          description: Value(video['description'] as String),
          thumbnailUrl: video['thumbnailUrl'] as String,
          channelId: video['channelId'] as String,
          channelTitle: video['channelTitle'] as String,
          publishedAt: video['publishedAt'] as DateTime,
          durationSeconds: video['durationSeconds'] as int,
          viewCount: Value(video['viewCount'] as BigInt),
        ),
      );
    }

    print('Seeded ${mockVideos.length} videos');
  }

  Future<void> _seedNotifications(String userId) async {
    final mockNotifications = [
      {
        'id': 'notif_1',
        'title': 'New video from Tech Academy',
        'body': 'Flutter Tutorial - Complete Course for Beginners',
        'metadata': '{"videoId": "dQw4w9WgXcQ", "type": "new_video"}',
        'isRead': false,
        'receivedAt': DateTime.now().subtract(const Duration(hours: 2)),
      },
      {
        'id': 'notif_2',
        'title': 'Someone liked your comment',
        'body': 'John Doe liked your comment on "Building Amazing Apps"',
        'metadata': '{"videoId": "x7X9w_GIm1s", "type": "comment_like"}',
        'isRead': false,
        'receivedAt': DateTime.now().subtract(const Duration(hours: 5)),
      },
      {
        'id': 'notif_3',
        'title': 'New subscriber',
        'body': 'Sarah Smith subscribed to your channel',
        'metadata': '{"type": "new_subscriber"}',
        'isRead': true,
        'receivedAt': DateTime.now().subtract(const Duration(days: 1)),
      },
      {
        'id': 'notif_4',
        'title': 'Recommended for you',
        'body': 'Flutter Animation Masterclass',
        'metadata': '{"videoId": "pTJJsmejUOQ", "type": "recommendation"}',
        'isRead': true,
        'receivedAt': DateTime.now().subtract(const Duration(days: 2)),
      },
      {
        'id': 'notif_5',
        'title': 'New video from Code Masters',
        'body': 'Advanced Flutter Widgets You Need to Know',
        'metadata': '{"videoId": "Lf6tNnw87PY", "type": "new_video"}',
        'isRead': false,
        'receivedAt': DateTime.now().subtract(const Duration(minutes: 30)),
      },
    ];

    for (final notif in mockNotifications) {
      await _database.into(_database.notifications).insert(
            NotificationsCompanion.insert(
              id: notif['id'] as String,
              userId: userId,
              title: notif['title'] as String,
              body: notif['body'] as String,
              metadata: Value(notif['metadata'] as String?),
              isRead: Value(notif['isRead'] as bool),
              receivedAt: Value(notif['receivedAt'] as DateTime),
            ),
          );
    }

    print('Seeded ${mockNotifications.length} notifications');
  }

  Future<void> clearAllData() async {
    await _database.delete(_database.videos).go();
    await _database.delete(_database.favorites).go();
    await _database.delete(_database.notifications).go();
    await _database.delete(_database.progress).go();
    print('All data cleared');
  }
}
