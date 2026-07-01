import '../core/api_client.dart';

class InvoiceService {
  Future<List<dynamic>?> getInvoices({String? from, String? to, String? search}) async {
    String path = '/invoices?';
    if (from != null) path += 'from=$from&';
    if (to != null) path += 'to=$to&';
    if (search != null) path += 'search=$search&';
    final response = await ApiClient.get(path);
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] as List<dynamic> : null;
  }

  Future<Map<String, dynamic>?> getInvoice(String id) async {
    final response = await ApiClient.get('/invoices/$id');
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] : null;
  }
}
