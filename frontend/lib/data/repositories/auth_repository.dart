import '../remote/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final SharedPreferences _prefs;

  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserName = 'user_name';

  AuthRepository(this._apiClient, this._prefs);

  Future<Map<String, dynamic>> register(
      String email, String name, String password) async {
    print('📝 AuthRepository.register called with email: $email, name: $name');

    try {
      final response = await _apiClient.register({
        'email': email,
        'name': name,
        'password': password,
      });

      print('✅ Registration successful! Saving tokens...');
      await _saveTokens(
        response['accessToken'] as String,
        response['refreshToken'] as String,
        response['user']['id'] as String,
        response['user']['email'] as String,
        response['user']['name'] as String,
      );

      print('💾 Tokens saved. Registration complete.');
      return response;
    } catch (e) {
      print('❌ Registration failed: $e');
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    print('🔐 AuthRepository.login called with email: $email');

    try {
      print('📡 Calling backend API at login endpoint...');
      final response = await _apiClient.login({
        'email': email,
        'password': password,
      });

      print('✅ Login successful! Response received.');
      await _saveTokens(
        response['accessToken'] as String,
        response['refreshToken'] as String,
        response['user']['id'] as String,
        response['user']['email'] as String,
        response['user']['name'] as String,
      );

      print('💾 Tokens saved. Login complete.');
      return response;
    } catch (e) {
      print('❌ Login failed: $e');
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    await _prefs.clear();
  }

  Future<void> _saveTokens(String accessToken, String refreshToken,
      String userId, String email, String name) async {
    await _prefs.setString(_keyAccessToken, accessToken);
    await _prefs.setString(_keyRefreshToken, refreshToken);
    await _prefs.setString(_keyUserId, userId);
    await _prefs.setString(_keyUserEmail, email);
    await _prefs.setString(_keyUserName, name);
  }

  String? get accessToken => _prefs.getString(_keyAccessToken);
  String? get userId => _prefs.getString(_keyUserId);
  String? get userEmail => _prefs.getString(_keyUserEmail);
  String? get userName => _prefs.getString(_keyUserName);
  bool get isLoggedIn => accessToken != null && userId != null;
}
