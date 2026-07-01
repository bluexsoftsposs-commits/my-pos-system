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
              Expanded(child: SummaryStat(
                label: 'Total Sales',
                value: '\$${_formatTotal(saleProv.summary?['allTime']?['total'])}',
                gradient: AppTheme.cardGradientPurple,
              )),
              const SizedBox(width: 12),
              Expanded(child: SummaryStat(
                label: 'Transactions',
                value: '${saleProv.summary?['allTime']?['count'] ?? 0}',
                gradient: AppTheme.cardGradientGreen,
              )),
              const SizedBox(width: 12),
              Expanded(child: SummaryStat(
                label: 'Today',
                value: '\$${_formatTotal(saleProv.summary?['today']?['total'])}',
                gradient: AppTheme.cardGradientBlue,
              )),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.darkBorder),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text('Sale History', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    saleProv.loadSales();
                    saleProv.loadSummary();
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: saleProv.isLoading
              ? const Center(child: CircularProgressIndicator())
              : saleProv.sales.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[600]),
                          const SizedBox(height: 12),
                          const Text('No sales yet', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
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

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.darkBorder.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 3)),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showSaleDetails(sale),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppTheme.cardGradientBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(paymentIcon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
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
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.receipt_long, size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          '${sale.saleItems.length} items | $dateStr',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                    if (sale.user != null)
                      Text(
                        'By: ${sale.user?['name'] ?? 'Unknown'}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[600], size: 20),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppTheme.cardGradientGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.receipt_long, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sale Details', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          Text(dateStr, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.print, color: AppTheme.primary),
                            onPressed: () => ReceiptService.printReceipt(sale, shopName: shopName),
                            tooltip: 'Print receipt',
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.info.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.share, color: AppTheme.info),
                            onPressed: () => ReceiptService.shareReceipt(sale, shopName: shopName),
                            tooltip: 'Share receipt',
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.darkBorder.withOpacity(0.5)),
                  ),
                  child: Column(
                    children: [
                      _detailRow('Date', dateStr),
                      const SizedBox(height: 8),
                      _detailRow('Payment', sale.paymentMethod),
                      if (sale.notes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _detailRow('Notes', sale.notes),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text('Items', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.darkBorder.withOpacity(0.5)),
                  ),
                  child: Column(
                    children: sale.saleItems.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(item.product?['name'] ?? 'Product', style: const TextStyle(fontSize: 14)),
                          ),
                          Text('x${item.quantity}', style: TextStyle(color: Colors.grey[500])),
                          const SizedBox(width: 16),
                          Text(
                            '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    )).toList(),
                  ),
                ),
                const Divider(color: AppTheme.darkBorder),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.darkBorder.withOpacity(0.5)),
                  ),
                  child: Column(
                    children: [
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
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      ],
    );
  }
}
