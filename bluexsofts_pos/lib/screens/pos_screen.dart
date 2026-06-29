import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/sale_provider.dart';
import '../providers/auth_provider.dart';
import '../core/theme.dart';
import '../views/pos/product_panel.dart';
import '../views/pos/cart_panel.dart';
import '../views/pos/checkout_panel.dart';
import 'plans_screen.dart';

class POSScreen extends StatefulWidget {
  const POSScreen({super.key});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  bool _showCheckout = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ProductProvider>().loadProducts());
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isSuperAdmin && !auth.hasActiveSubscription) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 48, color: AppTheme.warning),
            const SizedBox(height: 12),
            const Text('Active subscription required to use POS'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PlansScreen()),
              ),
              child: const Text('View Plans'),
            ),
          ],
        ),
      );
    }

    final productProv = context.watch<ProductProvider>();
    final cart = context.watch<CartProvider>();
    final saleProv = context.watch<SaleProvider>();

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(flex: 3, child: ProductPanel(productProv: productProv, cart: cart)),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 2,
                child: _showCheckout
                    ? CheckoutPanel(
                        cart: cart,
                        saleProv: saleProv,
                        onBack: () => setState(() => _showCheckout = false),
                      )
                    : CartPanel(
                        cart: cart,
                        onCheckout: () => setState(() => _showCheckout = true),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
