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
        body: Container(
          decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.lock_outline, size: 40, color: AppTheme.warning),
                ),
                const SizedBox(height: 20),
                Text(
                  'No Active Plan',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please purchase a plan to access the POS system.',
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const PlansScreen()),
                  ),
                  icon: const Icon(Icons.shopping_cart),
                  label: const Text('View Plans'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isWide = MediaQuery.of(context).size.width >= 600;
    final isAdmin = auth.isAdmin;
    final pages = _pages(isAdmin);
    final navDestinations = _buildNavDestinations(isAdmin);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.point_of_sale, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text('BluexSofts POS'),
          ],
        ),
        actions: [
          if (auth.shop != null)
            Container(
              margin: const EdgeInsets.only(right: 4),
              child: Chip(
                avatar: const Icon(Icons.store, size: 16, color: AppTheme.primary),
                label: Text(auth.shop!.shopName, style: const TextStyle(fontSize: 12)),
                backgroundColor: AppTheme.primary.withOpacity(0.15),
                side: BorderSide.none,
              ),
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
                    decoration: const BoxDecoration(
                      gradient: AppTheme.accentGradient,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                    child: Text(
                      '${cart.itemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
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
                _buildSidebar(navDestinations, isWide),
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
              destinations: navDestinations
                  .map((d) => NavigationDestination(icon: Icon(d.icon, size: 20), label: d.label))
                  .toList(),
              animationDuration: const Duration(milliseconds: 300),
            ),
    );
  }

  Widget _buildSidebar(List<_NavItem> items, bool isWide) {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        border: Border(
          right: BorderSide(color: AppTheme.darkBorder.withOpacity(0.5)),
        ),
      ),
      child: NavigationRail(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        labelType: NavigationRailLabelType.all,
        groupAlignment: -1.0,
        minExtendedWidth: 80,
        destinations: items
            .map((d) => NavigationRailDestination(
                  icon: Icon(d.icon, size: 22),
                  selectedIcon: Icon(d.icon, size: 22, color: AppTheme.accent),
                  label: Text(
                    d.label,
                    style: const TextStyle(fontSize: 11),
                  ),
                ))
            .toList(),
        indicatorColor: AppTheme.accent.withOpacity(0.15),
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
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    (auth.user?.name ?? 'U').substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${auth.user?.name ?? ''}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Welcome back to your dashboard',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSummaryCards(summary),
          const SizedBox(height: 16),
          const _DashboardChart(),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
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
                color: AppTheme.info,
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
                  gradient: AppTheme.cardGradientBlue,
                  icon: Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SummaryCard(
                  title: 'All Time Sales',
                  value: CurrencyFormatter.format(allTime['total'] ?? 0),
                  subtitle: '${allTime['count'] ?? 0} transactions',
                  gradient: AppTheme.cardGradientPurple,
                  icon: Icons.attach_money,
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
              gradient: AppTheme.cardGradientBlue,
              icon: Icons.trending_up,
            ),
            const SizedBox(height: 12),
            SummaryCard(
              title: 'All Time Sales',
              value: CurrencyFormatter.format(allTime['total'] ?? 0),
              subtitle: '${allTime['count'] ?? 0} transactions',
              gradient: AppTheme.cardGradientPurple,
              icon: Icons.attach_money,
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
