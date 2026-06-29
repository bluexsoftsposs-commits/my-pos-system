import '../core/api_client.dart';

class AdminService {
  Future<Map<String, dynamic>?> getStats() async {
    final response = await ApiClient.get('/admin/stats');
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] : null;
  }

  Future<Map<String, dynamic>?> getShops({int limit = 50}) async {
    final response = await ApiClient.get('/admin/shops?limit=$limit');
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] : null;
  }

  Future<Map<String, dynamic>?> getUsers({int limit = 50}) async {
    final response = await ApiClient.get('/admin/users?limit=$limit');
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] : null;
  }

  Future<bool> toggleShop(String shopId) async {
    final response = await ApiClient.put('/admin/shops/$shopId/toggle', {});
    return ApiClient.parseResponse(response)['success'] == true;
  }

  Future<bool> extendSubscription(String shopId, {int days = 30}) async {
    final response = await ApiClient.put('/admin/shops/$shopId/extend', {'days': days});
    return ApiClient.parseResponse(response)['success'] == true;
  }

  Future<bool> deactivateUser(String userId) async {
    final response = await ApiClient.delete('/admin/users/$userId');
    return ApiClient.parseResponse(response)['success'] == true;
  }
}
