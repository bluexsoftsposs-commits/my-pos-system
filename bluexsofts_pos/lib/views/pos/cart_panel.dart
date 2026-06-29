import 'package:flutter/material.dart';
import '../../providers/cart_provider.dart';
import '../../models/product.dart';
import '../shared/summary_row.dart';
import '../../core/theme.dart';
import '../../core/currency_formatter.dart';

class CartPanel extends StatelessWidget {
  final CartProvider cart;
  final VoidCallback onCheckout;
  const CartPanel({super.key, required this.cart, required this.onCheckout});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: cart.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Cart is empty', style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 4),
                      Text('Tap products to add', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        children: [
                          Text('Cart (${cart.itemCount})', style: Theme.of(context).textTheme.titleMedium),
                          const Spacer(),
                          TextButton(
                            onPressed: cart.clearCart,
                            child: const Text('Clear', style: TextStyle(color: AppTheme.error)),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    ...cart.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _CartItemCard(item: item, cart: cart),
                    )),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SummaryRow(label: 'Subtotal', value: CurrencyFormatter.format(cart.subtotal)),
                    ),
                    if (cart.taxAmount > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SummaryRow(label: 'Tax (${(cart.taxRate * 100).toStringAsFixed(0)}%)', value: CurrencyFormatter.format(cart.taxAmount)),
                      ),
                    if (cart.discount > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SummaryRow(label: 'Discount', value: '-${CurrencyFormatter.format(cart.discount)}', valueColor: AppTheme.warning),
                      ),
                    const Divider(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SummaryRow(
                        label: 'Total',
                        value: CurrencyFormatter.format(cart.total),
                        valueStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: onCheckout,
                          icon: const Icon(Icons.shopping_cart_checkout),
                          label: const Text('Proceed to Checkout'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
        ),
      ],
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
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8),
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
