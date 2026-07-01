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
              Text('Cart (${cart.itemCount})', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              TextButton.icon(
                onPressed: cart.clearCart,
                icon: const Icon(Icons.delete_sweep, size: 18),
                label: const Text('Clear', style: TextStyle(color: AppTheme.error)),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.darkBorder),
        Expanded(
          child: cart.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(Icons.shopping_cart_outlined, size: 36, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      const Text('Cart is empty', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(
                        'Tap products to add',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.only(bottom: 8),
                  children: [
                    ...cart.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: _CartItemCard(item: item, cart: cart),
                    )),
                    const SizedBox(height: 8),
                    const Divider(height: 1, color: AppTheme.darkBorder),
                    const SizedBox(height: 8),
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
                    const Divider(height: 8, color: AppTheme.darkBorder),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SummaryRow(
                        label: 'Total',
                        value: CurrencyFormatter.format(cart.total),
                        valueStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.success),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: onCheckout,
                          icon: const Icon(Icons.shopping_cart_checkout, size: 20),
                          label: const Text('Proceed to Checkout'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 4,
                            shadowColor: AppTheme.success.withOpacity(0.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.darkBorder.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${CurrencyFormatter.format(product.price)} ea',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.darkSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.darkBorder.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => cart.removeProduct(product.id),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(Icons.remove, size: 16, color: Colors.grey[400]),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: item.quantity < product.stock ? () => cart.addProduct(product) : null,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.add,
                        size: 16,
                        color: item.quantity < product.stock ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              CurrencyFormatter.format(item.subtotal as double),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 4),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => cart.removeItem(product.id),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close, size: 16, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
