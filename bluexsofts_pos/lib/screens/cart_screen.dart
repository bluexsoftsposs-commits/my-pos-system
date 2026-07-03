import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/sale_provider.dart';
import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/ledger_provider.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../views/shared/summary_row.dart';
import '../core/theme.dart';
import '../core/currency_formatter.dart';
import '../services/receipt_service.dart';

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

    if (cart.paymentMethod == 'CREDIT') {
      if (cart.creditCustomerName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer name required for credit sale'), backgroundColor: AppTheme.error),
        );
        return;
      }
      final ledgerProv = context.read<LedgerProvider>();
      final customer = await ledgerProv.findOrCreateCustomer(
        cart.creditCustomerName,
        phone: cart.creditCustomerPhone,
      );
      if (customer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create customer'), backgroundColor: AppTheme.error),
        );
        return;
      }
      cart.setCustomerId(customer.id);
      payload['customerId'] = customer.id;
    }
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
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Sale completed! Total: ${CurrencyFormatter.format(sale.total)}')),
            ],
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
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
    final cart = context.watch<CartProvider>();
    final saleProv = context.watch<SaleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shopping_cart, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text('Cart (${cart.itemCount})'),
          ],
        ),
        actions: [
          if (!cart.isEmpty)
            TextButton.icon(
              onPressed: cart.clearCart,
              icon: const Icon(Icons.delete_sweep, size: 18),
              label: const Text('Clear', style: TextStyle(color: AppTheme.error)),
            ),
        ],
      ),
      body: cart.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 20),
                  const Text('Cart is empty', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text('Add products from the POS screen', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...cart.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CartItemCard(item: item, cart: cart),
                )),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.darkBorder.withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
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
                          Text('Order Summary', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SummaryRow(label: 'Subtotal', value: CurrencyFormatter.format(cart.subtotal)),
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
                const SizedBox(height: 20),
                Text('Discount & Tax', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
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
                      selectedColor: AppTheme.accent,
                      backgroundColor: AppTheme.darkCard,
                      onSelected: (_) => cart.setTaxRate(val),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text('Payment Method', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: ['CASH', 'CARD', 'MOBILE', 'CREDIT'].map((method) {
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
                if (cart.paymentMethod == 'CREDIT') ...[
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Customer Name',
                      prefixIcon: Icon(Icons.person),
                    ),
                    onChanged: cart.setCreditCustomerName,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Phone (optional)',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    onChanged: cart.setCreditCustomerPhone,
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
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
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle),
                    label: Text(
                      saleProv.isLoading ? 'Processing...' : 'Complete Sale - ${CurrencyFormatter.format(cart.total)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 4,
                      shadowColor: AppTheme.success.withOpacity(0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                    child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: item.quantity < product.stock ? () => cart.addProduct(product) : null,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(Icons.add, size: 16, color: item.quantity < product.stock ? Colors.grey[400] : Colors.grey[700]),
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
