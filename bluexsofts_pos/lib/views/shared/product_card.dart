import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../core/theme.dart';
import '../../core/currency_formatter.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final CartProvider cart;
  const ProductCard({super.key, required this.product, required this.cart});

  @override
  Widget build(BuildContext context) {
    final outOfStock = product.stock <= 0;
    return Card(
      color: outOfStock ? AppTheme.darkCard.withOpacity(0.4) : null,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: outOfStock ? null : () => cart.addProduct(product),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Icon(
                  Icons.inventory_2,
                  size: 22,
                  color: outOfStock ? Colors.grey : AppTheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                product.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  color: outOfStock ? Colors.grey : null,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                CurrencyFormatter.format(product.price),
                style: TextStyle(
                  fontSize: 11,
                  color: outOfStock ? Colors.grey : AppTheme.success,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (outOfStock)
                const Text('Out of stock', style: TextStyle(fontSize: 9, color: AppTheme.error), maxLines: 1, overflow: TextOverflow.ellipsis)
              else
                Text(
                  'Stock: ${product.stock}',
                  style: const TextStyle(fontSize: 9, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
