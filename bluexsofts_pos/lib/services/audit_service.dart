import '../core/api_client.dart';

class AuditService {
  Future<Map<String, dynamic>?> getAuditLogs({int page = 1, String? action, String? entityType}) async {
    String url = '/audit/logs?page=$page&limit=50';
    if (action != null) url += '&action=$action';
    if (entityType != null) url += '&entityType=$entityType';
    final response = await ApiClient.get(url);
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] : null;
  }

  Future<Map<String, dynamic>?> getPendingApprovals({int page = 1}) async {
    final response = await ApiClient.get('/audit/pending-approvals?page=$page');
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] : null;
  }

  Future<bool> reviewApproval(String id, String status, {String? note}) async {
    final response = await ApiClient.put('/audit/pending-approvals/$id', {
      'status': status,
      if (note != null) 'reviewNote': note,
    });
    return ApiClient.parseResponse(response)['success'] == true;
  }
}
