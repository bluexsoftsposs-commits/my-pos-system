import '../core/api_client.dart';

class SupplierService {
  Future<Map<String, dynamic>?> register(Map<String, dynamic> data) async {
    final response = await ApiClient.post('/suppliers/register', data);
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] : null;
  }

  Future<Map<String, dynamic>?> getProfile(String id) async {
    final response = await ApiClient.get('/suppliers/$id');
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] : null;
  }

  Future<bool> updateProfile(String id, Map<String, dynamic> data) async {
    final response = await ApiClient.put('/suppliers/$id', data);
    return ApiClient.parseResponse(response)['success'] == true;
  }

  Future<Map<String, dynamic>?> getLedger(String id) async {
    final response = await ApiClient.get('/suppliers/$id/ledger');
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] : null;
  }

  Future<Map<String, dynamic>?> getTransactions(String id, {int page = 1, String? type}) async {
    String url = '/suppliers/$id/transactions?page=$page&limit=20';
    if (type != null && type.isNotEmpty) url += '&type=$type';
    final response = await ApiClient.get(url);
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] : null;
  }

  Future<Map<String, dynamic>?> createTransaction(String id, Map<String, dynamic> data) async {
    final response = await ApiClient.post('/suppliers/$id/transactions', data);
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] : null;
  }

  Future<Map<String, dynamic>?> getStats() async {
    final response = await ApiClient.get('/suppliers/stats');
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] : null;
  }

  // Shop-scoped supplier endpoints for Admin / Cashier with permission
  Future<Map<String, dynamic>?> getShopSuppliers() async {
    final response = await ApiClient.get('/suppliers/shop');
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] : null;
  }

  Future<Map<String, dynamic>?> createShopTransaction(String supplierId, Map<String, dynamic> data) async {
    final response = await ApiClient.post('/suppliers/$supplierId/shop-transactions', data);
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] : null;
  }
}
