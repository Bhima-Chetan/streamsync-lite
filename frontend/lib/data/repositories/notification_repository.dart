import 'package:drift/drift.dart';
import '../local/database.dart';
import '../remote/api_client.dart';

class NotificationRepository {
  final ApiClient _apiClient;
  final AppDatabase _database;

  NotificationRepository(this._apiClient, this._database);

  Future<List<Notification>> getUserNotifications(String userId,
      {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      return _database.getUserNotifications(userId);
    }

    final response = await _apiClient.getNotifications(userId, 50, null);

    for (final notifData in response) {
      await _database.into(_database.notifications).insertOnConflictUpdate(
            NotificationsCompanion.insert(
              id: notifData['id'] as String,
              userId: notifData['userId'] as String,
              title: notifData['title'] as String,
              body: notifData['body'] as String,
              metadata: Value(notifData['metadata']?.toString()),
              isRead: Value(notifData['isRead'] as bool? ?? false),
              isDeleted: Value(notifData['isDeleted'] as bool? ?? false),
              receivedAt:
                  Value(DateTime.parse(notifData['receivedAt'] as String)),
            ),
          );
    }

    return _database.getUserNotifications(userId);
  }

  Future<int> getUnreadCount(String userId) {
    return _database.getUnreadNotificationCount(userId);
  }

  Future<void> deleteNotification(String userId, String notificationId) async {
    await _database.update(_database.notifications).replace(
          NotificationsCompanion(
            id: Value(notificationId),
            isDeleted: const Value(true),
          ),
        );

    try {
      await _apiClient.deleteNotification(notificationId, userId);
    } catch (e) {
      // Queue for sync later
    }
  }

  Future<void> sendTestPush(String title, String body) async {
    await _apiClient.sendTestPush({
      'title': title,
      'body': body,
    });
  }
}
