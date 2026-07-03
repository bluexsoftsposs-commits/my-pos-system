import 'package:flutter/foundation.dart';
import '../core/api_client.dart';

class LedgerService {
  Future<List<dynamic>?> getCustomers() async {
    final response = await ApiClient.get('/ledger/customers');
    final result = ApiClient.parseResponse(response);
    if (!result['success']) debugPrint('getCustomers error: ${result['error']} (status: ${result['statusCode']})');
    return result['success'] ? result['data'] as List<dynamic> : null;
  }

  Future<Map<String, dynamic>?> createCustomer(String name, {String? phone}) async {
    final body = {
      'name': name,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    };
    debugPrint('createCustomer request: $body');
    final response = await ApiClient.post('/ledger/customers', body);
    final result = ApiClient.parseResponse(response);
    if (!result['success']) debugPrint('createCustomer error: ${result['error']} (status: ${result['statusCode']})');
    return result['success'] ? result['data'] as Map<String, dynamic> : null;
  }

  Future<Map<String, dynamic>?> getCustomer(String id) async {
    final response = await ApiClient.get('/ledger/customers/$id');
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] as Map<String, dynamic> : null;
  }

  Future<Map<String, dynamic>?> recordPayment(String customerId, double amount, {String? note}) async {
    final body = {
      'amount': amount,
      if (note != null) 'note': note,
    };
    debugPrint('recordPayment request: $body');
    final response = await ApiClient.post('/ledger/customers/$customerId/pay', body);
    final result = ApiClient.parseResponse(response);
    if (!result['success']) debugPrint('recordPayment error: ${result['error']} (status: ${result['statusCode']}) raw: ${response.body}');
    return result['success'] ? result['data'] as Map<String, dynamic> : null;
  }

  Future<Map<String, dynamic>?> createManualDebit(String customerId, double amount, {String? note}) async {
    final body = {
      'customerId': customerId,
      'amount': amount,
      if (note != null) 'note': note,
    };
    debugPrint('createManualDebit request: $body');
    final response = await ApiClient.post('/ledger/manual-debit', body);
    final result = ApiClient.parseResponse(response);
    if (!result['success']) debugPrint('createManualDebit error: ${result['error']} (status: ${result['statusCode']}) raw: ${response.body}');
    return result['success'] ? result['data'] as Map<String, dynamic> : null;
  }

  Future<Map<String, dynamic>?> getOutstanding() async {
    final response = await ApiClient.get('/ledger/outstanding');
    final result = ApiClient.parseResponse(response);
    if (!result['success']) debugPrint('getOutstanding error: ${result['error']} (status: ${result['statusCode']})');
    return result['success'] ? result['data'] as Map<String, dynamic> : null;
  }
}
