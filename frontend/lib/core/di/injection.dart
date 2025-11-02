import 'package:get_it/get_it.dart';
import '../../data/local/database.dart';
import '../../data/remote/api_client.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/video_repository.dart';
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

  final dio = Dio();
  getIt.registerSingleton<Dio>(dio);

  final apiClient = ApiClient(dio);
  getIt.registerSingleton<ApiClient>(apiClient);

  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(apiClient, sharedPreferences),
  );

  getIt.registerLazySingleton<VideoRepository>(
    () => VideoRepository(apiClient, database),
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
