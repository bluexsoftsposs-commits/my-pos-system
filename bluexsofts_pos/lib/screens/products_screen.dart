import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';
import '../models/product.dart';
import '../core/theme.dart';
import '../views/shared/product_form.dart';

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

  void _showProductForm({Product? product}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ProductForm(product: product),
    );
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
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: productProv.categories.map((cat) {
                final selected = productProv.selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: selected,
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
                    ? const Center(child: Text('No products found'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: productProv.products.length,
                        itemBuilder: (context, index) {
                          final product = productProv.products[index];
                          return _buildProductListTile(product, auth.isAdmin);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: auth.isAdmin
          ? FloatingActionButton(
              onPressed: () => _showProductForm(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildProductListTile(Product product, bool isAdmin) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary.withOpacity(0.2),
          child: Icon(Icons.inventory_2, color: AppTheme.primary),
        ),
        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${product.category} | SKU: ${product.sku}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('\$${product.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Stock: ${product.stock}', style: TextStyle(fontSize: 12, color: product.stock <= 5 ? AppTheme.warning : Colors.grey)),
          ],
        ),
        onTap: isAdmin ? () => _showProductForm(product: product) : null,
      ),
    );
  }
}
