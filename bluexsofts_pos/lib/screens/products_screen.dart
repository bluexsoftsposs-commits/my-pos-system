import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';
import '../models/product.dart';
import '../core/theme.dart';
import '../core/currency_formatter.dart';
import '../views/shared/product_form.dart';
import 'barcode_scanner_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ProductProvider>().loadProducts());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showProductForm({
    Product? product,
    String? initialBarcode,
    String? initialName,
    String? initialImageUrl,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ProductForm(
        product: product,
        initialBarcode: initialBarcode,
        initialName: initialName,
        initialImageUrl: initialImageUrl,
      ),
    );
  }

  Future<void> _handleBarcodeScan() async {
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (barcode == null || barcode.isEmpty) return;
    if (!mounted) return;

    _showScanningOverlay(true);

    // Layer 1: check locally
    final existing = await context.read<ProductProvider>().findProductByBarcode(barcode);
    if (!mounted) return;

    if (existing != null) {
      _showScanningOverlay(false);
      _showProductForm(product: existing);
      return;
    }

    // Layer 2: query Open Food Facts API
    try {
      final response = await http.get(
        Uri.parse('https://world.openfoodfacts.org/api/v2/product/$barcode.json'),
      ).timeout(const Duration(seconds: 8));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['status'] == 1) {
          final product = body['product'] as Map<String, dynamic>?;
          if (product != null) {
            final productName = product['product_name'] as String? ?? product['brands'] as String? ?? '';
            final imageUrl = product['image_url'] as String?;
            final apiCategories = product['categories'] as String? ?? '';

            _showScanningOverlay(false);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Found: $productName'),
                backgroundColor: AppTheme.success,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );

            _showProductForm(
              initialBarcode: barcode,
              initialName: productName,
              initialImageUrl: imageUrl,
            );
            return;
          }
        }
      }
    } catch (_) {
      // Fall through to layer 3
    }

    if (!mounted) return;
    _showScanningOverlay(false);

    // Layer 3: not found anywhere
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Product not found in database — enter details manually.'),
        backgroundColor: AppTheme.warning,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );

    _showProductForm(initialBarcode: barcode);
  }

  OverlayEntry? _scanOverlay;

  void _showScanningOverlay(bool show) {
    if (show) {
      _scanOverlay?.remove();
      _scanOverlay = OverlayEntry(
        builder: (_) => Container(
          color: Colors.black.withValues(alpha: 0.5),
          child: const Center(
            child: Card(
              color: AppTheme.darkSurface,
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppTheme.primary),
                    SizedBox(height: 16),
                    Text('Looking up product...', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      Overlay.of(context).insert(_scanOverlay!);
    } else {
      _scanOverlay?.remove();
      _scanOverlay = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProv = context.watch<ProductProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search products by name or SKU...',
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
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
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
                    side: BorderSide(
                      color: selected ? catColor : catColor.withOpacity(0.3),
                    ),
                    onSelected: (_) => productProv.setCategory(cat),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: productProv.isLoading
                ? const Center(child: CircularProgressIndicator())
                : productProv.products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[600]),
                            const SizedBox(height: 12),
                            const Text('No products found', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth >= 768) {
                            return _buildDesktopTable(productProv);
                          }
                          return _buildMobileList(productProv, auth);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: auth.isAdmin
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'scan',
                  mini: true,
                  onPressed: _handleBarcodeScan,
                  backgroundColor: AppTheme.darkCard,
                  child: const Icon(Icons.qr_code_scanner, color: AppTheme.primary),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'add',
                  onPressed: () => _showProductForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Product'),
                  backgroundColor: AppTheme.primary,
                  elevation: 4,
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildDesktopTable(ProductProvider productProv) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(AppTheme.darkSurface),
        dataRowColor: WidgetStateProperty.all(AppTheme.darkCard),
        border: TableBorder(
          borderRadius: BorderRadius.circular(12),
          horizontalInside: BorderSide(color: AppTheme.darkBorder.withOpacity(0.3)),
        ),
        columns: const [
          DataColumn(label: Text('Product', style: TextStyle(fontWeight: FontWeight.w600))),
          DataColumn(label: Text('SKU', style: TextStyle(fontWeight: FontWeight.w600))),
          DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.w600))),
          DataColumn(label: Text('Price', style: TextStyle(fontWeight: FontWeight.w600)), numeric: true),
          DataColumn(label: Text('Stock', style: TextStyle(fontWeight: FontWeight.w600)), numeric: true),
          DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600))),
        ],
        rows: productProv.products.map((product) {
          final auth = context.read<AuthProvider>();
          return DataRow(
            cells: [
              DataCell(Text(product.name, style: const TextStyle(fontWeight: FontWeight.w500))),
              DataCell(Text(product.sku.isEmpty ? '-' : product.sku, style: const TextStyle(fontSize: 13))),
              DataCell(_buildCategoryBadge(product.category)),
              DataCell(Text(CurrencyFormatter.format(product.price), style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(_buildStockBadge(product.stock)),
              DataCell(
                auth.isAdmin
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: () => _showProductForm(product: product),
                            color: AppTheme.primary,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            onPressed: () => _confirmDelete(product),
                            color: AppTheme.error,
                          ),
                        ],
                      )
                    : const SizedBox(),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMobileList(ProductProvider productProv, AuthProvider auth) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: productProv.products.length,
      itemBuilder: (context, index) {
        final product = productProv.products[index];
        return _buildProductCard(product, auth.isAdmin);
      },
    );
  }

  Widget _buildProductCard(Product product, bool isAdmin) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.darkBorder.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 3)),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: isAdmin ? () => _showProductForm(product: product) : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary.withOpacity(0.2), AppTheme.accent.withOpacity(0.1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.inventory_2, color: AppTheme.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildCategoryBadge(product.category),
                        const SizedBox(width: 8),
                        Text(
                          'SKU: ${product.sku.isNotEmpty ? product.sku : '-'}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(product.price),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.success),
                  ),
                  const SizedBox(height: 4),
                  _buildStockBadge(product.stock),
                ],
              ),
              if (isAdmin) ...[
                const SizedBox(width: 4),
                PopupMenuButton(
                  icon: Icon(Icons.more_vert, size: 18, color: Colors.grey[500]),
                  color: AppTheme.darkSurface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (value) {
                    if (value == 'edit') _showProductForm(product: product);
                    if (value == 'delete') _confirmDelete(product);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Row(
                      children: [Icon(Icons.edit, size: 18, color: AppTheme.primary), SizedBox(width: 8), Text('Edit')],
                    )),
                    const PopupMenuItem(value: 'delete', child: Row(
                      children: [Icon(Icons.delete, size: 18, color: AppTheme.error), SizedBox(width: 8), Text('Delete')],
                    )),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(String category) {
    final categoryColors = {
      'General': Colors.blue,
      'Groceries': Colors.green,
      'Beverages': Colors.cyan,
      'Meat & Poultry': Colors.red,
      'Spices & Condiments': Colors.orange,
      'Bakery': Colors.amber,
    };
    final color = categoryColors[category] ?? AppTheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        category,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildStockBadge(int stock) {
    final color = stock <= 0
        ? AppTheme.error
        : stock <= 5
            ? AppTheme.warning
            : AppTheme.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        stock <= 0 ? 'Out' : 'Stock: $stock',
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }

  void _confirmDelete(Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await context.read<ProductProvider>().deleteProduct(product.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Product deleted' : 'Failed to delete'),
                    backgroundColor: success ? AppTheme.success : AppTheme.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
