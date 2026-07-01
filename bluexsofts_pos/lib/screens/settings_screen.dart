import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../views/shared/info_row.dart';
import 'login_screen.dart';
import 'plans_screen.dart';
import '../core/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _taxCtrl;

  @override
  void initState() {
    super.initState();
    final cart = context.read<CartProvider>();
    _taxCtrl = TextEditingController(text: (cart.taxRate * 100).toStringAsFixed(0));
  }

  @override
  void dispose() {
    _taxCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cart = context.watch<CartProvider>();
    final shop = auth.shop;

    String planLabel = shop?.subscriptionPlan ?? 'NONE';
    if (shop != null && shop.hasActiveSubscription) {
      final planNames = {'BASIC': 'Basic', 'PLATINUM': 'Platinum', 'PREMIUM': 'Premium'};
      planLabel = planNames[shop.subscriptionPlan] ?? shop.subscriptionPlan;
    } else if (shop?.subscriptionStatus == 'PENDING') {
      planLabel = 'Pending Payment';
    } else {
      planLabel = 'No Active Plan';
    }

    String? expiryText;
    if (shop?.subscriptionEndsAt != null) {
      expiryText = 'Expires: ${DateFormat('MMM dd, yyyy').format(shop!.subscriptionEndsAt!)}';
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Shop Settings', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Shop Information', style: Theme.of(context).textTheme.titleMedium),
                const Divider(),
                InfoRow(label: 'Shop Name', value: auth.shop?.shopName ?? 'N/A'),
                InfoRow(label: 'Plan', value: planLabel),
                if (expiryText != null) InfoRow(label: 'Expiry', value: expiryText),
                InfoRow(label: 'Status', value: auth.shop?.isActive == true ? 'Active' : 'Inactive'),
                if (!(auth.hasActiveSubscription)) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PlansScreen()),
                      ),
                      icon: const Icon(Icons.upgrade),
                      label: const Text('Upgrade Plan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('User Profile', style: Theme.of(context).textTheme.titleMedium),
                const Divider(),
                InfoRow(label: 'Name', value: auth.user?.name ?? 'N/A'),
                InfoRow(label: 'Email', value: auth.user?.email ?? 'N/A'),
                InfoRow(label: 'Role', value: auth.user?.role ?? 'N/A'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tax Settings', style: Theme.of(context).textTheme.titleMedium),
                const Divider(),
                TextFormField(
                  controller: _taxCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tax Rate (%)',
                    suffixText: '%',
                    prefixIcon: Icon(Icons.percent),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final rate = double.tryParse(v);
                    if (rate != null) {
                      cart.setTaxRate(rate / 100);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('App Info', style: Theme.of(context).textTheme.titleMedium),
                const Divider(),
                InfoRow(label: 'Version', value: '1.0.0'),
                InfoRow(label: 'API URL', value: 'https://my-pos-system-2.onrender.com/api'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _logout(auth),
            icon: const Icon(Icons.logout, color: AppTheme.error),
            label: const Text('Logout', style: TextStyle(color: AppTheme.error)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.error),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Future<void> _logout(AuthProvider auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Logout', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await auth.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}
