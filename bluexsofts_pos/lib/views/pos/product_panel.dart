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
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1.1,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: productProv.products.length,
                      itemBuilder: (context, index) {
                        final product = productProv.products[index];
                        return ProductCard(product: product, cart: cart);
                      },
                    ),
        ),
      ],
    );
  }
}
