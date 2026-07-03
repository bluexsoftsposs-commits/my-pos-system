import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/api_client.dart';

class SaleService {
  Future<List<dynamic>?> getSales() async {
    final response = await ApiClient.get('/sales');
    final result = ApiClient.parseResponse(response);
    if (!result['success']) debugPrint('getSales error: ${result['error']}');
    return result['success'] ? result['data'] as List<dynamic> : null;
  }

  Future<Map<String, dynamic>?> getSummary({String? from, String? to}) async {
    var path = '/sales/summary';
    if (from != null || to != null) {
      final params = <String, String>{};
      if (from != null) params['from'] = from;
      if (to != null) params['to'] = to;
      path += '?${Uri(queryParameters: params).query}';
    }
    final response = await ApiClient.get(path);
    final result = ApiClient.parseResponse(response);
    if (!result['success']) debugPrint('getSummary error: ${result['error']}');
    return result['success'] ? result['data'] : null;
  }

  Future<Map<String, dynamic>?> createSale(Map<String, dynamic> payload) async {
    debugPrint('createSale request: ${jsonEncode(payload)}');
    final response = await ApiClient.post('/sales', payload);
    final result = ApiClient.parseResponse(response);
    if (!result['success']) {
      debugPrint('createSale error (${result['statusCode']}): ${result['error']} raw: ${response.body}');
    }
    return result['success'] ? result['data'] : null;
  }
}
