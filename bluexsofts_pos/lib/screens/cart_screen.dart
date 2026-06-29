import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/sale_provider.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';
import '../views/shared/summary_row.dart';
import '../core/theme.dart';
import '../core/currency_formatter.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late TextEditingController _discountCtrl;
  late TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    final cart = context.read<CartProvider>();
    _discountCtrl = TextEditingController(text: cart.discount.toString());
    _notesCtrl = TextEditingController(text: cart.notes);
  }

  @override
  void dispose() {
    _discountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _completeSale() async {
    final cart = context.read<CartProvider>();
    final saleProv = context.read<SaleProvider>();
    final payload = cart.toCheckoutPayload();
    final sale = await saleProv.createSale(payload);
    if (!mounted) return;
    if (sale != null) {
      for (final item in cart.items) {
        context.read<ProductProvider>().decrementStock(item.product.id, item.quantity);
      }
      cart.clearCart();
      Navigator.of(context).pop();
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
    final cart = context.watch<CartProvider>();
    final saleProv = context.watch<SaleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Cart (${cart.itemCount})'),
        actions: [
          if (!cart.isEmpty)
            TextButton(
              onPressed: cart.clearCart,
              child: const Text('Clear', style: TextStyle(color: AppTheme.error)),
            ),
        ],
      ),
      body: cart.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Cart is empty', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('Add products from the POS screen', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...cart.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _CartItemCard(item: item, cart: cart),
                )),
                const Divider(),
                const SizedBox(height: 8),
                Text('Order Summary', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                SummaryRow(label: 'Subtotal', value: CurrencyFormatter.format(cart.subtotal)),
                if (cart.taxAmount > 0)
                  SummaryRow(label: 'Tax (${(cart.taxRate * 100).toStringAsFixed(0)}%)', value: CurrencyFormatter.format(cart.taxAmount)),
                if (cart.discount > 0)
                  SummaryRow(label: 'Discount', value: '-${CurrencyFormatter.format(cart.discount)}', valueColor: AppTheme.warning),
                const Divider(),
                SummaryRow(
                  label: 'Total',
                  value: CurrencyFormatter.format(cart.total),
                  valueStyle: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Text('Discount & Tax', style: Theme.of(context).textTheme.titleMedium),
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
                const SizedBox(height: 16),
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
                const SizedBox(height: 24),
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
                const SizedBox(height: 32),
              ],
            ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final dynamic item;
  final CartProvider cart;
  const _CartItemCard({required this.item, required this.cart});

  @override
  Widget build(BuildContext context) {
    final product = item.product as Product;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(
                    '${CurrencyFormatter.format(product.price)} ea',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  onPressed: () => cart.removeProduct(product.id),
                ),
                Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w600)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  onPressed: item.quantity < product.stock ? () => cart.addProduct(product) : null,
                ),
              ],
            ),
            Flexible(
              child: Text(
                CurrencyFormatter.format(item.subtotal as double),
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
              onPressed: () => cart.removeItem(product.id),
            ),
          ],
        ),
      ),
    );
  }
}
