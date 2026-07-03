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
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    if (_showCheckout) {
      return CheckoutPanel(
        cart: cart,
        saleProv: context.read<SaleProvider>(),
        onBack: () => setState(() => _showCheckout = false),
      );
    }

    if (productProv.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (productProv.products.isEmpty) {
      return const Center(child: Text('No products found'));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: isDesktop ? _buildDesktopLayout(productProv, cart) : _buildMobileLayout(productProv, cart),
      floatingActionButton: !isDesktop
          ? FloatingActionButton(
              backgroundColor: AppTheme.primary,
              onPressed: _openBarcodeScanner,
              child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
            )
          : null,
    );
  }

  Widget _buildDesktopLayout(ProductProvider productProv, CartProvider cart) {
    return Row(
      children: [
        Expanded(
          flex: 7,
          child: Column(
            children: [
              _buildSearchBar(productProv),
              _buildCategoryChips(productProv),
              Expanded(child: _buildProductGrid(productProv, cart)),
            ],
          ),
        ),
        SizedBox(
          width: 420,
          child: CartPanel(
            cart: cart,
            onCheckout: () => setState(() => _showCheckout = true),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(ProductProvider productProv, CartProvider cart) {
    return Column(
      children: [
        _buildSearchBar(productProv),
        _buildCategoryChips(productProv),
        Expanded(child: _buildProductGrid(productProv, cart)),
        if (cart.itemCount > 0)
          _buildMobileBottomBar(cart),
      ],
    );
  }

  Widget _buildSearchBar(ProductProvider productProv) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(999),
              ),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(fontSize: 14, color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search products, SKUs, or categories...',
                  hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
                  prefixIcon: Icon(Icons.search, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          onPressed: () {
                            _searchCtrl.clear();
                            productProv.setSearchQuery('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: productProv.setSearchQuery,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(999),
            ),
            child: IconButton(
              icon: Icon(Icons.qr_code_scanner, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
              onPressed: _openBarcodeScanner,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(ProductProvider productProv) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _buildChip('All Items', productProv.selectedCategory == null, () => productProv.setCategory('')),
            ...productProv.categories.map((cat) {
              final selected = productProv.selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _buildChip(cat, selected, () => productProv.setCategory(cat)),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.darkCard,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : Colors.grey,
            letterSpacing: 0.03,
          ),
        ),
      ),
    );
  }

  Widget _buildProductGrid(ProductProvider productProv, CartProvider cart) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200 ? 4 : constraints.maxWidth > 800 ? 3 : 2;

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: productProv.products.length,
          itemBuilder: (context, index) {
            return ProductCard(
              product: productProv.products[index],
              cart: cart,
            );
          },
        );
      },
    );
  }

  Widget _buildMobileBottomBar(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${cart.itemCount} item(s)',
                  style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                Text(CurrencyFormatter.format(cart.total),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.success),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => setState(() => _showCheckout = true),
            icon: const Icon(Icons.shopping_cart_checkout, size: 20),
            label: const Text('Checkout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  void _openBarcodeScanner() async {
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );

    if (barcode == null || barcode.isEmpty) return;
    if (!mounted) return;

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
