import '../core/api_client.dart';

class OnlineOrderService {
  Future<List<dynamic>?> getOnlineOrders({String? status}) async {
    final query = status != null ? '?status=$status' : '';
    final response = await ApiClient.get('/orders/online$query');
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] as List<dynamic> : null;
  }

  Future<Map<String, dynamic>?> updateOrderStatus(String orderId, String status) async {
    final response = await ApiClient.patch('/orders/online/$orderId/status', {'status': status});
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] as Map<String, dynamic> : null;
  }

  Future<int> getPendingCount() async {
    final response = await ApiClient.get('/orders/online/pending-count');
    final result = ApiClient.parseResponse(response);
    if (result['success'] && result['data'] is Map<String, dynamic>) {
      return (result['data'] as Map<String, dynamic>)['count'] as int? ?? 0;
    }
    return 0;
  }
}
