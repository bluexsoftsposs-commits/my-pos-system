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
    return Container(
      decoration: BoxDecoration(
        color: outOfStock ? AppTheme.darkCard.withOpacity(0.4) : AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: outOfStock
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
        border: Border.all(
          color: outOfStock ? AppTheme.darkBorder.withOpacity(0.3) : AppTheme.darkBorder.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: outOfStock ? null : () => cart.addProduct(product),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: outOfStock
                            ? null
                            : LinearGradient(
                                colors: [AppTheme.primary.withOpacity(0.2), AppTheme.accent.withOpacity(0.1)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        color: outOfStock ? Colors.grey[800] : null,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.inventory_2,
                        size: 24,
                        color: outOfStock ? Colors.grey : AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    product.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: outOfStock ? Colors.grey : Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(product.price),
                    style: TextStyle(
                      fontSize: 13,
                      color: outOfStock ? Colors.grey : AppTheme.success,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (outOfStock)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Out of stock',
                        style: TextStyle(fontSize: 9, color: AppTheme.error, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  else
                    Text(
                      'Stock: ${product.stock}',
                      style: TextStyle(fontSize: 10, color: product.stock <= 5 ? AppTheme.warning : Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
