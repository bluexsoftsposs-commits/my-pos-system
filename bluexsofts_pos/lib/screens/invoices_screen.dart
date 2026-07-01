import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/invoice_provider.dart';
import '../providers/auth_provider.dart';
import '../models/invoice.dart';
import '../core/theme.dart';
import '../services/receipt_service.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final _searchCtrl = TextEditingController();
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<InvoiceProvider>().loadInvoices());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final from = _dateRange != null
        ? DateFormat('yyyy-MM-dd').format(_dateRange!.start) + 'T00:00:00.000Z'
        : null;
    final to = _dateRange != null
        ? DateFormat('yyyy-MM-dd').format(_dateRange!.end) + 'T23:59:59.999Z'
        : null;
    final search = _searchCtrl.text.isNotEmpty ? _searchCtrl.text.trim() : null;
    await context.read<InvoiceProvider>().loadInvoices(from: from, to: to, search: search);
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final invProv = context.watch<InvoiceProvider>();
    final auth = context.watch<AuthProvider>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search by invoice number...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              _load();
                            },
                          )
                        : null,
                  ),
                  onSubmitted: (_) => _load(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.date_range),
                onPressed: _pickDateRange,
                tooltip: 'Filter by date',
              ),
              if (_dateRange != null)
                IconButton(
                  icon: const Icon(Icons.clear, color: AppTheme.error),
                  onPressed: () {
                    setState(() => _dateRange = null);
                    _load();
                  },
                  tooltip: 'Clear date filter',
                ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _load,
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
        if (_dateRange != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${DateFormat('MMM dd, yyyy').format(_dateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_dateRange!.end)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Text('Invoices', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text('${invProv.invoices.length} records', style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        Expanded(
          child: invProv.isLoading
              ? const Center(child: CircularProgressIndicator())
              : invProv.invoices.isEmpty
                  ? const Center(child: Text('No invoices found'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: invProv.invoices.length,
                      itemBuilder: (context, index) {
                        final inv = invProv.invoices[index];
                        return _buildInvoiceCard(inv, auth.shop?.shopName);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildInvoiceCard(Invoice inv, String? shopName) {
    final dateStr = DateFormat('MMM dd, yyyy HH:mm').format(inv.createdAt);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showInvoiceDetail(inv, shopName),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primary.withOpacity(0.2),
                child: const Icon(Icons.receipt, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inv.invoiceNumber,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '\$${inv.total.toStringAsFixed(2)} | $dateStr',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (inv.user != null)
                      Text(
                        'By: ${inv.user!['name'] ?? 'Unknown'}',
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

  void _showInvoiceDetail(Invoice inv, String? shopName) {
    final dateStr = DateFormat('MMM dd, yyyy HH:mm').format(inv.createdAt);
    final sale = inv.sale;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              controller: scrollController,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(inv.invoiceNumber, style: Theme.of(context).textTheme.titleLarge),
                    ),
                    Row(
                      children: [
                        if (sale != null)
                          IconButton(
                            icon: const Icon(Icons.print),
                            onPressed: () => ReceiptService.printReceipt(sale, shopName: shopName),
                            tooltip: 'Print invoice',
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
                    const Text('Invoice #', style: TextStyle(color: Colors.grey)),
                    Text(inv.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Date', style: TextStyle(color: Colors.grey)),
                    Text(dateStr),
                  ],
                ),
                const SizedBox(height: 4),
                if (inv.user != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Cashier', style: TextStyle(color: Colors.grey)),
                      Text('${inv.user!['name'] ?? 'Unknown'}'),
                    ],
                  ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Payment', style: TextStyle(color: Colors.grey)),
                    Text(inv.paymentMethod),
                  ],
                ),
                if (shopName != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Shop', style: TextStyle(color: Colors.grey)),
                      Text(shopName),
                    ],
                  ),
                ],
                const Divider(),
                if (sale != null && sale.saleItems.isNotEmpty) ...[
                  Text('Items', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: const [
                      Expanded(flex: 3, child: Text('Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      Expanded(flex: 1, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                      Expanded(flex: 1, child: Text('Price', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right)),
                      Expanded(flex: 1, child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right)),
                    ],
                  ),
                  const Divider(height: 4),
                  ...sale.saleItems.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: Text(item.product?['name'] ?? 'Product', style: const TextStyle(fontSize: 13))),
                        Expanded(flex: 1, child: Text('${item.quantity}', textAlign: TextAlign.center)),
                        Expanded(flex: 1, child: Text('\$${item.price.toStringAsFixed(2)}', textAlign: TextAlign.right)),
                        Expanded(flex: 1, child: Text('\$${(item.price * item.quantity).toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600))),
                      ],
                    ),
                  )),
                  const Divider(),
                ],
                _buildTotalRow('Subtotal', '\$${inv.subtotal.toStringAsFixed(2)}'),
                if (inv.tax > 0) _buildTotalRow('Tax', '\$${inv.tax.toStringAsFixed(2)}'),
                if (inv.discount > 0) _buildTotalRow('Discount', '-\$${inv.discount.toStringAsFixed(2)}', AppTheme.warning),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('\$${inv.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.success)),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: TextStyle(color: valueColor)),
        ],
      ),
    );
  }
}
