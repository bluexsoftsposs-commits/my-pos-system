import '../core/api_client.dart';

class AdminService {
  Future<Map<String, dynamic>?> getStats() async {
    final response = await ApiClient.get('/superadmin/stats');
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] : null;
  }

  Future<Map<String, dynamic>?> getShops({int limit = 50}) async {
    final response = await ApiClient.get('/superadmin/shops?limit=$limit');
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] : null;
  }

  Future<Map<String, dynamic>?> getUsers({int limit = 50}) async {
    final response = await ApiClient.get('/superadmin/users?limit=$limit');
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] : null;
  }

  Future<bool> toggleShop(String shopId) async {
    final response = await ApiClient.put('/superadmin/shops/$shopId/toggle', {});
    return ApiClient.parseResponse(response)['success'] == true;
  }

  Future<bool> extendSubscription(String shopId, {int days = 30}) async {
    final response = await ApiClient.put('/superadmin/shops/$shopId/extend', {'days': days});
    return ApiClient.parseResponse(response)['success'] == true;
  }

  Future<bool> deactivateUser(String userId) async {
    final response = await ApiClient.delete('/superadmin/users/$userId');
    return ApiClient.parseResponse(response)['success'] == true;
  }

  Future<bool> createAdmin({
    required String shopName,
    required String name,
    required String email,
    required String password,
  }) async {
    final url = '${ApiClient.baseUrl}/superadmin/create-admin';
    final body = {
      'shopName': shopName,
      'name': name,
      'email': email,
      'password': password,
    };
    print('Creating admin at: $url');
    print('Request body: $body');
    try {
      final response = await ApiClient.post('/superadmin/create-admin', body);
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      return ApiClient.parseResponse(response)['success'] == true;
    } catch (e) {
      print('NETWORK ERROR in createAdmin: $e');
      return false;
    }
  }

  Future<bool> toggleAdminStatus(String userId) async {
    final response = await ApiClient.put('/superadmin/users/$userId/toggle', {});
    return ApiClient.parseResponse(response)['success'] == true;
  }
}
