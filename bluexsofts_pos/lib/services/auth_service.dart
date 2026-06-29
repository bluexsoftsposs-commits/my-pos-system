import '../core/api_client.dart';

class AuthService {
  Future<Map<String, dynamic>?> login({
    required String shopName,
    required String email,
    required String password,
  }) async {
    final response = await ApiClient.post('/auth/login', {
      'shopName': shopName,
      'email': email,
      'password': password,
    });
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] : null;
  }

  Future<Map<String, dynamic>?> register({
    required String shopName,
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await ApiClient.post('/auth/register', {
      'shopName': shopName,
      'name': name,
      'email': email,
      'password': password,
    });
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] : null;
  }

  Future<Map<String, dynamic>?> getMe() async {
    final response = await ApiClient.get('/auth/me');
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] : null;
  }

  Future<void> saveToken(String token) => ApiClient.saveToken(token);
  Future<String?> getToken() => ApiClient.getToken();
  Future<void> clearToken() => ApiClient.clearToken();
}
