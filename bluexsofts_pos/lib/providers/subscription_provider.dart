import 'package:flutter/foundation.dart';
import '../services/payment_service.dart';
import '../models/user.dart';

class SubscriptionProvider with ChangeNotifier {
  List<Plan> _plans = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _paymentResult;

  final _paymentService = PaymentService();

  List<Plan> get plans => _plans;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get paymentResult => _paymentResult;

  Future<bool> loadPlans() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _paymentService.getPlans();
      if (data != null) {
        _plans = data.map((p) => Plan.fromJson(p as Map<String, dynamic>)).toList();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<Map<String, dynamic>?> initiatePayment({
    required String plan,
    required String paymentMethod,
  }) async {
    _isLoading = true;
    _error = null;
    _paymentResult = null;
    notifyListeners();

    try {
      final data = await _paymentService.initiatePayment(plan: plan, paymentMethod: paymentMethod);
      _isLoading = false;
      if (data != null) {
        _paymentResult = data;
        notifyListeners();
        return data;
      } else {
        _error = 'Payment initiation failed';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = 'Connection error. Check server is running.';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> verifyPayment(String transactionId) async {
    return _paymentService.verifyPayment(transactionId);
  }

  void clearPaymentResult() {
    _paymentResult = null;
    _error = null;
    notifyListeners();
  }
}
