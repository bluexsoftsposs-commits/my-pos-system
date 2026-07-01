import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/sale_provider.dart';
import '../core/theme.dart';
import '../core/currency_formatter.dart';
import '../views/shared/summary_card.dart';
import '../views/shared/action_card.dart';
import '../views/shared/sales_chart.dart';
import 'pos_screen.dart';
import 'cart_screen.dart';
import 'products_screen.dart';
import 'sales_screen.dart';
import 'invoices_screen.dart';
import 'users_screen.dart';
import 'settings_screen.dart';
import 'plans_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  List<Widget> _pages(bool isAdmin) {
    final base = <Widget>[
      const _DashboardHome(),
      const POSScreen(),
      const ProductsScreen(),
      const SalesScreen(),
      const InvoicesScreen(),
    ];
    if (isAdmin) {
      base.add(const UsersScreen());
    }
    base.add(const SettingsScreen());
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cart = context.watch<CartProvider>();

    if (!auth.isSuperAdmin && !auth.hasActiveSubscription) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: AppTheme.warning),
              const SizedBox(height: 16),
              Text('No Active Plan', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Please purchase a plan to access the POS system.'),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const PlansScreen()),
                ),
                icon: const Icon(Icons.shopping_cart),
                label: const Text('View Plans'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14)),
              ),
            ],
          ),
        ),
      );
    }

    final isWide = MediaQuery.of(context).size.width >= 600;
    final isAdmin = auth.isAdmin;
    final pages = _pages(isAdmin);
    final _navDestinations = _buildNavDestinations(isAdmin);

    return Scaffold(
      appBar: AppBar(
        title: const Text('BluexSofts POS'),
        actions: [
          if (auth.shop != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Chip(label: Text(auth.shop!.shopName)),
            ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                ),
              ),
              if (cart.itemCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppTheme.error, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      '${cart.itemCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: isWide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (i) => setState(() => _selectedIndex = i),
                  labelType: NavigationRailLabelType.all,
                  destinations: _navDestinations.map((d) => NavigationRailDestination(icon: Icon(d.icon), label: Text(d.label))).toList(),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: pages[_selectedIndex]),
              ],
            )
          : pages[_selectedIndex],
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) => setState(() => _selectedIndex = i),
              destinations: _navDestinations.map((d) => NavigationDestination(icon: Icon(d.icon), label: d.label)).toList(),
            ),
    );
  }

  List<_NavItem> _buildNavDestinations(bool isAdmin) {
    final items = <_NavItem>[
      _NavItem(Icons.dashboard, 'Home'),
      _NavItem(Icons.point_of_sale, 'POS'),
      _NavItem(Icons.inventory_2, 'Products'),
      _NavItem(Icons.receipt_long, 'Sales'),
      _NavItem(Icons.receipt, 'Invoices'),
    ];
    if (isAdmin) {
      items.add(_NavItem(Icons.people, 'Staff'));
    }
    items.add(_NavItem(Icons.settings, 'Settings'));
    return items;
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

class _DashboardHome extends StatefulWidget {
  const _DashboardHome();

  @override
  State<_DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<_DashboardHome> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<SaleProvider>().loadSummary());
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final saleProv = context.watch<SaleProvider>();
    final summary = saleProv.summary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hello, ${auth.user?.name ?? ''}', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildSummaryCards(summary),
          const SizedBox(height: 16),
          _DashboardChart(),
          const SizedBox(height: 24),
          Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ActionCard(
                icon: Icons.point_of_sale,
                label: 'New Sale',
                color: AppTheme.primary,
                onTap: () {
                  final parent = context.findAncestorStateOfType<_DashboardScreenState>()!;
                  parent.setState(() => parent._selectedIndex = 1);
                },
              ),
              ActionCard(
                icon: Icons.inventory_2,
                label: 'Add Product',
                color: AppTheme.success,
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProductsScreen()));
                },
              ),
              ActionCard(
                icon: Icons.receipt_long,
                label: 'View Sales',
                color: AppTheme.accent,
                onTap: () {
                  final parent = context.findAncestorStateOfType<_DashboardScreenState>()!;
                  parent.setState(() => parent._selectedIndex = 3);
                },
              ),
              ActionCard(
                icon: Icons.receipt,
                label: 'Invoices',
                color: Colors.cyan,
                onTap: () {
                  final parent = context.findAncestorStateOfType<_DashboardScreenState>()!;
                  parent.setState(() => parent._selectedIndex = 4);
                },
              ),
              ActionCard(
                icon: Icons.logout,
                label: 'Logout',
                color: AppTheme.error,
                onTap: () async {
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic>? summary) {
    final today = summary?['today'] ?? {};
    final allTime = summary?['allTime'] ?? {};
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 600) {
          return Row(
            children: [
              Expanded(
                child: SummaryCard(
                  title: 'Today Sales',
                  value: CurrencyFormatter.format(today['total'] ?? 0),
                  subtitle: '${today['count'] ?? 0} transactions',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SummaryCard(
                  title: 'All Time',
                  value: CurrencyFormatter.format(allTime['total'] ?? 0),
                  subtitle: '${allTime['count'] ?? 0} transactions',
                ),
              ),
            ],
          );
        }
        return Column(
          children: [
            SummaryCard(
              title: 'Today Sales',
              value: CurrencyFormatter.format(today['total'] ?? 0),
              subtitle: '${today['count'] ?? 0} transactions',
            ),
            const SizedBox(height: 12),
            SummaryCard(
              title: 'All Time',
              value: CurrencyFormatter.format(allTime['total'] ?? 0),
              subtitle: '${allTime['count'] ?? 0} transactions',
            ),
          ],
        );
      },
    );
  }
}

class _DashboardChart extends StatefulWidget {
  @override
  State<_DashboardChart> createState() => _DashboardChartState();
}

class _DashboardChartState extends State<_DashboardChart> {
  Map<String, double> _chartData = {};

  @override
  void initState() {
    super.initState();
    _loadChartData();
  }

  Future<void> _loadChartData() async {
    await context.read<SaleProvider>().loadSummary();
    if (!mounted) return;
    final summary = context.read<SaleProvider>().summary;
    if (summary != null && summary['dailySales'] != null) {
      final raw = summary['dailySales'] as Map<String, dynamic>;
      setState(() {
        _chartData = raw.map((k, v) => MapEntry(k, (v as num).toDouble()));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SalesChart(dailySales: _chartData);
  }
}
