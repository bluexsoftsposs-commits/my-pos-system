import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/sale_service.dart';
import '../core/constants.dart';
import '../models/sale.dart';

class SaleProvider with ChangeNotifier {
  List<Sale> _sales = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _summary;

  final _saleService = SaleService();

  List<Sale> get sales => _sales;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get summary => _summary;

  Future<void> loadSales() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _saleService.getSales();
      if (data != null) {
        _sales = data.map((e) => Sale.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        _error = 'Failed to load sales';
      }
    } catch (e) {
      _error = 'Failed to load sales';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadSummary() async {
    try {
      final data = await _saleService.getSummary();
      if (data != null) {
        _summary = data;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<Sale?> createSale(Map<String, dynamic> payload) async {
    try {
      final data = await _saleService.createSale(payload);
      if (data != null) {
        final sale = Sale.fromJson(data);
        _sales.insert(0, sale);
        notifyListeners();
        return sale;
      }
    } catch (_) {}

    final box = Hive.box(AppConstants.offlineQueueBox);
    final queue = box.get('sales', defaultValue: <String>[]).cast<String>();
    queue.add(jsonEncode(payload));
    await box.put('sales', queue);
    return null;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
