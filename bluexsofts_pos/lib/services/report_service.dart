import '../core/api_client.dart';

class ReportService {
  Future<Map<String, dynamic>?> getSalesReport({
    String? period,
    String? startDate,
    String? endDate,
  }) async {
    final params = <String, String>{};
    if (period != null) params['period'] = period;
    if (startDate != null) params['startDate'] = startDate;
    if (endDate != null) params['endDate'] = endDate;
    final query = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    final response = await ApiClient.get('/reports/sales${query.isEmpty ? '' : '?$query'}');
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] as Map<String, dynamic> : null;
  }
}
