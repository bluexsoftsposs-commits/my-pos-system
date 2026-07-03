import 'package:flutter/material.dart';
import '../../providers/cart_provider.dart';
import '../../models/product.dart';
import '../../core/theme.dart';
import '../../core/currency_formatter.dart';

class CartPanel extends StatelessWidget {
  final CartProvider cart;
  final VoidCallback onCheckout;
  const CartPanel({super.key, required this.cart, required this.onCheckout});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        border: Border(left: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          _buildCustomerRow(context),
          Expanded(
            child: cart.isEmpty
                ? _buildEmptyState(context)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    children: [
                      ...cart.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _CartItemRow(item: item, cart: cart),
                      )),
                    ],
                  ),
          ),
          _buildSummaryFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Current Sale',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          TextButton(
            onPressed: cart.clearCart,
            child: Text('Clear All',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Row(
        children: [
          Icon(Icons.person, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(cart.customerName,
              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _showCustomerDialog(context),
            child: Icon(Icons.edit, size: 16, color: AppTheme.primary),
          ),
        ],
      ),
    );
  }

  void _showCustomerDialog(BuildContext context) {
    final controller = TextEditingController(text: cart.customerName == 'Walking Customer' ? '' : cart.customerName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Customer Details', style: TextStyle(color: Colors.white, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Customer Name',
                labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                hintText: 'Enter customer name',
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                prefixIcon: Icon(Icons.person, color: Theme.of(context).colorScheme.onSurfaceVariant),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone (optional)',
                labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                hintText: 'Enter phone number',
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                prefixIcon: Icon(Icons.phone, color: Theme.of(context).colorScheme.onSurfaceVariant),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.primary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              cart.setCustomerName(controller.text.trim());
              Navigator.of(ctx).pop();
            },
            child: const Text('Save', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_basket_outlined, size: 48, color: Colors.grey.withOpacity(0.4)),
          const SizedBox(height: 12),
          const Text('Cart is empty',
            style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text('Tap products to add',
            style: TextStyle(fontSize: 13, color: Colors.grey.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _summaryRow('Subtotal', CurrencyFormatter.format(cart.subtotal)),
          const SizedBox(height: 4),
          if (cart.taxAmount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _summaryRow('Tax (${(cart.taxRate * 100).toStringAsFixed(0)}%)', CurrencyFormatter.format(cart.taxAmount)),
            ),
          if (cart.discount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Discount', style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onTertiary)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('-${CurrencyFormatter.format(cart.discount)}',
                        style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onTertiary),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.edit, size: 14, color: AppTheme.primary),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Container(height: 1, color: AppTheme.darkBorder.withOpacity(0.3)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Total Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              Text(CurrencyFormatter.format(cart.total),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: cart.isEmpty ? null : onCheckout,
              icon: const Icon(Icons.payments, size: 22),
              label: const Text('Proceed to Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.primary.withOpacity(0.3),
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 8,
                shadowColor: AppTheme.primary.withOpacity(0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }
}

class _CartItemRow extends StatelessWidget {
  final dynamic item;
  final CartProvider cart;
  const _CartItemRow({required this.item, required this.cart});

  @override
  Widget build(BuildContext context) {
    final product = item.product as Product;
    final lineTotal = item.subtotal;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(8),
          ),
          child: product.imageUrl != null && product.imageUrl!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(product.imageUrl!, fit: BoxFit.cover),
                )
              : Icon(Icons.inventory_2, size: 24, color: Colors.grey.withOpacity(0.4)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(product.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(CurrencyFormatter.format(lineTotal),
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text('Unit: ${CurrencyFormatter.format(product.price)}',
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () => cart.removeProduct(product.id),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            child: Icon(Icons.remove, size: 16, color: Colors.grey),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text('${item.quantity}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: item.quantity < product.stock ? () => cart.addProduct(product) : null,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            child: Icon(
                              Icons.add, size: 16,
                              color: item.quantity < product.stock ? Colors.grey : Colors.grey.withOpacity(0.3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => cart.removeItem(product.id),
                    child: Icon(Icons.delete, size: 18, color: Colors.grey.withOpacity(0.6)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
