import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/sale_provider.dart';
import '../../providers/product_provider.dart';
import '../shared/summary_row.dart';
import '../../core/theme.dart';
import '../../core/currency_formatter.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sale completed! Total: ${CurrencyFormatter.format(sale.total)}'),
          backgroundColor: AppTheme.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sale saved offline. Will sync when online.'),
          backgroundColor: AppTheme.warning,
        ),
      );
    }
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
              Text('Checkout', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              SummaryRow(label: 'Items', value: '${cart.itemCount}'),
              SummaryRow(label: 'Subtotal', value: CurrencyFormatter.format(cart.subtotal)),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Discount (PKR)',
                  prefixIcon: Icon(Icons.discount),
                ),
                keyboardType: TextInputType.number,
                controller: _discountCtrl,
                onChanged: (v) => cart.setDiscount(double.tryParse(v) ?? 0),
              ),
              const SizedBox(height: 12),
              Text('Tax Rate', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: ['0%', '5%', '10%', '15%'].map((rate) {
                  final val = double.parse(rate.replaceAll('%', '')) / 100;
                  final selected = cart.taxRate == val;
                  return ChoiceChip(
                    label: Text(rate),
                    selected: selected,
                    onSelected: (_) => cart.setTaxRate(val),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Text('Payment Method', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: ['CASH', 'CARD', 'MOBILE'].map((method) {
                  final selected = cart.paymentMethod == method;
                  return ChoiceChip(
                    label: Text(method),
                    selected: selected,
                    onSelected: (_) => cart.setPaymentMethod(method),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  prefixIcon: Icon(Icons.notes),
                ),
                controller: _notesCtrl,
                maxLines: 2,
                onChanged: cart.setNotes,
              ),
              const SizedBox(height: 16),
              if (cart.taxAmount > 0)
                SummaryRow(label: 'Tax', value: CurrencyFormatter.format(cart.taxAmount)),
              if (cart.discount > 0)
                SummaryRow(label: 'Discount', value: '-${CurrencyFormatter.format(cart.discount)}', valueColor: AppTheme.warning),
              const Divider(),
              SummaryRow(
                label: 'Total',
                value: CurrencyFormatter.format(cart.total),
                valueStyle: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: saleProv.isLoading ? null : _completeSale,
                  icon: saleProv.isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check_circle),
                  label: Text(saleProv.isLoading ? 'Processing...' : 'Complete Sale - ${CurrencyFormatter.format(cart.total)}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
