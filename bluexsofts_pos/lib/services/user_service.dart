import '../core/api_client.dart';

class UserService {
  Future<List<dynamic>?> getUsers() async {
    final response = await ApiClient.get('/users');
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] as List<dynamic> : null;
  }

  Future<Map<String, dynamic>?> createUser({
    required String name,
    required String email,
    required String password,
    String role = 'CASHIER',
  }) async {
    final response = await ApiClient.post('/users', {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    });
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] : null;
  }

  Future<bool> updateUser(String id, Map<String, dynamic> data) async {
    final response = await ApiClient.put('/users/$id', data);
    return ApiClient.parseResponse(response)['success'] == true;
  }

  Future<bool> deleteUser(String id) async {
    final response = await ApiClient.delete('/users/$id');
    return ApiClient.parseResponse(response)['success'] == true;
  }
}
