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
          const SnackBar(
            content: Text('Customer name required for credit sale'),
            backgroundColor: AppTheme.error,
          ),
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
          const SnackBar(
            content: Text('Failed to create customer'),
            backgroundColor: AppTheme.error,
          ),
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
        context
            .read<ProductProvider>()
            .decrementStock(item.product.id, item.quantity);
      }
      cart.clearCart();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sale completed! Total: ${CurrencyFormatter.format(sale.total)}',
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
              Expanded(
                child: Text('Sale saved offline. Will sync when online.'),
              ),
            ],
          ),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AppTheme.successGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Sale Completed!',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Total: ${CurrencyFormatter.format(sale.total)}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.success,
              ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Skip',
                style: TextStyle(color: Colors.grey),
              ),
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Your Cart',
          style: TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront),
            onPressed: () => Navigator.of(context).pop(),
          ),
          if (!cart.isEmpty)
            IconButton(
              onPressed: cart.clearCart,
              icon: const Icon(
                Icons.delete_sweep,
                size: 20,
                color: AppTheme.error,
              ),
            ),
        ],
      ),
      body: cart.isEmpty ? _buildEmptyState() : _buildCartBody(cart, saleProv),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 48,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Cart is empty',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Add products from the POS screen',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildCartBody(CartProvider cart, SaleProvider saleProv) {
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            ...cart.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CartItemCard(item: item, cart: cart),
              ),
            ),
            const SizedBox(height: 8),
            _buildOrderSummary(cart),
            const SizedBox(height: 24),
            _buildDiscountSection(cart),
            const SizedBox(height: 20),
            _buildPaymentSection(cart),
            if (cart.paymentMethod == 'CREDIT') ...[
              const SizedBox(height: 12),
              _buildCreditFields(cart),
            ],
            const SizedBox(height: 12),
            _buildNotesField(cart),
          ],
        ),
        _buildBottomCheckout(cart, saleProv),
      ],
    );
  }

  Widget _buildOrderSummary(CartProvider cart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Summary',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFC8C4D7),
            ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.darkSurface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Subtotal',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.darkBorder,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(cart.subtotal),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (cart.taxAmount > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tax (${(cart.taxRate * 100).toStringAsFixed(0)}%)',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.darkBorder,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(cart.taxAmount),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              if (cart.discount > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Discount',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.darkBorder,
                        ),
                      ),
                      Text(
                        '-${CurrencyFormatter.format(cart.discount)}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppTheme.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              Divider(color: AppTheme.darkBorder.withOpacity(0.3)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(cart.total),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFC6BFFF),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDiscountSection(CartProvider cart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Discount & Tax',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkBorder,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF4BDDB7).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.edit,
                      size: 14,
                      color: const Color(0xFF4BDDB7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'EDIT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                        color: const Color(0xFF4BDDB7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
        Text(
          'Tax Rate',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.darkBorder,
          ),
        ),
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
      ],
    );
  }

  Widget _buildPaymentSection(CartProvider cart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.darkBorder,
          ),
        ),
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
      ],
    );
  }

  Widget _buildCreditFields(CartProvider cart) {
    return Column(
      children: [
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
    );
  }

  Widget _buildNotesField(CartProvider cart) {
    return TextField(
      decoration: const InputDecoration(
        labelText: 'Notes (optional)',
        prefixIcon: Icon(Icons.notes),
      ),
      controller: _notesCtrl,
      maxLines: 2,
      onChanged: cart.setNotes,
    );
  }

  Widget _buildBottomCheckout(CartProvider cart, SaleProvider saleProv) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF131313).withOpacity(0),
              const Color(0xFF131313),
            ],
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: saleProv.isLoading ? null : _completeSale,
            icon: saleProv.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.arrow_forward),
            label: Text(
              saleProv.isLoading
                  ? 'Processing...'
                  : 'Proceed to Payment  ·  ${CurrencyFormatter.format(cart.total)}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: const Color(0xFF6C5CE7).withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
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
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: product.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                          Icons.inventory_2,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.inventory_2,
                      color: Colors.grey,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => cart.removeItem(product.id),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.delete,
                            size: 18,
                            color: AppTheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.description.isNotEmpty
                        ? product.description
                        : '--',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        CurrencyFormatter.format(product.price),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFC6BFFF),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.darkCard,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => cart.removeProduct(product.id),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppTheme.darkSurface,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.remove,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: item.quantity < product.stock
                                  ? () => cart.addProduct(product)
                                  : null,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppTheme.darkSurface,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  Icons.add,
                                  size: 18,
                                  color: item.quantity < product.stock
                                      ? Colors.grey
                                      : Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
