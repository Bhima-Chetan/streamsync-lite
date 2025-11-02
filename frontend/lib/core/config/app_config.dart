class AppConfig {
  static const String appName = 'StreamSync Lite';
  static const String apiBaseUrl =
      'http://192.168.1.8:3000'; // Physical device - PC IP
  static const String apiVersion = 'v1';

  static const int cacheExpiryHours = 24;
  static const int syncRetryAttempts = 3;
  static const int syncRetryDelaySeconds = 5;

  static const int notificationBadgeMax = 99;
  static const int videoProgressSaveInterval = 10; // seconds
}
