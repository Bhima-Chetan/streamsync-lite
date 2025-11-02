import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

import '../../data/remote/api_client.dart';
import '../di/injection.dart';

// Top-level background message handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  developer.log('Handling background message: ${message.messageId}');

  // Show notification even when app is in background
  await FirebaseMessagingService._showNotification(message);
}

class FirebaseMessagingService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  // Initialize Firebase Messaging
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request permission for iOS
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      developer.log('FCM Permission status: ${settings.authorizationStatus}');

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Set up foreground notification handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        developer
            .log('Foreground message received: ${message.notification?.title}');
        _showNotification(message);
      });

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Handle notification tap when app is in background/terminated
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        developer.log('Notification tapped: ${message.data}');
        _handleNotificationTap(message);
      });

      // Check if app was opened from a notification
      RemoteMessage? initialMessage =
          await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        developer.log('App opened from notification: ${initialMessage.data}');
        _handleNotificationTap(initialMessage);
      }

      _isInitialized = true;
      developer.log('Firebase Messaging initialized successfully');
    } catch (e) {
      developer.log('Error initializing Firebase Messaging: $e', error: e);
    }
  }

  // Initialize local notifications plugin
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        developer.log('Local notification tapped: ${response.payload}');
        // Handle notification tap
      },
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'streamsync_notifications',
      'StreamSync Notifications',
      description: 'Notifications for new videos, comments, and updates',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Show local notification
  static Future<void> _showNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;

    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'streamsync_notifications',
            'StreamSync Notifications',
            channelDescription:
                'Notifications for new videos, comments, and updates',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data['videoId'] ?? message.data['route'],
      );
    }
  }

  // Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    // TODO: Navigate to specific screen based on notification data
    final data = message.data;

    if (data.containsKey('videoId')) {
      // Navigate to video player
      developer.log('Should navigate to video: ${data['videoId']}');
    } else if (data.containsKey('route')) {
      // Navigate to specific route
      developer.log('Should navigate to route: ${data['route']}');
    }
  }

  // Get FCM token
  static Future<String?> getToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      developer.log('FCM Token: $token');

      // Save token to SharedPreferences
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', token);
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        developer.log('FCM Token refreshed: $newToken');
        SharedPreferences.getInstance().then((prefs) {
          prefs.setString('fcm_token', newToken);
        });
        // TODO: Send new token to backend
      });

      return token;
    } catch (e) {
      developer.log('Error getting FCM token: $e', error: e);
      return null;
    }
  }

  // Subscribe to topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      developer.log('Subscribed to topic: $topic');
    } catch (e) {
      developer.log('Error subscribing to topic: $e', error: e);
    }
  }

  // Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      developer.log('Unsubscribed from topic: $topic');
    } catch (e) {
      developer.log('Error unsubscribing from topic: $e', error: e);
    }
  }

  // Send FCM token to backend
  static Future<void> sendTokenToBackend(String userId, String token) async {
    // TODO: Implement API call to send token to backend
    // Example: await apiClient.updateFcmToken(userId, token);
    developer.log('Should send FCM token to backend for user: $userId');
  }

  // Register FCM token with backend after login
  static Future<void> registerTokenWithBackend(String userId) async {
    try {
      // Get the current FCM token
      final token = await getToken();

      if (token == null) {
        developer.log('Failed to get FCM token', error: 'Token is null');
        return;
      }

      developer.log('Registering FCM token with backend for user: $userId');

      // Import ApiClient using dependency injection
      final apiClient = _getApiClient();

      // Register token with backend
      await apiClient.registerFcmToken({
        'userId': userId,
        'token': token,
        'platform': 'android', // TODO: Detect platform (android/ios)
      });

      developer.log('Successfully registered FCM token with backend');
    } catch (e) {
      developer.log('Error registering FCM token with backend: $e', error: e);
    }
  }

  // Helper to get ApiClient from dependency injection
  static ApiClient _getApiClient() {
    return getIt<ApiClient>();
  }
}
