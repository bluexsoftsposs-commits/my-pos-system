import 'package:flutter/foundation.dart';
import '../services/invoice_service.dart';
import '../models/invoice.dart';

class InvoiceProvider with ChangeNotifier {
  List<Invoice> _invoices = [];
  bool _isLoading = false;
  String? _error;

  final _invoiceService = InvoiceService();

  List<Invoice> get invoices => _invoices;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadInvoices({String? from, String? to, String? search}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _invoiceService.getInvoices(from: from, to: to, search: search);
      if (data != null) {
        _invoices = data.map((e) => Invoice.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        _error = 'Failed to load invoices';
      }
    } catch (e) {
      _error = 'Failed to load invoices';
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
