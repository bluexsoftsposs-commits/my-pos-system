import 'package:flutter/foundation.dart';
import '../services/ledger_service.dart';
import '../models/customer.dart';
import '../models/ledger_entry.dart';

class LedgerProvider with ChangeNotifier {
  List<Customer> _customers = [];
  Customer? _selectedCustomer;
  List<LedgerEntry> _entries = [];
  bool _isLoading = false;
  String? _error;
  double _totalOutstanding = 0;

  final _ledgerService = LedgerService();

  List<Customer> get customers => _customers;
  Customer? get selectedCustomer => _selectedCustomer;
  List<LedgerEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get totalOutstanding => _totalOutstanding;

  Future<void> loadCustomers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _ledgerService.getCustomers();
      if (data != null) {
        _customers = data.map((e) => Customer.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      _error = 'Failed to load customers';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Customer?> findOrCreateCustomer(String name, {String? phone}) async {
    final data = await _ledgerService.createCustomer(name, phone: phone);
    if (data != null) {
      final customer = Customer.fromJson(data);
      final idx = _customers.indexWhere((c) => c.id == customer.id);
      if (idx >= 0) {
        _customers[idx] = customer;
      } else {
        _customers.add(customer);
      }
      notifyListeners();
      return customer;
    }
    return null;
  }

  Future<void> loadCustomerDetail(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _ledgerService.getCustomer(id);
      if (data != null) {
        _selectedCustomer = Customer.fromJson(data);
        _entries = ((data['entries'] as List<dynamic>?) ?? [])
            .map((e) => LedgerEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      _error = 'Failed to load customer details';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> recordPayment(String customerId, double amount, {String? note}) async {
    final data = await _ledgerService.recordPayment(customerId, amount, note: note);
    if (data != null) {
      _selectedCustomer = Customer.fromJson(data);
      await loadCustomerDetail(customerId);
      await loadOutstanding();
      return true;
    }
    return false;
  }

  Future<void> loadOutstanding() async {
    try {
      final data = await _ledgerService.getOutstanding();
      if (data != null) {
        _totalOutstanding = (data['totalOutstanding'] as num).toDouble();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> createManualDebit(String customerId, double amount, {String? note}) async {
    final data = await _ledgerService.createManualDebit(customerId, amount, note: note);
    if (data != null) {
      await loadCustomers();
      return true;
    }
    return false;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
