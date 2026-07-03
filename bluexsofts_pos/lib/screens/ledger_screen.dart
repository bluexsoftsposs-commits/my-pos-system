import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ledger_provider.dart';
import '../models/customer.dart';
import '../core/theme.dart';
import '../core/currency_formatter.dart';
import 'customer_detail_screen.dart';

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LedgerProvider>().loadCustomers();
    });
  }

  Future<void> _showAddManualDebitDialog() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Manual Ledger Entry'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Customer Name'), autofocus: true),
              const SizedBox(height: 8),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone (optional)'), keyboardType: TextInputType.phone),
              const SizedBox(height: 8),
              TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'Amount (Rs)'), keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Note (optional)'), maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Add')),
        ],
      ),
    );

    if (result == true && mounted) {
      final name = nameCtrl.text.trim();
      final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
      if (name.isEmpty || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name and valid amount required'), backgroundColor: AppTheme.error),
        );
        return;
      }
      final prov = context.read<LedgerProvider>();
      final customer = await prov.findOrCreateCustomer(name, phone: phoneCtrl.text.trim());
      if (customer != null) {
        if (customer.id.isNotEmpty) {
          await prov.createManualDebit(customer.id, amount, note: noteCtrl.text.trim());
        }
        await prov.loadCustomers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ledger entry added'), backgroundColor: AppTheme.success),
          );
        }
      }
    }
    nameCtrl.dispose();
    phoneCtrl.dispose();
    amountCtrl.dispose();
    noteCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<LedgerProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ledger / Udhaar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Manual Entry',
            onPressed: _showAddManualDebitDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              prov.loadCustomers();
              prov.loadOutstanding();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primary.withOpacity(0.15), AppTheme.darkCard],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Outstanding', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.format(prov.totalOutstanding),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.warning),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.darkBorder),
          Expanded(
            child: prov.isLoading
                ? const Center(child: CircularProgressIndicator())
                : prov.customers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.account_balance, size: 64, color: Colors.grey[600]),
                            const SizedBox(height: 12),
                            const Text('No customers yet', style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 8),
                            const Text('Credit sales will appear here', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await prov.loadCustomers();
                          await prov.loadOutstanding();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: prov.customers.length,
                          itemBuilder: (context, index) {
                            final customer = prov.customers[index];
                            return _CustomerCard(customer: customer);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Customer customer;
  const _CustomerCard({required this.customer});

  @override
  Widget build(BuildContext context) {
    final balance = customer.balance;
    final hasBalance = balance > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.darkBorder.withOpacity(0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CustomerDetailScreen(customerId: customer.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: hasBalance ? AppTheme.cardGradientPurple : AppTheme.cardGradientGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.person, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    if (customer.phone.isNotEmpty)
                      Text(customer.phone, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    if (customer.lastPaymentAt != null)
                      Text(
                        'Last payment: ${_formatDate(customer.lastPaymentAt!)}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    hasBalance ? CurrencyFormatter.format(balance) : 'Cleared',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: hasBalance ? AppTheme.warning : AppTheme.success,
                    ),
                  ),
                  if (hasBalance) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Owed: ${CurrencyFormatter.format(customer.totalOwed)}',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: Colors.grey[600], size: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
