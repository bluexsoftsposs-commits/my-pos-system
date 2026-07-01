import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/sale_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/sale.dart';
import '../shared/summary_row.dart';
import '../../core/theme.dart';
import '../../core/currency_formatter.dart';
import '../../services/receipt_service.dart';

class CheckoutPanel extends StatefulWidget {
  final CartProvider cart;
  final SaleProvider saleProv;
  final VoidCallback onBack;
  const CheckoutPanel({super.key, required this.cart, required this.saleProv, required this.onBack});

  @override
  State<CheckoutPanel> createState() => _CheckoutPanelState();
}

class _CheckoutPanelState extends State<CheckoutPanel> {
  late TextEditingController _discountCtrl;
  late TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    _discountCtrl = TextEditingController(text: widget.cart.discount.toString());
    _notesCtrl = TextEditingController(text: widget.cart.notes);
  }

  @override
  void dispose() {
    _discountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _completeSale() async {
    final cart = widget.cart;
    final saleProv = widget.saleProv;
    final payload = cart.toCheckoutPayload();
    final sale = await saleProv.createSale(payload);
    if (!mounted) return;
    if (sale != null) {
      for (final item in cart.items) {
        context.read<ProductProvider>().decrementStock(item.product.id, item.quantity);
      }
      cart.clearCart();
      widget.onBack();
      final invoiceNum = sale.invoice?['invoiceNumber'] ?? '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  invoiceNum.isNotEmpty
                      ? 'Sale completed! Invoice: $invoiceNum - Total: ${CurrencyFormatter.format(sale.total)}'
                      : 'Sale completed! Total: ${CurrencyFormatter.format(sale.total)}',
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      // Auto-show print dialog
      final auth = context.read<AuthProvider>();
      _showPrintDialog(sale, auth.shop?.shopName);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Sale saved offline. Will sync when online.')),
            ],
          ),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _showPrintDialog(Sale sale, String? shopName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AppTheme.successGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.check_circle, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Sale Completed!', style: TextStyle(fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Total: ${CurrencyFormatter.format(sale.total)}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.success),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    ReceiptService.printReceipt(sale, shopName: shopName);
                  },
                  icon: const Icon(Icons.print),
                  label: const Text('Print Receipt'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    ReceiptService.shareReceipt(sale, shopName: shopName);
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.darkCard,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Skip', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = widget.cart;
    final saleProv = widget.saleProv;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
              Text('Checkout', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: widget.onBack,
                ),
              ),
            ],
          ),
        ),
        const Divider(color: AppTheme.darkBorder),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                    SummaryRow(label: 'Items', value: '${cart.itemCount}'),
                    const SizedBox(height: 4),
                    SummaryRow(label: 'Subtotal', value: CurrencyFormatter.format(cart.subtotal)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Discount', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Discount Amount',
                  prefixIcon: Icon(Icons.discount),
                ),
                keyboardType: TextInputType.number,
                controller: _discountCtrl,
                onChanged: (v) => cart.setDiscount(double.tryParse(v) ?? 0),
              ),
              const SizedBox(height: 16),
              Text('Tax Rate', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['0%', '5%', '10%', '15%'].map((rate) {
                  final val = double.parse(rate.replaceAll('%', '')) / 100;
                  final selected = cart.taxRate == val;
                  return ChoiceChip(
                    label: Text(rate),
                    selected: selected,
                    selectedColor: AppTheme.accent,
                    backgroundColor: AppTheme.darkCard,
                    onSelected: (_) => cart.setTaxRate(val),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text('Payment Method', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['CASH', 'CARD', 'MOBILE'].map((method) {
                  final selected = cart.paymentMethod == method;
                  return ChoiceChip(
                    label: Text(method),
                    selected: selected,
                    selectedColor: AppTheme.accent,
                    backgroundColor: AppTheme.darkCard,
                    onSelected: (_) => cart.setPaymentMethod(method),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  prefixIcon: Icon(Icons.notes),
                ),
                controller: _notesCtrl,
                maxLines: 2,
                onChanged: cart.setNotes,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.darkBorder.withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    if (cart.taxAmount > 0)
                      SummaryRow(label: 'Tax (${(cart.taxRate * 100).toStringAsFixed(0)}%)', value: CurrencyFormatter.format(cart.taxAmount)),
                    if (cart.discount > 0)
                      SummaryRow(label: 'Discount', value: '-${CurrencyFormatter.format(cart.discount)}', valueColor: AppTheme.warning),
                    const Divider(color: AppTheme.darkBorder),
                    SummaryRow(
                      label: 'Total',
                      value: CurrencyFormatter.format(cart.total),
                      valueStyle: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.success),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: saleProv.isLoading ? null : _completeSale,
                  icon: saleProv.isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle, size: 22),
                  label: Text(
                    saleProv.isLoading
                        ? 'Processing...'
                        : 'Complete Sale - ${CurrencyFormatter.format(cart.total)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: 4,
                    shadowColor: AppTheme.success.withOpacity(0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
