import 'dart:convert';
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

  Future<String?> forgotPassword({
    required String shopName,
    required String email,
  }) async {
    final response = await ApiClient.post('/auth/forgot-password', {
      'shopName': shopName,
      'email': email,
    });
    final result = ApiClient.parseResponse(response);
    final success = result['success'] as bool? ?? false;
    if (success) {
      final data = result['data'];
      if (data is Map<String, dynamic>) {
        return data['message'] as String?;
      }
      return null;
    }
    return result['error'] as String?;
  }

  Future<String?> resetPassword({
    required String token,
    required String password,
  }) async {
    final response = await ApiClient.post('/auth/reset-password', {
      'token': token,
      'password': password,
    });
    final result = ApiClient.parseResponse(response);
    final success = result['success'] as bool? ?? false;
    if (success) {
      final data = result['data'];
      if (data is Map<String, dynamic>) {
        return data['message'] as String?;
      }
      return null;
    }
    return result['error'] as String?;
  }

  Future<String?> resendVerification({
    required String email,
    required String shopId,
  }) async {
    final response = await ApiClient.post('/auth/resend-verification', {
      'email': email,
      'shopId': shopId,
    });
    final result = ApiClient.parseResponse(response);
    final success = result['success'] as bool? ?? false;
    if (success) {
      final data = result['data'];
      if (data is Map<String, dynamic>) {
        return data['message'] as String?;
      }
      return null;
    }
    return result['error'] as String?;
  }

  Future<void> saveToken(String token) => ApiClient.saveToken(token);
  Future<String?> getToken() => ApiClient.getToken();
  Future<void> clearToken() => ApiClient.clearToken();
}
