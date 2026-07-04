import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';
import '../models/product.dart';
import '../core/theme.dart';
import '../core/currency_formatter.dart';
import '../services/plan_service.dart';
import '../views/shared/product_form.dart';
import 'barcode_scanner_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _searchCtrl = TextEditingController();
  int _currentPage = 1;
  static const int _pageSize = 5;
  bool _isRefreshing = false;
  bool _showAsGrid = true;

  final _planService = PlanService();
  int _productsUsed = 0;
  int _productsLimit = 0;
  String _planName = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ProductProvider>().loadProducts();
      _loadPlanUsage();
    });
  }

  Future<void> _loadPlanUsage() async {
    try {
      final auth = context.read<AuthProvider>();
      final shopId = auth.shop?.id;
      if (shopId == null) return;
      final data = await _planService.getSubscription(shopId);
      if (!mounted) return;
      final usage = data?['usage'] as Map<String, dynamic>?;
      final sub = data?['subscription'] as Map<String, dynamic>?;
      final plan = sub?['plan'] as Map<String, dynamic>?;
      setState(() {
        _productsUsed = usage?['productsUsed'] as int? ?? 0;
        _productsLimit = usage?['productsLimit'] as int? ?? 0;
        _planName = plan?['name'] as String? ?? '';
      });
    } catch (_) {}
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
        productsUsed: _productsUsed,
        productsLimit: _productsLimit,
        planName: _planName,
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

    final existing = await context.read<ProductProvider>().findProductByBarcode(barcode);
    if (!mounted) return;

    if (existing != null) {
      _showScanningOverlay(false);
      _showProductForm(product: existing);
      return;
    }

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
    } catch (_) {}

    if (!mounted) return;
    _showScanningOverlay(false);

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
    final products = productProv.products;
    final totalItems = products.length;
    final lowStock = products.where((p) => p.stock > 0 && p.stock <= p.lowStockThreshold).length;
    final outOfStock = products.where((p) => p.stock <= 0).length;
    final categories = productProv.categories;

    final fromItem = totalItems > 0 ? ((_currentPage - 1) * _pageSize) + 1 : 0;
    final toItem = (_currentPage * _pageSize) > totalItems ? totalItems : (_currentPage * _pageSize);
    final totalPages = (totalItems / _pageSize).ceil();

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 900;

          if (isWide || isTablet) {
            final gridCols = isWide ? 3 : 2;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                  AppTheme.spaceMd, 0, AppTheme.spaceMd, AppTheme.spaceMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppTheme.spaceMd),
                  _buildSearchField(productProv),
                  const SizedBox(height: AppTheme.spaceMd),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Product Inventory',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Manage and monitor your retail stock efficiently.',
                              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildViewToggle(),
                      const SizedBox(width: 8),
                      if (auth.isAdmin)
                        _buildAddProductButton()
                      else
                        const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  Row(
                    children: [
                      _buildIconButton(Icons.download_outlined, 'Export', () =>
                          _exportCsv(productProv.allProducts)),
                      const SizedBox(width: AppTheme.spaceSm),
                      if (auth.isAdmin)
                        _buildIconButton(Icons.qr_code_scanner, 'Scan', _handleBarcodeScan),
                      const Spacer(),
                      _buildRefreshButton(),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceLg),
                  _buildStatsRow(products.length, lowStock, outOfStock),
                  const SizedBox(height: AppTheme.spaceLg),
                  _buildFilterChips(productProv, categories),
                  const SizedBox(height: AppTheme.spaceMd),
                  if (productProv.isLoading && products.isEmpty)
                    const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (products.isEmpty)
                    _buildEmptyState()
                  else ...[
                    _showAsGrid
                        ? _buildProductGrid(products, auth, crossAxisCount: gridCols)
                        : _buildMobileList(products, auth),
                    if (totalItems > _pageSize)
                      _buildPagination(totalItems, fromItem, toItem, totalPages),
                    const SizedBox(height: 80),
                  ],
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceMd, 0, AppTheme.spaceMd, AppTheme.spaceMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(auth, productProv),
                const SizedBox(height: AppTheme.spaceMd),
                _buildSearchField(productProv),
                const SizedBox(height: AppTheme.spaceMd),
                _buildFilterChips(productProv, categories),
                const SizedBox(height: AppTheme.spaceMd),
                _buildStatsRow(products.length, lowStock, outOfStock),
                const SizedBox(height: AppTheme.spaceLg),
                if (productProv.isLoading && products.isEmpty)
                  const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (products.isEmpty)
                  _buildEmptyState()
                else ...[
                  _buildMobileList(products, auth),
                  const SizedBox(height: 80),
                  if (totalItems > _pageSize)
                    _buildPagination(totalItems, fromItem, toItem, totalPages),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(AuthProvider auth, ProductProvider productProv) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.spaceMd, AppTheme.spaceMd, AppTheme.spaceMd, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product Inventory',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage and monitor your retail stock efficiently.',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
          const SizedBox(height: AppTheme.spaceMd),
          Row(
            children: [
              _buildIconButton(Icons.download_outlined, 'Export', () =>
                  _exportCsv(productProv.allProducts)),
              const SizedBox(width: AppTheme.spaceSm),
              if (auth.isAdmin)
                _buildIconButton(Icons.qr_code_scanner, 'Scan', _handleBarcodeScan),
              if (auth.isAdmin) ...[
                const SizedBox(width: AppTheme.spaceSm),
                _buildAddProductButton(),
              ],
              const Spacer(),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _isRefreshing
                      ? null
                      : () async {
                          setState(() => _isRefreshing = true);
                          debugPrint('[Refresh] Starting loadProducts…');
                          await productProv.loadProducts(forceRefresh: true);
                          debugPrint('[Refresh] loadProducts done, error=${productProv.error}');
                          if (productProv.error != null && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(productProv.error!),
                                backgroundColor: AppTheme.error,
                              ),
                            );
                          }
                          setState(() => _isRefreshing = false);
                        },
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    child: _isRefreshing
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          )
                        : Icon(Icons.refresh,
                            color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, String label, VoidCallback onTap) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          onTap: onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: Colors.grey[400]),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewToggle() {
    final gridActive = _showAsGrid;
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.darkBorder.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleButton(Icons.grid_view_rounded, gridActive, () => setState(() => _showAsGrid = true)),
          Container(width: 1, height: 20, color: AppTheme.darkBorder.withValues(alpha: 0.3)),
          _toggleButton(Icons.view_list_rounded, !gridActive, () => setState(() => _showAsGrid = false)),
        ],
      ),
    );
  }

  Widget _toggleButton(IconData icon, bool active, VoidCallback onTap) {
    return Material(
      color: active ? AppTheme.primary.withValues(alpha: 0.15) : Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: active ? AppTheme.primary : Colors.grey[500]),
        ),
      ),
    );
  }

  Widget _buildAddProductButton() {
    return Material(
      color: AppTheme.primary,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showProductForm(),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.add, size: 18, color: Colors.white),
              SizedBox(width: 6),
              Text('Add Product', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRefreshButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _isRefreshing
            ? null
            : () async {
                setState(() => _isRefreshing = true);
                await context.read<ProductProvider>().loadProducts(forceRefresh: true);
                if (mounted) {
                  setState(() => _isRefreshing = false);
                }
              },
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: _isRefreshing
              ? SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                )
              : Icon(Icons.refresh, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _buildSearchField(ProductProvider productProv) {
    return TextField(
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
    );
  }

  Widget _buildStatsRow(int totalProducts, int lowStock, int outOfStock) {
    final cards = [
      _buildStatCard('Total Products', '$totalProducts', AppTheme.primary, Icons.inventory_2),
      _buildStatCard('Low Stock', '$lowStock', AppTheme.warning, Icons.warning_amber),
      _buildStatCard('Out of Stock', '$outOfStock', AppTheme.error, Icons.highlight_off),
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 600) {
                return GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppTheme.spaceMd,
                  crossAxisSpacing: AppTheme.spaceMd,
                  childAspectRatio: 2.4,
                  children: cards,
                );
              }
              return Row(
                children: cards.map((c) => Expanded(child: c)).toList(),
              );
            },
          ),
        ),
        if (_productsLimit > 0) ...[
          const SizedBox(height: AppTheme.spaceMd),
          _buildUsageProgressBar(),
        ],
      ],
    );
  }

  Widget _buildUsageProgressBar() {
    final pct = _productsLimit > 0 ? (_productsUsed / _productsLimit) : 0.0;
    final pctDisplay = '${(pct * 100).toStringAsFixed(1)}%';
    final remaining = _productsLimit - _productsUsed;

    Color barColor;
    if (pct >= 0.9) {
      barColor = AppTheme.error;
    } else if (pct >= 0.7) {
      barColor = AppTheme.warning;
    } else {
      barColor = AppTheme.primary;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.darkBorder.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage, size: 16, color: barColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Product Limit ($_planName)',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Text(
                  '$_productsUsed / $_productsLimit',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[400]),
                ),
                const SizedBox(width: 6),
                Text(
                  'Using $pctDisplay',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: barColor),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation(barColor),
              ),
            ),
            if (remaining <= 0) ...[
              const SizedBox(height: 6),
              Text(
                '🔒 You\'ve reached your product limit. Upgrade to add more.',
                style: TextStyle(fontSize: 11, color: AppTheme.error, fontWeight: FontWeight.w500),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color valueColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.darkBorder.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 16, color: valueColor.withValues(alpha: 0.3)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(ProductProvider productProv, List<String> categories) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
      child: SizedBox(
        height: 38,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildAllProductsChip(productProv),
            ),
            ...categories.where((c) => c != 'All').map((cat) {
              final selected = productProv.selectedCategory == cat;
              final catColor = _categoryColor(cat);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat, style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? catColor : Colors.grey[400],
                  )),
                  selected: selected,
                  selectedColor: catColor.withValues(alpha: 0.15),
                  backgroundColor: AppTheme.darkCard,
                  checkmarkColor: Colors.transparent,
                  showCheckmark: false,
                  side: BorderSide(
                    color: selected ? catColor : AppTheme.darkBorder.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                  onSelected: (_) {
                    productProv.setCategory(cat);
                    setState(() => _currentPage = 1);
                  },
                ),
              );
            }),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildMoreFiltersChip(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllProductsChip(ProductProvider productProv) {
    final active = productProv.selectedCategory == 'All';
    return GestureDetector(
      onTap: () {
        productProv.setCategory('All');
        setState(() => _currentPage = 1);
      },
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: active ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppTheme.primary : AppTheme.darkBorder.withValues(alpha: 0.4),
            width: 1.2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          'All Products',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : Colors.grey[400],
          ),
        ),
      ),
    );
  }

  Widget _buildMoreFiltersChip() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.darkBorder.withValues(alpha: 0.4), width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {},
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('≡', style: TextStyle(fontSize: 16, color: Colors.grey[400], fontWeight: FontWeight.w700)),
              const SizedBox(width: 4),
              Text('More Filters', style: TextStyle(fontSize: 12, color: Colors.grey[400], fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Color _categoryColor(String category) {
    const colors = {
      'General': Colors.blue,
      'Groceries': Colors.green,
      'Beverages': Colors.cyan,
      'Meat & Poultry': Colors.red,
      'Spices & Condiments': Colors.orange,
      'Bakery': Colors.amber,
    };
    return colors[category] ?? AppTheme.primary;
  }

  Widget _buildProductGrid(List<Product> products, AuthProvider auth, {int crossAxisCount = 3}) {
    final displayProducts = products
        .skip((_currentPage - 1) * _pageSize)
        .take(_pageSize)
        .toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(AppTheme.spaceMd, 0, AppTheme.spaceMd, AppTheme.spaceSm),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: AppTheme.spaceMd,
        crossAxisSpacing: AppTheme.spaceMd,
        childAspectRatio: 0.85,
      ),
      itemCount: displayProducts.length,
      itemBuilder: (context, index) {
        return _buildProductCard(displayProducts[index], auth);
      },
    );
  }

  Widget _buildProductCard(Product product, AuthProvider auth) {
    final isOut = product.stock <= 0;
    final isLow = product.stock > 0 && product.stock <= product.lowStockThreshold;
    final stockColor = isOut ? AppTheme.error : AppTheme.success;
    final stockLabel = isOut ? 'Out of Stock' : 'In Stock';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        onTap: auth.isAdmin ? () => _showProductForm(product: product) : null,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.darkSurface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.darkBorder.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 180,
                width: double.infinity,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg - 1)),
                      child: SizedBox(
                        width: double.infinity,
                        height: 180,
                        child: product.imageUrl.isNotEmpty
                            ? Image.network(
                                product.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _cardImagePlaceholder(),
                              )
                            : _cardImagePlaceholder(),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: stockColor.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              stockLabel,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (auth.isAdmin)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () => _confirmDelete(product),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(Icons.delete_outline, size: 16, color: Colors.white.withValues(alpha: 0.8)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.sku.isNotEmpty ? 'SKU: ${product.sku.toUpperCase()}' : '',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: Colors.grey[500],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          CurrencyFormatter.format(product.price),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppTheme.primary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Qty: ${product.stock}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCategoryBadge(product.category),
                        ),
                        const SizedBox(width: 8),
                        if (isOut)
                          InkWell(
                            onTap: auth.isAdmin ? () => _showProductForm(product: product) : null,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.refresh, size: 14, color: AppTheme.warning),
                                const SizedBox(width: 3),
                                Text(
                                  'Restock',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.warning),
                                ),
                              ],
                            ),
                          )
                        else
                          InkWell(
                            onTap: auth.isAdmin ? () => _showProductForm(product: product) : null,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Details',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[400]),
                                ),
                                const SizedBox(width: 3),
                                Icon(Icons.arrow_forward, size: 14, color: Colors.grey[500]),
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
      ),
    );
  }

  Widget _cardImagePlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2D1B69), Color(0xFF6C5CE7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(Icons.inventory_2, size: 40, color: Colors.white.withValues(alpha: 0.3)),
      ),
    );
  }

  Widget _buildMobileList(List<Product> products, AuthProvider auth) {
    final displayProducts = products
        .skip((_currentPage - 1) * _pageSize)
        .take(_pageSize)
        .toList();
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
      itemCount: displayProducts.length,
      itemBuilder: (context, index) {
        return _buildMobileCard(displayProducts[index], auth.isAdmin);
      },
    );
  }

  Widget _buildMobileCard(Product product, bool isAdmin) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.darkBorder.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        onTap: isAdmin ? () => _showProductForm(product: product) : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: product.imageUrl.isNotEmpty
                      ? Image.network(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2D1B69), Color(0xFF6C5CE7)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Icon(Icons.inventory_2, color: Colors.white.withValues(alpha: 0.7), size: 24),
                            ),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2D1B69), Color(0xFF6C5CE7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Icon(Icons.inventory_2, color: Colors.white.withValues(alpha: 0.7), size: 24),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          CurrencyFormatter.format(product.price),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    if (product.sku.isNotEmpty)
                      Text(
                        'SKU: ${product.sku}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildCategoryBadge(product.category),
                        const SizedBox(width: 8),
                        _buildStockBadge(product.stock, product.lowStockThreshold),
                      ],
                    ),
                  ],
                ),
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
    final color = _categoryColor(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            category,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockBadge(int stock, int threshold) {
    final color = stock <= 0
        ? AppTheme.error
        : stock <= threshold
            ? AppTheme.warning
            : AppTheme.success;
    final label = stock <= 0 ? 'Out' : 'Stock: $stock';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.darkSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.darkBorder),
            ),
            child: Icon(Icons.inventory_2_outlined, size: 40, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          const Text(
            'No products found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Products will appear here once added by an admin.',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(int totalItems, int fromItem, int toItem, int totalPages) {
    return Container(
      margin: const EdgeInsets.fromLTRB(AppTheme.spaceMd, 0, AppTheme.spaceMd, AppTheme.spaceSm),
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.darkBorder.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing $fromItem - $toItem of $totalItems products',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
          Row(
            children: [
              _buildPageButton(Icons.chevron_left, _currentPage > 1, () {
                setState(() => _currentPage--);
              }),
              const SizedBox(width: 4),
              ...() {
                if (totalPages <= 5) {
                  return List.generate(totalPages, (i) => i + 1);
                }
                final int start =
                    (_currentPage - 2).clamp(1, totalPages - 4);
                final int end = (start + 4).clamp(start, totalPages);
                return List.generate(end - start + 1, (i) => start + i);
              }().map((page) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: _buildPageNumber(page, page == _currentPage),
                  )),
              const SizedBox(width: 4),
              _buildPageButton(Icons.chevron_right, _currentPage < totalPages, () {
                setState(() => _currentPage++);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageButton(IconData icon, bool enabled, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: enabled ? onTap : null,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: enabled ? AppTheme.darkBorder : Colors.transparent),
          ),
          child: Icon(
            icon,
            size: 18,
            color: enabled ? Colors.grey[400] : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildPageNumber(int page, bool isActive) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: () => setState(() => _currentPage = page),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primary.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Center(
            child: Text(
              '$page',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isActive ? AppTheme.primary : Colors.grey[400],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _exportCsv(List<Product> products) {
    final buffer = StringBuffer();
    buffer.writeln('Name,SKU,Category,Price,Stock,Description');
    for (final p in products) {
      final name = p.name;
      final sku = p.sku;
      final cat = p.category;
      final price = p.price.toStringAsFixed(2);
      final stock = p.stock.toString();
      final desc = p.description.replaceAll(',', ';');
      buffer.writeln('$name,$sku,$cat,$price,$stock,$desc');
    }
    final csv = buffer.toString();
    final bytes = utf8.encode(csv);
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'products_export.csv')
      ..click();
    html.Url.revokeObjectUrl(url);
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
