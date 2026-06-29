import '../core/api_client.dart';

class PaymentService {
  Future<List<dynamic>?> getPlans() async {
    final response = await ApiClient.get('/payment/plans');
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] as List<dynamic> : null;
  }

  Future<Map<String, dynamic>?> initiatePayment({
    required String plan,
    required String paymentMethod,
  }) async {
    final response = await ApiClient.post('/payment/initiate', {
      'plan': plan,
      'paymentMethod': paymentMethod,
    });
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] : null;
  }

  Future<Map<String, dynamic>?> checkStatus(String paymentId) async {
    final response = await ApiClient.get('/payment/status/$paymentId');
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] : null;
  }

  Future<bool> verifyPayment(String transactionId) async {
    final response = await ApiClient.get('/payment/verify/$transactionId');
    return ApiClient.parseResponse(response)['success'] == true;
  }

  Future<Map<String, dynamic>?> getSubscriptionStatus() async {
    final response = await ApiClient.get('/payment/status');
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] : null;
  }
}
