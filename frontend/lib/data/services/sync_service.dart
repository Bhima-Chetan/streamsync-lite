import 'dart:convert';
import 'package:drift/drift.dart';
import '../local/database.dart';
import '../remote/api_client.dart';

/// Service responsible for syncing local changes to the backend
class SyncService {
  final AppDatabase _database;
  final ApiClient _apiClient;

  SyncService(this._database, this._apiClient);

  /// Sync all pending actions to the backend
  Future<void> syncPendingActions(String userId) async {
    try {
      // Get all pending actions
      final pendingActions = await (_database.select(_database.pendingActions)
            ..orderBy([(a) => OrderingTerm.asc(a.createdAt)]))
          .get();

      if (pendingActions.isEmpty) {
        return;
      }

      print('Syncing ${pendingActions.length} pending actions...');

      for (final action in pendingActions) {
        try {
          await _processPendingAction(userId, action);

          // Delete successfully synced action
          await (_database.delete(_database.pendingActions)
                ..where((a) => a.id.equals(action.id)))
              .go();
        } catch (e) {
          print('Failed to sync action ${action.id}: $e');
          // Continue with other actions
        }
      }

      print('Sync completed');
    } catch (e) {
      print('Sync error: $e');
    }
  }

  Future<void> _processPendingAction(
      String userId, PendingAction action) async {
    final payload = jsonDecode(action.payload) as Map<String, dynamic>;

    switch (action.actionType) {
      case 'save_progress':
        await _apiClient.saveProgress({
          'userId': userId,
          'videoId': payload['videoId'],
          'positionSeconds': payload['positionSeconds'],
          'completedPercent': payload['completedPercent'],
        });

        // Mark as synced in local database
        await _database.update(_database.progress).replace(
              ProgressCompanion(
                id: Value(payload['id'] as String),
                synced: const Value(true),
              ),
            );
        break;

      case 'toggle_favorite':
        await _apiClient.toggleFavorite({
          'userId': userId,
          'videoId': payload['videoId'],
        });

        // Mark as synced in local database
        await _database.update(_database.favorites).replace(
              FavoritesCompanion(
                id: Value(payload['id'] as String),
                synced: const Value(true),
              ),
            );
        break;

      case 'delete_notification':
        await _apiClient.deleteNotification(
          payload['notificationId'] as String,
          userId,
        );
        break;

      case 'mark_notifications_read':
        await _apiClient.markNotificationsRead({
          'userId': userId,
          'notificationIds': payload['notificationIds'],
        });
        break;

      default:
        print('Unknown action type: ${action.actionType}');
    }
  }

  /// Queue a local action to be synced later
  Future<void> queueAction(String actionType, Map<String, dynamic> payload) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    
    await _database.into(_database.pendingActions).insert(
          PendingActionsCompanion.insert(
            id: id,
            actionType: actionType,
            payload: jsonEncode(payload),
          ),
        );
  }

  /// Get count of pending actions
  Future<int> getPendingActionCount() async {
    final query = _database.selectOnly(_database.pendingActions)
      ..addColumns([_database.pendingActions.id.count()]);
    final result = await query.getSingle();
    return result.read(_database.pendingActions.id.count()) ?? 0;
  }
}
