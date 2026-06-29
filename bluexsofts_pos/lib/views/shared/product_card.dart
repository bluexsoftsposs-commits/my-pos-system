import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../core/theme.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final CartProvider cart;
  const ProductCard({super.key, required this.product, required this.cart});

  @override
  Widget build(BuildContext context) {
    final outOfStock = product.stock <= 0;
    return Card(
      color: outOfStock ? AppTheme.darkCard.withOpacity(0.4) : null,
      child: InkWell(
        onTap: outOfStock ? null : () => cart.addProduct(product),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: Icon(
                    Icons.inventory_2,
                    size: 32,
                    color: outOfStock ? Colors.grey : AppTheme.primary,
                  ),
                ),
              ),
              Text(
                product.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: outOfStock ? Colors.grey : null,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '\$${product.price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 12,
                  color: outOfStock ? Colors.grey : AppTheme.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (outOfStock)
                const Text('Out of stock', style: TextStyle(fontSize: 10, color: AppTheme.error))
              else
                Text(
                  'Stock: ${product.stock}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
