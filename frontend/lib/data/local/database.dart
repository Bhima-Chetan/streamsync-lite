import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

class Videos extends Table {
  TextColumn get videoId => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get thumbnailUrl => text()();
  TextColumn get channelId => text()();
  TextColumn get channelTitle => text()();
  DateTimeColumn get publishedAt => dateTime()();
  IntColumn get durationSeconds => integer()();
  Int64Column get viewCount => int64().nullable()();
  Int64Column get likeCount => int64().nullable()();
  Int64Column get commentCount => int64().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {videoId};
}

class Progress extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get videoId => text()();
  IntColumn get positionSeconds => integer().withDefault(const Constant(0))();
  IntColumn get completedPercent => integer().withDefault(const Constant(0))();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Favorites extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get videoId => text()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Notifications extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get metadata => text().nullable()();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get receivedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class PendingActions extends Table {
  TextColumn get id => text()();
  TextColumn get actionType => text()();
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
    tables: [Videos, Progress, Favorites, Notifications, PendingActions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // Handle upgrade from version 1 to any newer version
      if (from < 2) {
        // Add the new columns to the videos table
        await m.addColumn(videos, videos.likeCount);
        await m.addColumn(videos, videos.commentCount);
      }
      
      // Handle upgrade from version 2 to 3
      if (from < 3) {
        // Ensure all tables exist
        // Using createTableIfNotExists to avoid errors if tables already exist
        try {
          await m.createTable(progress);
        } catch (e) {
          // Table already exists, ignore
        }
        try {
          await m.createTable(favorites);
        } catch (e) {
          // Table already exists, ignore
        }
        try {
          await m.createTable(notifications);
        } catch (e) {
          // Table already exists, ignore
        }
        try {
          await m.createTable(pendingActions);
        } catch (e) {
          // Table already exists, ignore
        }
      }
    },
  );

  Future<List<Video>> getAllVideos() => select(videos).get();
  Future<Video?> getVideoById(String videoId) =>
      (select(videos)..where((v) => v.videoId.equals(videoId)))
          .getSingleOrNull();

  Future<int> insertVideo(VideosCompanion video) =>
      into(videos).insertOnConflictUpdate(video);

  Future<int> clearVideos() => delete(videos).go();

  Future<List<ProgressData>> getUserProgress(String userId) =>
      (select(progress)..where((p) => p.userId.equals(userId))).get();

  Future<int> upsertProgress(ProgressCompanion prog) =>
      into(progress).insertOnConflictUpdate(prog);

  Future<List<Notification>> getUserNotifications(String userId) =>
      (select(notifications)
            ..where((n) => n.userId.equals(userId) & n.isDeleted.equals(false))
            ..orderBy([(n) => OrderingTerm.desc(n.receivedAt)]))
          .get();

  Future<int> getUnreadNotificationCount(String userId) async {
    final query = selectOnly(notifications)
      ..addColumns([notifications.id.count()])
      ..where(notifications.userId.equals(userId) &
          notifications.isRead.equals(false) &
          notifications.isDeleted.equals(false));
    final result = await query.getSingle();
    return result.read(notifications.id.count()) ?? 0;
  }

  // Get a specific progress record
  Future<ProgressData?> getProgress(String id) =>
      (select(progress)..where((p) => p.id.equals(id))).getSingleOrNull();

  // Get all videos that have been watched (have progress)
  Future<List<Video>> getVideosWithProgress(String userId) async {
    final progressRecords = await (select(progress)
          ..where((p) => p.userId.equals(userId))
          ..orderBy([(p) => OrderingTerm.desc(p.updatedAt)]))
        .get();

    final videoIds = progressRecords.map((p) => p.videoId).toList();

    if (videoIds.isEmpty) {
      return [];
    }

    return (select(videos)..where((v) => v.videoId.isIn(videoIds))).get();
  }

  // Get all favorites for a user
  Future<List<Favorite>> getAllFavorites(String userId) =>
      (select(favorites)
            ..where((f) => f.userId.equals(userId))
            ..orderBy([(f) => OrderingTerm.desc(f.createdAt)]))
          .get();

  // Toggle favorite for a video
  Future<bool> toggleFavorite(String userId, String videoId) async {
    final existing = await (select(favorites)
          ..where((f) => f.userId.equals(userId) & f.videoId.equals(videoId)))
        .getSingleOrNull();

    if (existing != null) {
      await delete(favorites).delete(existing);
      return false;
    } else {
      await into(favorites).insert(FavoritesCompanion.insert(
        id: '$userId-$videoId',
        userId: userId,
        videoId: videoId,
        synced: const Value(false),
      ));
      return true;
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'streamsync_db.sqlite'));
    return NativeDatabase(file);
  });
}
