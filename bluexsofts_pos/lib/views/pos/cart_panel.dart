import 'package:flutter/material.dart';
import '../../providers/cart_provider.dart';
import '../../models/product.dart';
import '../shared/summary_row.dart';
import '../../core/theme.dart';

class CartPanel extends StatelessWidget {
  final CartProvider cart;
  final VoidCallback onCheckout;
  const CartPanel({super.key, required this.cart, required this.onCheckout});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text('Cart (${cart.itemCount})', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              if (cart.items.isNotEmpty)
                TextButton(
                  onPressed: cart.clearCart,
                  child: const Text('Clear', style: TextStyle(color: AppTheme.error)),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: cart.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Cart is empty', style: TextStyle(color: Colors.grey)),
                      Text('Tap products to add', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return _CartItemCard(item: item, cart: cart);
                  },
                ),
        ),
        if (cart.items.isNotEmpty) ...[
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SummaryRow(label: 'Subtotal', value: '\$${cart.subtotal.toStringAsFixed(2)}'),
                if (cart.taxAmount > 0)
                  SummaryRow(label: 'Tax (${(cart.taxRate * 100).toStringAsFixed(0)}%)', value: '\$${cart.taxAmount.toStringAsFixed(2)}'),
                if (cart.discount > 0)
                  SummaryRow(label: 'Discount', value: '-\$${cart.discount.toStringAsFixed(2)}', valueColor: AppTheme.warning),
                const Divider(height: 8),
                SummaryRow(
                  label: 'Total',
                  value: '\$${cart.total.toStringAsFixed(2)}',
                  valueStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
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
              ],
            ),
          ),
        ],
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
                  Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    '\$${product.price.toStringAsFixed(2)} ea',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                  onPressed: () => cart.removeProduct(product.id),
                ),
                Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w600)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  onPressed: item.quantity < product.stock ? () => cart.addProduct(product) : null,
                ),
              ],
            ),
            Text(
              '\$${(item.subtotal as double).toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
              onPressed: () => cart.removeItem(product.id),
            ),
          ],
        ),
      ),
    );
  }
}
