import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ledger_provider.dart';
import '../core/theme.dart';
import '../core/currency_formatter.dart';

class CustomerDetailScreen extends StatefulWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LedgerProvider>().loadCustomerDetail(widget.customerId);
    });
  }

  Future<void> _showPaymentDialog() async {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Record Payment'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountCtrl,
                decoration: const InputDecoration(labelText: 'Amount (Rs)'),
                keyboardType: TextInputType.number,
                autofocus: true,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            child: const Text('Pay'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
      if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Valid amount required'), backgroundColor: AppTheme.error),
        );
        return;
      }
      final prov = context.read<LedgerProvider>();
      final success = await prov.recordPayment(widget.customerId, amount, note: noteCtrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Payment recorded' : 'Failed to record payment'),
            backgroundColor: success ? AppTheme.success : AppTheme.error,
          ),
        );
      }
    }
    amountCtrl.dispose();
    noteCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<LedgerProvider>();
    final customer = prov.selectedCustomer;
    final entries = prov.entries;

    return Scaffold(
      appBar: AppBar(
        title: Text(customer?.name ?? 'Customer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.payments, color: AppTheme.success),
            tooltip: 'Record Payment',
            onPressed: _showPaymentDialog,
          ),
        ],
      ),
      body: prov.isLoading
          ? const Center(child: CircularProgressIndicator())
          : customer == null
              ? const Center(child: Text('Customer not found'))
              : RefreshIndicator(
                  onRefresh: () => prov.loadCustomerDetail(widget.customerId),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.darkCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.darkBorder.withOpacity(0.5)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.person, color: Colors.grey[500]),
                                const SizedBox(width: 8),
                                Text(customer.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            if (customer.phone.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.phone, color: Colors.grey[500], size: 16),
                                  const SizedBox(width: 8),
                                  Text(customer.phone, style: TextStyle(color: Colors.grey[400])),
                                ],
                              ),
                            ],
                            const Divider(color: AppTheme.darkBorder, height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text('Total Owed', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                                      const SizedBox(height: 4),
                                      Text(CurrencyFormatter.format(customer.totalOwed), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.warning)),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text('Total Paid', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                                      const SizedBox(height: 4),
                                      Text(CurrencyFormatter.format(customer.totalPaid), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.success)),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text('Balance', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                                      const SizedBox(height: 4),
                                      Text(
                                        CurrencyFormatter.format(customer.balance),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: customer.balance > 0 ? AppTheme.warning : AppTheme.success,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(gradient: AppTheme.accentGradient, borderRadius: BorderRadius.circular(2)),
                          ),
                          const SizedBox(width: 10),
                          Text('History', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Text('${entries.length} entries', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (entries.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          alignment: Alignment.center,
                          child: Text('No entries yet', style: TextStyle(color: Colors.grey[500])),
                        )
                      else
                        ...entries.map((entry) => Container(
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
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: entry.isDebit ? AppTheme.warning.withOpacity(0.15) : AppTheme.success.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  entry.isDebit ? Icons.arrow_upward : Icons.arrow_downward,
                                  color: entry.isDebit ? AppTheme.warning : AppTheme.success,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.isDebit ? 'Charge' : 'Payment',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                    ),
                                    if (entry.note.isNotEmpty)
                                      Text(entry.note, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                                    Text(
                                      _formatDate(entry.createdAt),
                                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${entry.isDebit ? '+' : '-'}${CurrencyFormatter.format(entry.amount)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: entry.isDebit ? AppTheme.warning : AppTheme.success,
                                ),
                              ),
                            ],
                          ),
                        )),
                    ],
                  ),
                ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
