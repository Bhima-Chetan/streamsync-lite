import 'package:flutter/material.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/video/video_player_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/search/search_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String videoPlayer = '/video-player';
  static const String profile = '/profile';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String search = '/search';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
        );

      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );

      case register:
        return MaterialPageRoute(
          builder: (_) => const RegisterScreen(),
        );

      case home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );

      case videoPlayer:
        final args = settings.arguments as Map<String, dynamic>?;
        
        // Helper function to safely parse BigInt from dynamic
        BigInt? parseBigInt(dynamic value) {
          if (value == null) return null;
          if (value is BigInt) return value;
          if (value is int) return BigInt.from(value);
          if (value is String) return BigInt.tryParse(value);
          return null;
        }
        
        return MaterialPageRoute(
          builder: (_) => VideoPlayerScreen(
            videoId: args?['videoId']?.toString() ?? 'dQw4w9WgXcQ',
            title: args?['title']?.toString(),
            description: args?['description']?.toString(),
            channelTitle: args?['channelTitle']?.toString(),
            viewCount: parseBigInt(args?['viewCount']),
            likeCount: parseBigInt(args?['likeCount']),
            commentCount: parseBigInt(args?['commentCount']),
            publishedAt: args?['publishedAt'] != null 
                ? DateTime.parse(args!['publishedAt'] as String)
                : null,
          ),
        );

      case profile:
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
        );

      case notifications:
        return MaterialPageRoute(
          builder: (_) => const NotificationsScreen(),
        );

      case search:
        return MaterialPageRoute(
          builder: (_) => const SearchScreen(),
        );

      case '/settings':
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Settings Screen - Coming Soon')),
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('404 - Page Not Found')),
          ),
        );
    }
  }
}
