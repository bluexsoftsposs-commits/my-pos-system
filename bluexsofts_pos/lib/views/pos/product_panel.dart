import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/sale_provider.dart';
import '../../core/theme.dart';
import '../../core/currency_formatter.dart';
import '../shared/product_card.dart';
import '../pos/cart_panel.dart';
import '../pos/checkout_panel.dart';
import '../../screens/barcode_scanner_screen.dart';
import '../../core/currency_formatter.dart';

class ProductPanel extends StatefulWidget {
  final ProductProvider productProv;
  final CartProvider cart;
  const ProductPanel({super.key, required this.productProv, required this.cart});

  @override
  State<ProductPanel> createState() => _ProductPanelState();
}

class _ProductPanelState extends State<ProductPanel> {
  final _searchCtrl = TextEditingController();
  bool _showCheckout = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productProv = widget.productProv;
    final cart = widget.cart;

    return Column(
      children: [
        Expanded(
          child: _showCheckout
              ? CheckoutPanel(
                  cart: cart,
                  saleProv: context.read<SaleProvider>(),
                  onBack: () => setState(() => _showCheckout = false),
                )
              : productProv.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : productProv.products.isEmpty
                      ? const Center(child: Text('No products found'))
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth >= 768;
                            if (isWide) {
                              return Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: _buildProductGrid(constraints, productProv),
                                  ),
                                  Container(
                                    width: 1,
                                    color: AppTheme.darkBorder.withOpacity(0.5),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: CartPanel(
                                      cart: cart,
                                      onCheckout: () => setState(() => _showCheckout = true),
                                    ),
                                  ),
                                ],
                              );
                            }
                            return _buildProductGrid(constraints, productProv);
                          },
                        ),
        ),
        if (!_showCheckout && widget.cart.itemCount > 0)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: BoxDecoration(
              color: AppTheme.darkSurface,
              border: Border(top: BorderSide(color: AppTheme.darkBorder.withOpacity(0.5))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${widget.cart.itemCount} item(s)',
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      Text(
                        CurrencyFormatter.format(widget.cart.total),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.success,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => setState(() => _showCheckout = true),
                  icon: const Icon(Icons.shopping_cart_checkout, size: 20),
                  label: const Text('Checkout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildProductGrid(BoxConstraints constraints, ProductProvider productProv) {
    final crossAxisCount = constraints.maxWidth > 900 ? 4 : constraints.maxWidth > 600 ? 3 : 2;
    final aspectRatio = constraints.maxWidth > 600 ? 1.1 : 0.95;
    final spacing = constraints.maxWidth > 600 ? 8.0 : 4.0;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                productProv.setSearchQuery('');
                              },
                            )
                          : null,
                    ),
                    onChanged: productProv.setSearchQuery,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.accentGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accent.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                    onPressed: () => _openBarcodeScanner(),
                    tooltip: 'Scan barcode',
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: productProv.categories.map((cat) {
                  final selected = productProv.selectedCategory == cat;
                  final categoryColors = {
                    'General': Colors.blue,
                    'Groceries': Colors.green,
                    'Beverages': Colors.cyan,
                    'Meat & Poultry': Colors.red,
                    'Spices & Condiments': Colors.orange,
                    'Bakery': Colors.amber,
                  };
                  final catColor = categoryColors[cat] ?? AppTheme.primary;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat, style: TextStyle(
                        fontSize: 13,
                        color: selected ? Colors.white : catColor,
                      )),
                      selected: selected,
                      selectedColor: catColor,
                      backgroundColor: catColor.withOpacity(0.1),
                      checkmarkColor: Colors.white,
                      showCheckmark: false,
                      side: BorderSide(color: selected ? catColor : catColor.withOpacity(0.3)),
                      onSelected: (_) => productProv.setCategory(cat),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(child: const SizedBox(height: 8)),
        SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: aspectRatio,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final product = productProv.products[index];
              return ProductCard(product: product, cart: widget.cart);
            },
            childCount: productProv.products.length,
          ),
        ),
        SliverToBoxAdapter(child: const SizedBox(height: 80)),
      ],
    );
  }

  void _openBarcodeScanner() async {
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );

    if (barcode == null || barcode.isEmpty) return;
    if (!mounted) return;

    // Try to find the product by barcode
    final product = await context.read<ProductProvider>().findProductByBarcode(barcode);

    if (!mounted) return;

    if (product != null) {
      widget.cart.addProduct(product);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('${product.name} added to cart')),
            ],
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Product not found')),
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

}
