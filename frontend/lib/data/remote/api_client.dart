import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../../core/config/app_config.dart';

part 'api_client.g.dart';

@RestApi(baseUrl: AppConfig.apiBaseUrl)
abstract class ApiClient {
  factory ApiClient(Dio dio, {String baseUrl}) = _ApiClient;

  @POST('/auth/register')
  Future<dynamic> register(@Body() Map<String, dynamic> body);

  @POST('/auth/login')
  Future<dynamic> login(@Body() Map<String, dynamic> body);

  @POST('/auth/refresh')
  Future<dynamic> refreshToken(@Body() Map<String, dynamic> body);

  @GET('/videos/latest')
  Future<dynamic> getLatestVideos(
    @Query('channelId') String? channelId,
    @Query('maxResults') int? maxResults,
    @Query('category') String? category,
  );

  @GET('/videos/search')
  Future<dynamic> searchVideos(
    @Query('q') String query,
    @Query('maxResults') int? maxResults,
  );

  @GET('/videos/{videoId}')
  Future<dynamic> getVideo(@Path() String videoId);

  @GET('/videos/{videoId}/comments')
  Future<dynamic> getVideoComments(
    @Path() String videoId,
    @Query('maxResults') int? maxResults,
  );

  @POST('/videos/progress')
  Future<dynamic> saveProgress(@Body() Map<String, dynamic> body);

  @POST('/videos/favorites')
  Future<dynamic> toggleFavorite(@Body() Map<String, dynamic> body);

  @GET('/notifications')
  Future<dynamic> getNotifications(
    @Query('userId') String userId,
    @Query('limit') int? limit,
    @Query('since') String? since,
  );

  @POST('/notifications/send-test')
  Future<dynamic> sendTestPush(@Body() Map<String, dynamic> body);

  @DELETE('/notifications/{id}')
  Future<dynamic> deleteNotification(
    @Path() String id,
    @Query('userId') String userId,
  );

  @POST('/notifications/mark-read')
  Future<dynamic> markNotificationsRead(@Body() Map<String, dynamic> body);

  @PATCH('/users/{id}')
  Future<dynamic> updateUserProfile(
    @Path('id') String id,
    @Body() Map<String, dynamic> data,
  );

  @POST('/users/{userId}/fcmToken')
  Future<dynamic> registerFcmToken(
    @Path('userId') String userId,
    @Body() Map<String, dynamic> body,
  );
}
