import '../core/api_client.dart';

class SaleService {
  Future<List<dynamic>?> getSales() async {
    final response = await ApiClient.get('/sales');
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] as List<dynamic> : null;
  }

  Future<Map<String, dynamic>?> getSummary() async {
    final response = await ApiClient.get('/sales/summary');
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] : null;
  }

  Future<Map<String, dynamic>?> createSale(Map<String, dynamic> payload) async {
    final response = await ApiClient.post('/sales', payload);
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] : null;
  }
}
