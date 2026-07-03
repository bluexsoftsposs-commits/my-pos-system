import '../core/api_client.dart';

class PlanService {
  Future<Map<String, dynamic>?> getSubscription(String shopId) async {
    final response = await ApiClient.get('/plans/shop/$shopId/subscription');
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] : null;
  }

  Future<List<dynamic>?> getAllPlans() async {
    final response = await ApiClient.get('/plans');
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] as List<dynamic> : null;
  }
}
