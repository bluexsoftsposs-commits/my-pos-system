import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/sale_provider.dart';
import '../providers/auth_provider.dart';
import '../models/sale.dart';
import '../core/theme.dart';
import '../views/shared/summary_stat.dart';
import '../views/shared/payment_badge.dart';
import '../views/shared/detail_row.dart';
import '../services/receipt_service.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<SaleProvider>().loadSales();
      context.read<SaleProvider>().loadSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final saleProv = context.watch<SaleProvider>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: SummaryStat(label: 'Total Sales', value: '\$${_formatTotal(saleProv.summary?['allTime']?['total'])}')),
              const SizedBox(width: 12),
              Expanded(child: SummaryStat(label: 'Transactions', value: '${saleProv.summary?['allTime']?['count'] ?? 0}')),
              const SizedBox(width: 12),
              Expanded(child: SummaryStat(label: 'Today', value: '\$${_formatTotal(saleProv.summary?['today']?['total'])}')),
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Text('Sale History', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  saleProv.loadSales();
                  saleProv.loadSummary();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: saleProv.isLoading
              ? const Center(child: CircularProgressIndicator())
              : saleProv.sales.isEmpty
                  ? const Center(child: Text('No sales yet'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: saleProv.sales.length,
                      itemBuilder: (context, index) {
                        final sale = saleProv.sales[index];
                        return _buildSaleCard(sale);
                      },
                    ),
        ),
      ],
    );
  }

  String _formatTotal(dynamic value) {
    if (value == null) return '0.00';
    return (value as num).toStringAsFixed(2);
  }

  Widget _buildSaleCard(Sale sale) {
    final dateStr = DateFormat('MMM dd, yyyy HH:mm').format(sale.createdAt);
    final paymentIcon = switch (sale.paymentMethod) {
      'CARD' => Icons.credit_card,
      'MOBILE' => Icons.phone_android,
      _ => Icons.money,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showSaleDetails(sale),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primary.withOpacity(0.2),
                child: Icon(paymentIcon, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '\$${sale.total.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        PaymentBadge(method: sale.paymentMethod),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${sale.saleItems.length} items | $dateStr',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (sale.user != null)
                      Text(
                        'By: ${sale.user!['name'] ?? 'Unknown'}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _showSaleDetails(Sale sale) {
    final dateStr = DateFormat('MMM dd, yyyy HH:mm').format(sale.createdAt);
    final auth = context.read<AuthProvider>();
    final shopName = auth.shop?.shopName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              controller: scrollController,
              children: [
                Row(
                  children: [
                    Text('Sale Details', style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.print),
                          onPressed: () => ReceiptService.printReceipt(sale, shopName: shopName),
                          tooltip: 'Print receipt',
                        ),
                        IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: () => ReceiptService.shareReceipt(sale, shopName: shopName),
                          tooltip: 'Share receipt',
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Date', style: const TextStyle(color: Colors.grey)),
                    Text(dateStr),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Payment', style: const TextStyle(color: Colors.grey)),
                    PaymentBadge(method: sale.paymentMethod),
                  ],
                ),
                if (sale.notes.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Notes', style: const TextStyle(color: Colors.grey)),
                      Flexible(child: Text(sale.notes, textAlign: TextAlign.right)),
                    ],
                  ),
                ],
                const Divider(),
                Text('Items', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...sale.saleItems.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(item.product?['name'] ?? 'Product', style: const TextStyle(fontSize: 14)),
                      ),
                      Text('x${item.quantity}', style: const TextStyle(color: Colors.grey)),
                      const SizedBox(width: 16),
                      Text(
                        '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )),
                const Divider(),
                if (sale.tax > 0)
                  DetailRow(label: 'Tax', value: '\$${sale.tax.toStringAsFixed(2)}'),
                if (sale.discount > 0)
                  DetailRow(label: 'Discount', value: '-\$${sale.discount.toStringAsFixed(2)}', valueColor: AppTheme.warning),
                DetailRow(
                  label: 'Total',
                  value: '\$${sale.total.toStringAsFixed(2)}',
                  isBold: true,
                  valueColor: AppTheme.success,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
