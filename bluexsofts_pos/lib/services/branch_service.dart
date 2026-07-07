import '../core/api_client.dart';

class BranchService {
  Future<List<dynamic>?> getBranches() async {
    final response = await ApiClient.get('/branches');
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] as List<dynamic> : null;
  }

  Future<Map<String, dynamic>?> createBranch(Map<String, dynamic> data) async {
    final response = await ApiClient.post('/branches', data);
    final result = ApiClient.parseResponse(response);
    if (result['success']) return result['data'];
    throw Exception(result['error'] ?? 'Failed to create branch');
  }

  Future<bool> deleteBranch(String id) async {
    final response = await ApiClient.delete('/branches/$id');
    return ApiClient.parseResponse(response)['success'] == true;
  }

  Future<Map<String, dynamic>?> getBranchReport(String branchId) async {
    final response = await ApiClient.get('/branches/$branchId/report');
    final result = ApiClient.parseResponse(response);
    return result['success'] ? result['data'] as Map<String, dynamic> : null;
  }
}
