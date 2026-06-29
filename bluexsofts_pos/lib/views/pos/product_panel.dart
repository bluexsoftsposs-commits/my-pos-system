import 'package:flutter/material.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../shared/product_card.dart';

class ProductPanel extends StatefulWidget {
  final ProductProvider productProv;
  final CartProvider cart;
  const ProductPanel({super.key, required this.productProv, required this.cart});

  @override
  State<ProductPanel> createState() => _ProductPanelState();
}

class _ProductPanelState extends State<ProductPanel> {
  final _searchCtrl = TextEditingController();

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
          child: productProv.isLoading
              ? const Center(child: CircularProgressIndicator())
              : productProv.products.isEmpty
                  ? const Center(child: Text('No products found'))
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final crossAxisCount = width > 900 ? 4 : width > 600 ? 3 : 2;
                        final aspectRatio = width > 600 ? 1.1 : 0.95;
                        final spacing = width > 600 ? 8.0 : 4.0;
                        return CustomScrollView(
                          slivers: [
                            SliverToBoxAdapter(
                              child: Padding(
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
                                  return ProductCard(product: product, cart: cart);
                                },
                                childCount: productProv.products.length,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
