import 'package:flutter/material.dart';
import '../services/audit_service.dart';
import '../core/theme.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  final _auditService = AuditService();
  List<dynamic> _logs = [];
  bool _loading = true;
  int _page = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs({bool loadMore = false}) async {
    if (loadMore && !_hasMore) return;
    setState(() => _loading = !loadMore);
    try {
      final data = await _auditService.getAuditLogs(page: _page);
      if (data != null) {
        final logs = data['logs'] as List<dynamic>? ?? [];
        final total = data['total'] as int? ?? 0;
        if (loadMore) {
          _logs.addAll(logs);
        } else {
          _logs = logs;
        }
        _hasMore = _logs.length < total;
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
              decoration: BoxDecoration(gradient: AppTheme.accentGradient, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.history, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text('Audit Logs'),
          ],
        ),
      ),
      body: _loading && _logs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey[600]),
                      const SizedBox(height: 12),
                      Text('No audit logs yet', style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _logs.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _logs.length) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: ElevatedButton(
                            onPressed: () {
                              _page++;
                              _loadLogs(loadMore: true);
                            },
                            child: const Text('Load More'),
                          ),
                        ),
                      );
                    }
                    final log = _logs[index] as Map<String, dynamic>;
                    final user = log['user'] as Map<String, dynamic>?;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF201F1F),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.06)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFF6C5CE7).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '${user?['name'] ?? '?'}'.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(color: Color(0xFF6C5CE7), fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text('${user?['name'] ?? 'Unknown'}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF6C5CE7).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text('${user?['role'] ?? ''}', style: const TextStyle(fontSize: 9, color: Color(0xFFC6BFFF))),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('${log['action'] ?? ''} — ${log['entityType'] ?? ''}', style: const TextStyle(fontSize: 12, color: Colors.white)),
                                  Text(_formatDate(log['createdAt'] as String? ?? ''), style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
                                ],
                              ),
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
      return dateStr;
    }
  }
}
