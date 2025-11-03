import 'package:get_it/get_it.dart';
import '../../data/local/database.dart';
import '../../data/remote/api_client.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/video_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/services/sync_service.dart';
import '../../data/services/connectivity_service.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/blocs/theme/theme_cubit.dart';
import '../../presentation/blocs/videos/videos_bloc.dart';
import '../../presentation/blocs/notifications/notifications_bloc.dart';
import '../../presentation/blocs/favorites/favorites_bloc.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);

  final database = AppDatabase();
  getIt.registerSingleton<AppDatabase>(database);

  final dio = Dio(BaseOptions(
    baseUrl: 'http://3.85.120.15', // AWS EC2 instance
    connectTimeout: const Duration(seconds: 10), // Reduced from 30
    receiveTimeout: const Duration(seconds: 15), // Reduced from 30
    sendTimeout: const Duration(seconds: 10),
  ));
  
  // Add interceptor to include auth token in requests
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      // Get the access token from SharedPreferences
      final token = sharedPreferences.getString('access_token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
        print('🔑 Auth token added to request: ${options.path}');
      } else {
        print('⚠️ No auth token found for request: ${options.path}');
      }
      return handler.next(options);
    },
    onError: (error, handler) async {
      print('❌ Dio Error: ${error.message}');
      print('❌ Response: ${error.response?.data}');
      print('❌ Status Code: ${error.response?.statusCode}');
      return handler.next(error);
    },
  ));
  
  getIt.registerSingleton<Dio>(dio);

  final apiClient = ApiClient(dio);
  getIt.registerSingleton<ApiClient>(apiClient);

  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(apiClient, sharedPreferences),
  );

  getIt.registerLazySingleton<VideoRepository>(
    () => VideoRepository(apiClient, database),
  );

  getIt.registerLazySingleton<NotificationRepository>(
    () => NotificationRepository(apiClient, database),
  );

  getIt.registerLazySingleton<SyncService>(
    () => SyncService(database, apiClient),
  );

  getIt.registerLazySingleton<ConnectivityService>(
    () => ConnectivityService(getIt<SyncService>()),
  );

  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(getIt<AuthRepository>()),
  );

  getIt.registerFactory<ThemeCubit>(
    () => ThemeCubit(sharedPreferences),
  );

  getIt.registerFactory<VideosBloc>(
    () => VideosBloc(getIt<VideoRepository>()),
  );

  getIt.registerFactory<NotificationsBloc>(
    () => NotificationsBloc(getIt<AppDatabase>()),
  );

  getIt.registerFactory<FavoritesBloc>(
    () => FavoritesBloc(getIt<AppDatabase>()),
  );
}
