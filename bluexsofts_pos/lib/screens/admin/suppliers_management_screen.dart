import 'package:flutter/material.dart';
import '../../services/supplier_service.dart';
import '../../core/theme.dart';
import '../../core/currency_formatter.dart';
import '../../core/api_client.dart';

class SuppliersManagementScreen extends StatefulWidget {
  const SuppliersManagementScreen({super.key});

  @override
  State<SuppliersManagementScreen> createState() => _SuppliersManagementScreenState();
}

class _SuppliersManagementScreenState extends State<SuppliersManagementScreen> {
  final _service = SupplierService();
  List<dynamic> _suppliers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getStats();
      if (data != null && data['stats'] != null) {
        _suppliers = data['recentTransactions'] as List<dynamic>? ?? [];
      }
      // Also fetch all suppliers via the admin endpoint
      await _fetchAllSuppliers();
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _fetchAllSuppliers() async {
    try {
      final response = await ApiClient.get('/suppliers?limit=50');
      final result = ApiClient.parseResponse(response);
      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>?;
        if (data != null) _suppliers = data['suppliers'] ?? [];
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF00B894), Color(0xFF00CEC9)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text('Suppliers'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _suppliers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person, size: 64, color: Colors.grey[600]),
                      const SizedBox(height: 12),
                      Text('No suppliers registered', style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _suppliers.length,
                  itemBuilder: (context, index) {
                    final s = _suppliers[index] as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF201F1F),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.06)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [Color(0xFF00B894), Color(0xFF00CEC9)]),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${s['supplierName'] ?? '?'}'.substring(0, 1).toUpperCase(),
                                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${s['supplierName'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                      Text('${s['businessName'] ?? ''} - ${s['email'] ?? ''}', style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: s['isVerified'] == true ? const Color(0xFF00B894).withOpacity(0.1) : const Color(0xFFFDCB6E).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        s['isVerified'] == true ? 'Verified' : 'Pending',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: s['isVerified'] == true ? const Color(0xFF00B894) : const Color(0xFFFDCB6E)),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Balance: ${CurrencyFormatter.formatWithDecimals((s['pendingBalance'] as num?) ?? 0)}',
                                      style: TextStyle(fontSize: 11, color: ((s['pendingBalance'] as num?) ?? 0) >= 0 ? const Color(0xFF00B894) : const Color(0xFFD63031)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (s['_count'] != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _chip(Icons.receipt, '${(s['_count'] as Map)['transactions'] ?? 0} txns'),
                                ],
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _toggleVerify(s),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: s['isVerified'] == true ? const Color(0xFFFDCB6E).withOpacity(0.1) : const Color(0xFF00B894).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            s['isVerified'] == true ? Icons.undo : Icons.verified,
                                            size: 14,
                                            color: s['isVerified'] == true ? const Color(0xFFFDCB6E) : const Color(0xFF00B894),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            s['isVerified'] == true ? 'Unverify' : 'Verify',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: s['isVerified'] == true ? const Color(0xFFFDCB6E) : const Color(0xFF00B894)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _toggleStatus(s),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: (s['isActive'] as bool? ?? true) ? const Color(0xFFD63031).withOpacity(0.1) : const Color(0xFF00B894).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            (s['isActive'] as bool? ?? true) ? Icons.block : Icons.check_circle,
                                            size: 14,
                                            color: (s['isActive'] as bool? ?? true) ? const Color(0xFFD63031) : const Color(0xFF00B894),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            (s['isActive'] as bool? ?? true) ? 'Deactivate' : 'Activate',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: (s['isActive'] as bool? ?? true) ? const Color(0xFFD63031) : const Color(0xFF00B894)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF6C5CE7).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF6C5CE7)),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFFC6BFFF))),
        ],
      ),
    );
  }

  Future<void> _toggleVerify(Map<String, dynamic> supplier) async {
    try {
      final id = supplier['id'] as String;
      final response = await ApiClient.put('/suppliers/$id/verify', {});
      final result = ApiClient.parseResponse(response);
      if (result['success'] == true) {
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['data']?['message'] ?? 'Updated'),
            backgroundColor: const Color(0xFF00B894),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _toggleStatus(Map<String, dynamic> supplier) async {
    try {
      final id = supplier['id'] as String;
      final response = await ApiClient.put('/suppliers/$id/toggle-status', {});
      final result = ApiClient.parseResponse(response);
      if (result['success'] == true) {
        _loadData();
      }
    } catch (_) {}
  }
}
