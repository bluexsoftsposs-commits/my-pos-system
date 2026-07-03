import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/online_order_service.dart';

class OnlineOrderProvider with ChangeNotifier {
  final OnlineOrderService _service = OnlineOrderService();

  List<dynamic> _orders = [];
  int _pendingCount = 0;
  bool _isLoading = false;
  String? _error;
  Timer? _pollTimer;

  List<dynamic> get orders => _orders;
  int get pendingCount => _pendingCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  OnlineOrderProvider() {
    startPolling();
  }

  void startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 12), (_) async {
      await _fetchPendingCount();
    });
    _fetchPendingCount();
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _fetchPendingCount() async {
    try {
      _pendingCount = await _service.getPendingCount();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadOrders({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _service.getOnlineOrders(status: status);
      if (data != null) {
        _orders = data;
      } else {
        _error = 'Failed to load orders';
      }
    } catch (e) {
      _error = 'Connection error';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateStatus(String orderId, String status) async {
    try {
      final result = await _service.updateOrderStatus(orderId, status);
      if (result != null) {
        await loadOrders(status: 'PENDING');
        await _fetchPendingCount();
        return true;
      }
    } catch (_) {}
    return false;
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
