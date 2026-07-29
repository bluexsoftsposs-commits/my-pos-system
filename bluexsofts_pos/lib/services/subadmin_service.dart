import '../core/api_client.dart';

class SubAdminService {
  // Super admin manages sub-admins
  Future<Map<String, dynamic>?> createSubAdmin(Map<String, dynamic> data) async {
    final response = await ApiClient.post('/subadmins', data);
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] : null;
  }

  Future<Map<String, dynamic>?> getSubAdmins() async {
    final response = await ApiClient.get('/subadmins');
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] : null;
  }

  Future<bool> updateSubAdmin(String id, Map<String, dynamic> data) async {
    final response = await ApiClient.put('/subadmins/$id', data);
    return ApiClient.parseResponse(response)['success'] == true;
  }

  Future<bool> deleteSubAdmin(String id) async {
    final response = await ApiClient.delete('/subadmins/$id');
    return ApiClient.parseResponse(response)['success'] == true;
  }

  // Sub-admin self-service
  Future<Map<String, dynamic>?> createAdmin(Map<String, dynamic> data) async {
    final response = await ApiClient.post('/subadmins/admins', data);
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] : null;
  }

  Future<Map<String, dynamic>?> editAdmin(String id, Map<String, dynamic> data) async {
    final response = await ApiClient.put('/subadmins/admins/$id', data);
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] : null;
  }

  Future<Map<String, dynamic>?> getAdmins() async {
    final response = await ApiClient.get('/subadmins/admins');
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] : null;
  }

  Future<Map<String, dynamic>?> createShop(Map<String, dynamic> data) async {
    final response = await ApiClient.post('/subadmins/shops', data);
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] : null;
  }

  Future<Map<String, dynamic>?> editShop(String id, Map<String, dynamic> data) async {
    final response = await ApiClient.put('/subadmins/shops/$id', data);
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] : null;
  }

  Future<Map<String, dynamic>?> getShops() async {
    final response = await ApiClient.get('/subadmins/shops');
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] : null;
  }

  Future<Map<String, dynamic>?> changePlan(String shopId, String planId) async {
    final response = await ApiClient.put('/subadmins/shops/$shopId/plan', {'planId': planId});
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] : null;
  }

  Future<Map<String, dynamic>?> getReports() async {
    final response = await ApiClient.get('/subadmins/reports');
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] : null;
  }
}
