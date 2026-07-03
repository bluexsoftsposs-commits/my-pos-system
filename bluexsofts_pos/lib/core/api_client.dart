import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'env_config.dart';

class ApiClient {
  static String get baseUrl => EnvConfig.apiBaseUrl;
  static const String _tokenKey = 'auth_token';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove('user_data');
    await prefs.remove('shop_data');
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> get(String path) async {
    final headers = await _getHeaders();
    return http
        .get(Uri.parse('$baseUrl$path'), headers: headers)
        .timeout(const Duration(seconds: 15));
  }

  static Future<http.Response> post(String path, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    return http
        .post(Uri.parse('$baseUrl$path'), headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 15));
  }

  static Future<http.Response> put(String path, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    return http
        .put(Uri.parse('$baseUrl$path'), headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 15));
  }

  static Future<http.Response> patch(String path, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    return http
        .patch(Uri.parse('$baseUrl$path'), headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 15));
  }

  static Future<http.Response> delete(String path) async {
    final headers = await _getHeaders();
    return http
        .delete(Uri.parse('$baseUrl$path'), headers: headers)
        .timeout(const Duration(seconds: 15));
  }

  static Map<String, dynamic> parseResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': body};
      } else {
        return {
          'success': false,
          'error': body['error'] ?? 'Unknown error',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('Raw response (${response.statusCode}): ${response.body}');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': false, 'error': 'Empty response from server', 'statusCode': response.statusCode};
      }
      return {'success': false, 'error': response.body.isNotEmpty ? response.body : 'Empty response from server', 'statusCode': response.statusCode};
    }
  }
}
