import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/services/firebase_messaging_service.dart';
import 'core/di/injection.dart';
import 'core/config/app_config.dart';
import 'core/config/theme_config.dart';
import 'presentation/routes/app_router.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/theme/theme_cubit.dart';
import 'presentation/blocs/videos/videos_bloc.dart';
import 'presentation/blocs/favorites/favorites_bloc.dart';
import 'presentation/blocs/notifications/notifications_bloc.dart';
import 'data/local/database.dart';
import 'data/local/seed_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase with platform-specific options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Firebase Messaging
    await FirebaseMessagingService.initialize();

    // Get FCM token and log it
    final fcmToken = await FirebaseMessagingService.getToken();
    debugPrint('🔔 FCM Token: $fcmToken');
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  await configureDependencies();

  // Seed database with mock data on first run
  try {
    final database = getIt<AppDatabase>();
    final seeder = DatabaseSeeder(database);
    await seeder.seedMockData();
  } catch (e) {
    debugPrint('Error seeding database: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<AuthBloc>()),
        BlocProvider(create: (_) => getIt<ThemeCubit>()),
        BlocProvider(create: (_) => getIt<VideosBloc>()..add(LoadVideos())),
        BlocProvider(create: (_) => getIt<FavoritesBloc>()),
        BlocProvider(create: (_) => getIt<NotificationsBloc>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            title: AppConfig.appName,
            debugShowCheckedModeBanner: false,
            theme: ThemeConfig.lightTheme,
            darkTheme: ThemeConfig.darkTheme,
            themeMode: themeMode,
            onGenerateRoute: AppRouter.onGenerateRoute,
            initialRoute: AppRouter.splash,
          );
        },
      ),
    );
  }
}
