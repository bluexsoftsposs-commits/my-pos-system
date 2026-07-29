import 'package:flutter/material.dart';
import '../services/audit_service.dart';
import '../core/theme.dart';

class PendingApprovalsScreen extends StatefulWidget {
  const PendingApprovalsScreen({super.key});

  @override
  State<PendingApprovalsScreen> createState() => _PendingApprovalsScreenState();
}

class _PendingApprovalsScreenState extends State<PendingApprovalsScreen> {
  final _auditService = AuditService();
  List<dynamic> _approvals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadApprovals();
  }

  Future<void> _loadApprovals() async {
    setState(() => _loading = true);
    try {
      final data = await _auditService.getPendingApprovals();
      if (data != null) _approvals = data['approvals'] ?? [];
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _review(String id, String status) async {
    final success = await _auditService.reviewApproval(id, status);
    if (success) {
      _loadApprovals();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request ${status.toLowerCase()}'),
            backgroundColor: status == 'APPROVED' ? const Color(0xFF00B894) : const Color(0xFFD63031),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(gradient: AppTheme.accentGradient, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.approval, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text('Pending Approvals'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _approvals.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 64, color: Colors.grey[600]),
                      const SizedBox(height: 12),
                      Text('No pending approvals', style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _approvals.length,
                  itemBuilder: (context, index) {
                    final a = _approvals[index] as Map<String, dynamic>;
                    final subAdmin = a['subAdmin'] as Map<String, dynamic>?;
                    final payload = a['payload'] as Map<String, dynamic>?;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF201F1F),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFDCB6E).withOpacity(0.3)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFDCB6E).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text('${a['action'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFFDCB6E))),
                                ),
                                const Spacer(),
                                Text(_formatDate(a['createdAt'] as String? ?? ''), style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (subAdmin != null) ...[
                              Row(
                                children: [
                                  const Icon(Icons.person, size: 14, color: Color(0xFF6C5CE7)),
                                  const SizedBox(width: 6),
                                  Text('${subAdmin['name'] ?? ''} (${subAdmin['email'] ?? ''})', style: const TextStyle(fontSize: 13, color: Color(0xFFC6BFFF))),
                                ],
                              ),
                            ],
                            if (payload != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1A2E).withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: payload.entries.map((e) {
                                    if (e.value == null) return const SizedBox.shrink();
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2),
                                      child: Row(
                                        children: [
                                          Text('${e.key}: ', style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
                                          Expanded(
                                            child: Text('${e.value}', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _review(a['id'] as String, 'APPROVED'),
                                    icon: const Icon(Icons.check, size: 16),
                                    label: const Text('Approve'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF00B894),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _review(a['id'] as String, 'REJECTED'),
                                    icon: const Icon(Icons.close, size: 16),
                                    label: const Text('Reject'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFD63031),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
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

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr.split('T')[0];
    }
  }
}
