import '../core/api_client.dart';

class ProductService {
  Future<List<dynamic>?> getProducts() async {
    final response = await ApiClient.get('/products');
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] as List<dynamic> : null;
  }

  Future<Map<String, dynamic>?> createProduct(Map<String, dynamic> data) async {
    final response = await ApiClient.post('/products', data);
    final result = ApiClient.parseResponse(response);
    if (result['success']) return result['data'];
    throw Exception(result['error'] ?? 'Failed to create product');
  }

  Future<Map<String, dynamic>?> updateProduct(String id, Map<String, dynamic> data) async {
    final response = await ApiClient.put('/products/$id', data);
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] : null;
  }

  Future<bool> deleteProduct(String id) async {
    final response = await ApiClient.delete('/products/$id');
    return ApiClient.parseResponse(response)['success'] == true;
  }

  Future<Map<String, dynamic>?> findProductByBarcode(String barcode) async {
    final response = await ApiClient.get('/products/barcode/$barcode');
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] as Map<String, dynamic> : null;
  }

  Future<Map<String, dynamic>?> getLowStockProducts() async {
    final response = await ApiClient.get('/products/low-stock');
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] as Map<String, dynamic> : null;
  }
}
