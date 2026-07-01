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
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppTheme.primary,
            surface: AppTheme.darkSurface,
          ),
        ),
        child: child!,
      ),
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
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(Icons.date_range, color: AppTheme.primary),
                  onPressed: _pickDateRange,
                  tooltip: 'Filter by date',
                ),
              ),
              if (_dateRange != null)
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.clear, color: AppTheme.error, size: 20),
                    onPressed: () {
                      setState(() => _dateRange = null);
                      _load();
                    },
                    tooltip: 'Clear date filter',
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _load,
                  tooltip: 'Refresh',
                ),
              ),
            ],
          ),
        ),
        if (_dateRange != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: AppTheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    '${DateFormat('MMM dd, yyyy').format(_dateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_dateRange!.end)}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.primary),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text('Invoices', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(
                '${invProv.invoices.length} records',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ],
          ),
        ),
        Expanded(
          child: invProv.isLoading
              ? const Center(child: CircularProgressIndicator())
              : invProv.invoices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_outlined, size: 64, color: Colors.grey[600]),
                          const SizedBox(height: 12),
                          const Text('No invoices found', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
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
        onTap: () => _showInvoiceDetail(inv, shopName),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt, color: AppTheme.accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          inv.invoiceNumber,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusBadge(),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(dateStr, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                        const SizedBox(width: 12),
                        Text(
                          '\$${inv.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.success,
                          ),
                        ),
                      ],
                    ),
                    if (inv.user != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'By: ${inv.user!['name'] ?? 'Unknown'}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
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

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.success.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.success.withOpacity(0.3)),
      ),
      child: const Text(
        'Paid',
        style: TextStyle(fontSize: 10, color: AppTheme.success, fontWeight: FontWeight.w500),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppTheme.accentGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.receipt, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(inv.invoiceNumber, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          Text('Invoice Details', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        if (sale != null)
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.print, color: AppTheme.primary),
                              onPressed: () => ReceiptService.printReceipt(sale, shopName: shopName),
                              tooltip: 'Print invoice',
                            ),
                          ),
                        const SizedBox(width: 4),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
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
                      _detailRow('Invoice #', inv.invoiceNumber),
                      const SizedBox(height: 8),
                      _detailRow('Date', dateStr),
                      if (inv.user != null) ...[
                        const SizedBox(height: 8),
                        _detailRow('Cashier', '${inv.user!['name'] ?? 'Unknown'}'),
                      ],
                      const SizedBox(height: 8),
                      _detailRow('Payment', inv.paymentMethod),
                      if (shopName != null) ...[
                        const SizedBox(height: 8),
                        _detailRow('Shop', shopName),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (sale != null && sale.saleItems.isNotEmpty) ...[
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
                      children: [
                        Row(
                          children: const [
                            Expanded(flex: 3, child: Text('Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
                            Expanded(flex: 1, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey), textAlign: TextAlign.center)),
                            Expanded(flex: 1, child: Text('Price', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey), textAlign: TextAlign.right)),
                            Expanded(flex: 1, child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey), textAlign: TextAlign.right)),
                          ],
                        ),
                        const Divider(color: AppTheme.darkBorder, height: 16),
                        ...sale.saleItems.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(flex: 3, child: Text(item.product?['name'] ?? 'Product', style: const TextStyle(fontSize: 13))),
                              Expanded(flex: 1, child: Text('${item.quantity}', textAlign: TextAlign.center)),
                              Expanded(flex: 1, child: Text('\$${item.price.toStringAsFixed(2)}', textAlign: TextAlign.right)),
                              Expanded(flex: 1, child: Text(
                                '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              )),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.darkBorder.withOpacity(0.5)),
                  ),
                  child: Column(
                    children: [
                      _totalRow('Subtotal', '\$${inv.subtotal.toStringAsFixed(2)}'),
                      if (inv.tax > 0) _totalRow('Tax', '\$${inv.tax.toStringAsFixed(2)}'),
                      if (inv.discount > 0) _totalRow('Discount', '-\$${inv.discount.toStringAsFixed(2)}'),
                      const Divider(color: AppTheme.darkBorder),
                      _totalRow('TOTAL', '\$${inv.total.toStringAsFixed(2)}', isBold: true),
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

  Widget _totalRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? Colors.white : Colors.grey[400],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: FontWeight.bold,
              color: isBold ? AppTheme.success : null,
            ),
          ),
        ],
      ),
    );
  }
}
