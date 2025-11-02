import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:drift/drift.dart';
import '../../../data/local/database.dart';

// Events
abstract class NotificationsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadNotifications extends NotificationsEvent {
  final String userId;
  LoadNotifications(this.userId);
  @override
  List<Object?> get props => [userId];
}

class MarkNotificationAsRead extends NotificationsEvent {
  final String userId;
  final String notificationId;

  MarkNotificationAsRead(this.userId, this.notificationId);

  @override
  List<Object?> get props => [userId, notificationId];
}

class DeleteNotification extends NotificationsEvent {
  final String userId;
  final String notificationId;

  DeleteNotification(this.userId, this.notificationId);

  @override
  List<Object?> get props => [userId, notificationId];
}

class MarkAllAsRead extends NotificationsEvent {
  final String userId;
  MarkAllAsRead(this.userId);
  @override
  List<Object?> get props => [userId];
}

class RefreshNotifications extends NotificationsEvent {
  final String userId;
  RefreshNotifications(this.userId);
  @override
  List<Object?> get props => [userId];
}

// States
abstract class NotificationsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class NotificationsInitial extends NotificationsState {}

class NotificationsLoading extends NotificationsState {}

class NotificationsLoaded extends NotificationsState {
  final List<Notification> notifications;
  final int unreadCount;

  NotificationsLoaded(this.notifications, this.unreadCount);

  @override
  List<Object?> get props => [notifications, unreadCount];
}

class NotificationsError extends NotificationsState {
  final String message;
  NotificationsError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final AppDatabase _database;

  NotificationsBloc(this._database) : super(NotificationsInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<MarkNotificationAsRead>(_onMarkAsRead);
    on<DeleteNotification>(_onDeleteNotification);
    on<MarkAllAsRead>(_onMarkAllAsRead);
    on<RefreshNotifications>(_onRefreshNotifications);
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(NotificationsLoading());

    try {
      final notifications = await _database.getUserNotifications(event.userId);
      final unreadCount =
          await _database.getUnreadNotificationCount(event.userId);

      emit(NotificationsLoaded(notifications, unreadCount));
    } catch (e) {
      emit(NotificationsError('Failed to load notifications: ${e.toString()}'));
    }
  }

  Future<void> _onMarkAsRead(
    MarkNotificationAsRead event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      await (_database.update(_database.notifications)
            ..where((n) => n.id.equals(event.notificationId)))
          .write(NotificationsCompanion(
        isRead: const Value(true),
      ));

      // Reload notifications
      add(LoadNotifications(event.userId));
    } catch (e) {
      print('Failed to mark notification as read: $e');
    }
  }

  Future<void> _onDeleteNotification(
    DeleteNotification event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      await (_database.update(_database.notifications)
            ..where((n) => n.id.equals(event.notificationId)))
          .write(NotificationsCompanion(
        isDeleted: const Value(true),
      ));

      // Reload notifications
      add(LoadNotifications(event.userId));
    } catch (e) {
      print('Failed to delete notification: $e');
    }
  }

  Future<void> _onMarkAllAsRead(
    MarkAllAsRead event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      await (_database.update(_database.notifications)
            ..where((n) => n.userId.equals(event.userId)))
          .write(NotificationsCompanion(
        isRead: const Value(true),
      ));

      // Reload notifications
      add(LoadNotifications(event.userId));
    } catch (e) {
      print('Failed to mark all as read: $e');
    }
  }

  Future<void> _onRefreshNotifications(
    RefreshNotifications event,
    Emitter<NotificationsState> emit,
  ) async {
    // TODO: Fetch from backend when ready
    add(LoadNotifications(event.userId));
  }
}
