import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/branch_provider.dart';
import '../core/theme.dart';
import '../core/currency_formatter.dart';

class BranchReportScreen extends StatefulWidget {
  const BranchReportScreen({super.key});

  @override
  State<BranchReportScreen> createState() => _BranchReportScreenState();
}

class _BranchReportScreenState extends State<BranchReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BranchProvider>().loadBranches();
    });
  }

  Future<void> _showAddBranchDialog() async {
    final nameCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Branch'),
        content: TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Branch name'), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Add')),
        ],
      ),
    );
    if (result == true && mounted) {
      final name = nameCtrl.text.trim();
      if (name.isNotEmpty) {
        await context.read<BranchProvider>().createBranch(name);
      }
    }
    nameCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BranchProvider>();
    final branches = prov.branches;
    final selected = prov.selectedBranch;

    return Scaffold(
      appBar: AppBar(
        title: Text(selected != null ? 'Branch: ${selected.name}' : 'Branch Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Branch',
            onPressed: _showAddBranchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              prov.loadBranches();
              if (selected != null) prov.loadBranchReport(selected.id);
            },
          ),
        ],
      ),
      body: branches.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.store, size: 64, color: Colors.grey[600]),
                  const SizedBox(height: 12),
                  Text('No branches yet', style: TextStyle(color: Colors.grey[400])),
                  const SizedBox(height: 8),
                  Text('Add branches to track per-location sales', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            )
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard,
                    border: Border(bottom: BorderSide(color: AppTheme.darkBorder.withOpacity(0.3))),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _branchChip(null, 'All Branches', prov),
                        ...branches.map((b) => _branchChip(b, b.name, prov)),
                      ],
                    ),
                  ),
                ),
                Expanded(child: _buildReportContent(prov, selected)),
              ],
            ),
    );
  }

  Widget _branchChip(BranchInfo? branch, String label, BranchProvider prov) {
    final active = (branch == null && prov.selectedBranch == null) ||
        (branch != null && prov.selectedBranch?.id == branch.id);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          prov.selectBranch(branch);
          if (branch != null) prov.loadBranchReport(branch.id);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppTheme.primary : AppTheme.darkBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: active ? AppTheme.primary : AppTheme.darkBorder.withOpacity(0.3)),
          ),
          child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: active ? Colors.white : Colors.grey[400])),
        ),
      ),
    );
  }

  Widget _buildReportContent(BranchProvider prov, BranchInfo? selected) {
    if (selected == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.tap_and_play, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 12),
            Text('Select a branch above to view report', style: TextStyle(color: Colors.grey[400])),
          ],
        ),
      );
    }

    if (prov.isLoading) return const Center(child: CircularProgressIndicator());

    final report = prov.report;
    if (report == null) return const Center(child: CircularProgressIndicator());

    final revenue = (report['totalRevenue'] as num?)?.toDouble() ?? 0;
    final count = (report['transactionCount'] as num?)?.toInt() ?? 0;
    final recentSales = (report['recentSales'] as List?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _statCard('Total Revenue', CurrencyFormatter.format(revenue), AppTheme.primary, Icons.trending_up),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard('Transactions', '$count', AppTheme.info, Icons.receipt_long),
              ),
            ],
          ),
          if (report['branch'] != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.darkBorder.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Branch Details', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey[300])),
                  const SizedBox(height: 8),
                  _detailRow('Name', selected.name),
                  if (selected.address.isNotEmpty) _detailRow('Address', selected.address),
                  if (selected.phone.isNotEmpty) _detailRow('Phone', selected.phone),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Container(width: 4, height: 20, decoration: BoxDecoration(gradient: AppTheme.accentGradient, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Text('Recent Sales', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          if (recentSales.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: Text('No sales yet', style: TextStyle(color: Colors.grey[500])),
            )
          else
            ...recentSales.take(10).map((s) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.darkBorder.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.receipt, color: AppTheme.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sale #${(s['id'] as String).substring(0, 6)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text(s['user'] as String? ?? '', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                        Text(_formatDate(DateTime.parse(s['createdAt'] as String)), style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  Text(CurrencyFormatter.format((s['total'] as num).toDouble()), style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.darkBorder.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(width: 44, height: 44,
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ])),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          Text(value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
