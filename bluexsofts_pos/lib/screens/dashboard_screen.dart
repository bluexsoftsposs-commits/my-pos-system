import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sale.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/sale_provider.dart';
import '../providers/product_provider.dart';
import '../providers/ledger_provider.dart';
import '../providers/online_order_provider.dart';
import '../providers/connectivity_provider.dart';
import '../core/theme.dart';
import '../core/currency_formatter.dart';
import '../views/shared/sales_chart.dart';
import '../services/receipt_service.dart';
import 'pos_screen.dart';
import 'cart_screen.dart';
import 'products_screen.dart';
import 'sales_screen.dart';
import 'invoices_screen.dart';
import 'users_screen.dart';
import 'ledger_screen.dart';
import 'low_stock_screen.dart';
import 'branch_report_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'online_orders_screen.dart';
import 'plans_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Widget> _pages(bool isAdmin) {
    return [
      const _DashboardHome(),
      const POSScreen(),
      const ProductsScreen(),
      const SalesScreen(),
      const InvoicesScreen(),
      const LedgerScreen(),
      if (isAdmin) const UsersScreen(),
      const OnlineOrdersScreen(),
      const SettingsScreen(),
      const ReportsScreen(),
      const BranchReportScreen(),
      const LowStockScreen(),
    ];
  }

  void _selectPage(int index) {
    setState(() => _selectedIndex = index);
  }

  void goToPage(int index) {
    _selectPage(index);
  }

  void _openPlans() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PlansScreen()));
  }

  void _onItemTapped(int idx) {
    if (idx == -1) {
      _openPlans();
    } else {
      _selectPage(idx);
    }
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
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                  child: const Icon(Icons.lock_outline, size: 40, color: AppTheme.warning),
                ),
                const SizedBox(height: 20),
                Text('No Active Plan', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Text('Please purchase a plan to access the POS system.', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const PlansScreen())),
                  icon: const Icon(Icons.shopping_cart),
                  label: const Text('View Plans'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final isAdmin = auth.isAdmin;
    final pages = _pages(isAdmin);

    final onlineOrdersIndex = isAdmin ? 7 : 6;
    final settingsIndex = isAdmin ? 8 : 7;
    final reportsIndex = isAdmin ? 9 : 8;
    final branchIndex = isAdmin ? 10 : 9;
    final lowStockIndex = isAdmin ? 11 : 10;

    final sidebarItems = <_SidebarItem>[
      _SidebarItem(Icons.home, 'Home', 0),
      _SidebarItem(Icons.point_of_sale, 'POS', 1),
      _SidebarItem(Icons.inventory_2, 'Products', 2),
      _SidebarItem(Icons.payments, 'Sales', 3),
      _SidebarItem(Icons.description, 'Invoices', 4),
      _SidebarItem(Icons.account_balance, 'Ledger', 5),
      if (isAdmin) _SidebarItem(Icons.group, 'Users', 6),
      _SidebarItem(Icons.storefront, 'Online Orders', onlineOrdersIndex),
      _SidebarItem(Icons.bar_chart, 'Reports', reportsIndex),
      _SidebarItem(Icons.store, 'Branches', branchIndex),
      _SidebarItem(Icons.warning_amber, 'Low Stock', lowStockIndex),
      _SidebarItem(Icons.subscriptions, 'Plans', -1),
      _SidebarItem(Icons.settings, 'Settings', settingsIndex),
    ];

    final mainItems = sidebarItems.take(4).toList();
    final drawerItems = sidebarItems.skip(4).toList();
    final clampedIndex = _selectedIndex.clamp(0, pages.length - 1);
    final navSelectedIndex = _selectedIndex.clamp(0, mainItems.length - 1);
    if (clampedIndex != _selectedIndex) {
      _selectedIndex = clampedIndex;
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: isDesktop
          ? null
          : Drawer(
              backgroundColor: AppTheme.darkCard,
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('BluexSofts POS',
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold, color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Navigation',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          ...drawerItems.map((item) {
                            final isActive = item.pageIndex >= 0 && item.pageIndex == _selectedIndex;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: isActive ? Colors.white.withValues(alpha: 0.06) : null,
                                border: isActive
                                    ? const Border(right: BorderSide(color: AppTheme.primary, width: 4))
                                    : null,
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  _onItemTapped(item.pageIndex);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  child: Row(
                                    children: [
                                      Icon(
                                        item.icon,
                                        size: 22,
                                        color: isActive ? AppTheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(item.label,
                                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                            color: isActive ? AppTheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                      if (item.label == 'Online Orders') ...[
                                        Consumer<OnlineOrderProvider>(
                                          builder: (_, op, __) {
                                            if (op.pendingCount <= 0) return const SizedBox.shrink();
                                            return Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppTheme.error.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                '${op.pendingCount}',
                                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.error),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                      if (item.label == 'Low Stock') ...[
                                        Consumer<ProductProvider>(
                                          builder: (_, pp, __) {
                                            if (pp.lowStockCount <= 0) return const SizedBox.shrink();
                                            return Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppTheme.warning.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                '${pp.lowStockCount}',
                                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.warning),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                          const Divider(height: 24),
                          // Logout
                          Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                Navigator.of(context).pop();
                                auth.logout();
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                                  (_) => false,
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                child: Row(
                                  children: [
                                    Icon(Icons.logout, size: 22, color: AppTheme.error),
                                    const SizedBox(width: 16),
                                    Text('Logout',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.error),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop)
            _Sidebar(
              items: sidebarItems,
              selectedIndex: _selectedIndex,
              onItemTapped: (idx) {
                if (idx == -1) {
                  _openPlans();
                } else {
                  _selectPage(idx);
                }
              },
              auth: auth,
            ),
          Expanded(
            child: Column(
              children: [
                _TopBar(auth: auth, cart: cart, onMenuTap: isDesktop ? null : () => _scaffoldKey.currentState?.openDrawer()),
                Expanded(child: pages[_selectedIndex]),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              selectedIndex: navSelectedIndex,
              onDestinationSelected: (i) => setState(() => _selectedIndex = mainItems[i].pageIndex),
              destinations: mainItems
                  .map((d) => NavigationDestination(icon: Icon(d.icon, size: 20), label: d.label))
                  .toList(),
              animationDuration: const Duration(milliseconds: 300),
            ),
    );
  }
}

// ── Data class for sidebar items ───────────────────────────────────

class _SidebarItem {
  final IconData icon;
  final String label;
  final int pageIndex;
  const _SidebarItem(this.icon, this.label, this.pageIndex);
}

// ── Sidebar Widget ─────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  final List<_SidebarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;
  final AuthProvider auth;

  const _Sidebar({
    required this.items,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.auth,
  });

  @override
  Widget build(BuildContext context) {
    final userName = auth.user?.name ?? 'Merchant Profile';
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        border: Border(right: BorderSide(color: AppTheme.darkBorder.withValues(alpha: 0.5))),
      ),
      child: Column(
        children: [
          // Logo + Subtitle
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BluexSofts POS',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold, color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Modern Retail Solutions',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: items.map((item) {
                final isActive = item.pageIndex >= 0 && item.pageIndex == selectedIndex;
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: isActive ? Colors.white.withValues(alpha: 0.06) : null,
                    border: isActive
                        ? const Border(right: BorderSide(color: AppTheme.primary, width: 4))
                        : null,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => onItemTapped(item.pageIndex),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            size: 22,
                            color: isActive ? AppTheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(item.label,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                color: isActive ? AppTheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (item.label == 'Online Orders') ...[
                            const SizedBox(width: 8),
                            Consumer<OnlineOrderProvider>(
                              builder: (_, op, __) {
                                if (op.pendingCount <= 0) return const SizedBox.shrink();
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.error.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${op.pendingCount}',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.error),
                                  ),
                                );
                              },
                            ),
                          ],
                          if (item.label == 'Low Stock') ...[
                            const SizedBox(width: 8),
                            Consumer<ProductProvider>(
                              builder: (_, pp, __) {
                                if (pp.lowStockCount <= 0) return const SizedBox.shrink();
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.warning.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${pp.lowStockCount}',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.warning),
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // New Transaction button
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => onItemTapped(1),
                icon: const Icon(Icons.add),
                label: const Text('New Transaction'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 8,
                  shadowColor: AppTheme.primary.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
          // Merchant Profile
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.darkBorder.withValues(alpha: 0.5))),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                  child: Text(
                    _initials(userName),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userName,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text('ADMINISTRATOR',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          letterSpacing: 0.05,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Top Bar Widget ─────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final AuthProvider auth;
  final CartProvider cart;
  final VoidCallback? onMenuTap;

  const _TopBar({required this.auth, required this.cart, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final userName = auth.user?.name ?? 'Profile';
    final connectivity = context.watch<ConnectivityProvider>();
    final saleProv = context.watch<SaleProvider>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!connectivity.isOnline)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: AppTheme.warning.withValues(alpha: 0.15),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off, size: 14, color: AppTheme.warning),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Offline — changes will sync when back online',
                    style: TextStyle(fontSize: 12, color: AppTheme.warning),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        if (saleProv.isSyncing)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: AppTheme.primary.withValues(alpha: 0.12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14, height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Syncing offline changes...',
                    style: TextStyle(fontSize: 12, color: AppTheme.primary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 40 : 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.darkBg.withValues(alpha: 0.8),
            border: Border(bottom: BorderSide(color: AppTheme.darkBorder.withValues(alpha: 0.3))),
          ),
          child: Row(
            children: [
          if (!isDesktop)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: onMenuTap,
              tooltip: 'Open navigation menu',
            ),
          if (isDesktop) ...[
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 280,
                    child: TextField(
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Search orders, products...',
                        hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else
            Text('BluexSofts POS',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primary),
            ),
          const Spacer(),
          PopupMenuButton<String>(
            icon: Icon(Icons.notifications, color: Theme.of(context).colorScheme.onSurfaceVariant),
            color: AppTheme.darkSurface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            onSelected: (_) {},
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: SizedBox(
                  width: 250,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                      const SizedBox(height: 8),
                      Text('No new notifications', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.storefront, color: Theme.of(context).colorScheme.onSurfaceVariant),
            onPressed: () {
              final parent = context.findAncestorStateOfType<_DashboardScreenState>()!;
              final idx = auth.isAdmin ? 8 : 7;
              parent.goToPage(idx);
            },
          ),
          if (isDesktop) ...[
            Container(width: 1, height: 24, color: AppTheme.darkBorder.withValues(alpha: 0.5)),
            const SizedBox(width: 8),
          ],
          PopupMenuButton<String>(
            color: AppTheme.darkSurface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            offset: const Offset(0, 40),
            onSelected: (value) {
              if (value == 'settings') {
                final parent = context.findAncestorStateOfType<_DashboardScreenState>()!;
                final idx = auth.isAdmin ? 8 : 7;
                parent.goToPage(idx);
              } else if (value == 'logout') {
                auth.logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isDesktop) ...[
                  Text('Profile',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                  child: Text(
                    _initials(userName),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary),
                  ),
                ),
              ],
            ),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'settings', child: ListTile(leading: const Icon(Icons.settings, size: 18), title: const Text('Settings', style: TextStyle(fontSize: 13)), dense: true, contentPadding: EdgeInsets.zero)),
              PopupMenuItem(value: 'logout', child: ListTile(leading: const Icon(Icons.logout, size: 18), title: const Text('Logout', style: TextStyle(fontSize: 13)), dense: true, contentPadding: EdgeInsets.zero)),
            ],
          ),
          if (!isDesktop && cart.itemCount > 0)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CartScreen())),
                ),
                Positioned(
                  right: 6, top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(gradient: AppTheme.accentGradient, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text('${cart.itemCount}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                ),
              ],
            ),
        ],
      ),
      ),
      ],
    );
  }
}

// ── Helper functions ─────────────────────────────────────────────

String _timeBasedGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

String _timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${date.month}/${date.day}';
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  return name.isNotEmpty ? name[0].toUpperCase() : '?';
}

// ── Dashboard Home ───────────────────────────────────────────────

class _DashboardHome extends StatefulWidget {
  const _DashboardHome();

  @override
  State<_DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<_DashboardHome> {
  static const _cardRadius = 12.0;
  DateTimeRange? _dateRange;

  String? _dateRangeLabel;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    Future.microtask(() {
      final saleProv = context.read<SaleProvider>();
      if (_dateRange != null) {
        final from = _dateRange!.start.toIso8601String().split('T')[0];
        final to = _dateRange!.end.toIso8601String().split('T')[0];
        saleProv.loadSummary(from: from, to: to);
      } else {
        saleProv.loadSummary();
      }
      saleProv.loadSales();
      context.read<ProductProvider>().loadProducts();
      context.read<ProductProvider>().loadLowStock();
      context.read<LedgerProvider>().loadOutstanding();
    });
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _dateRange ?? DateTimeRange(start: now.subtract(const Duration(days: 1)), end: now),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppTheme.primary,
            surface: AppTheme.darkSurface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _dateRange = picked;
        final diff = picked.end.difference(picked.start).inDays;
        if (diff == 0) {
          _dateRangeLabel = 'Today';
        } else if (diff == 1) {
          _dateRangeLabel = 'Last 24 Hours';
        } else if (diff <= 7) {
          _dateRangeLabel = 'Last 7 Days';
        } else if (diff <= 30) {
          _dateRangeLabel = 'Last 30 Days';
        } else {
          _dateRangeLabel = 'Custom Range';
        }
      });
      _loadData();
    }
  }

  void _showSaleDetail(BuildContext context, Sale sale) {
    final statusLabel = sale.status == 'COMPLETED' ? 'Paid' : sale.status;
    final shopName = context.read<AuthProvider>().shop?.shopName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          final items = sale.saleItems;
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Sale #${sale.id.substring(0, 6)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.print, color: AppTheme.primary), onPressed: () => ReceiptService.printReceipt(sale, shopName: shopName)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _detailRow('Date', _formatDate(sale.createdAt)),
              _detailRow('Payment', sale.paymentMethod),
              _detailRow('Status', statusLabel),
              if (sale.notes.isNotEmpty) _detailRow('Notes', sale.notes),
              const Divider(height: 32),
              Text('Items (${items.length})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(item.product?['name']?.toString() ?? 'Item', style: const TextStyle(fontSize: 13))),
                    Text('x${item.quantity}', style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 16),
                    Text(CurrencyFormatter.format(item.price), style: const TextStyle(fontSize: 13)),
                  ],
                ),
              )),
              const Divider(height: 32),
              _detailRow('Subtotal', CurrencyFormatter.format(sale.subtotal)),
              if (sale.tax > 0) _detailRow('Tax', CurrencyFormatter.format(sale.tax)),
              if (sale.discount > 0) _detailRow('Discount', '-${CurrencyFormatter.format(sale.discount)}'),
              _detailRow('Total', CurrencyFormatter.format(sale.total), bold: true),
            ],
          );
        },
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final saleProv = context.watch<SaleProvider>();
    final productProv = context.watch<ProductProvider>();
    final summary = saleProv.summary;
    final recentSales = saleProv.sales.take(5).toList();
    final topProducts = productProv.products.take(3).toList();
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final pad = isDesktop ? 40.0 : 16.0;

    final today = summary?['today'] as Map<String, dynamic>? ?? {};
    final allTime = summary?['allTime'] as Map<String, dynamic>? ?? {};

    final todayTotal = (today['total'] as num?)?.toDouble() ?? 0;
    final todayCount = (today['count'] as num?)?.toInt() ?? 0;
    final allTimeTotal = (allTime['total'] as num?)?.toDouble() ?? 0;
    final allTimeCount = (allTime['count'] as num?)?.toInt() ?? 0;
    final avgTicket = allTimeCount > 0 ? allTimeTotal / allTimeCount : 0.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          _buildHeader(isDesktop),
          const SizedBox(height: 32),

          // Stat cards
          _buildStatGrid(isDesktop, todayTotal, todayCount, allTimeTotal, avgTicket, summary),
          const SizedBox(height: 32),

          // Analytics row (chart + popular products)
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: _buildChartCard(true)),
                const SizedBox(width: 24),
                Expanded(flex: 3, child: _PopularProductsCard(
                  products: topProducts,
                  onViewInventory: () {
                    final parent = context.findAncestorStateOfType<_DashboardScreenState>()!;
                    parent.setState(() => parent._selectedIndex = 2);
                  },
                )),
              ],
            )
          else ...[
            _buildChartCard(false),
            const SizedBox(height: 32),
            _PopularProductsCard(
              products: topProducts,
              onViewInventory: () {
                final parent = context.findAncestorStateOfType<_DashboardScreenState>()!;
                parent.setState(() => parent._selectedIndex = 2);
              },
            ),
          ],
          const SizedBox(height: 32),

          // Recent Transactions
          _buildRecentTransactions(recentSales, isDesktop),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDesktop) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isDesktop) ...[
              Text('${_timeBasedGreeting()}, Store #024',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
            ],
            Text('Dashboard Overview',
              style: isDesktop
                  ? Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w600)
                  : Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (isDesktop) ...[
              const SizedBox(height: 4),
              Text('Welcome back. Here\'s what\'s happening today.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _selectDateRange,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(_dateRangeLabel ?? 'Last 24 Hours',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Stat Cards ──────────────────────────────────────────────────

  Widget _buildStatGrid(bool isDesktop, double todayTotal, int todayCount, double allTimeTotal, double avgTicket, Map<String, dynamic>? summary) {
    final products = context.watch<ProductProvider>().products;
    final lowStockCount = products.where((p) => p.stock <= p.lowStockThreshold).length;

    final dailySales = summary?['dailySales'] as Map<String, dynamic>? ?? {};
    final dailyEntries = dailySales.entries.map((e) => MapEntry(e.key, (e.value as num).toDouble())).toList();
    dailyEntries.sort((a, b) => a.key.compareTo(b.key));

    String formatPct(double? pct) {
      if (pct == null) return 'N/A';
      final sign = pct >= 0 ? '+' : '';
      return '$sign${pct.toStringAsFixed(1)}%';
    }
    Color pctColor(double? pct) => pct != null && pct >= 0 ? AppTheme.success : AppTheme.error;
    double? calcChange() {
      if (dailyEntries.length < 2) return null;
      final prev = dailyEntries[dailyEntries.length - 2].value;
      final curr = dailyEntries.last.value;
      if (prev == 0) return curr > 0 ? 100.0 : 0.0;
      return ((curr - prev) / prev) * 100;
    }

    final change = calcChange();

    final cards = [
      _StatCardData(Icons.payments, AppTheme.primary, "Today's Sales", CurrencyFormatter.formatWithDecimals(todayTotal), formatPct(change), pctColor(change)),
      _StatCardData(Icons.account_balance_wallet, AppTheme.success, 'Total Revenue', CurrencyFormatter.formatCompact(allTimeTotal), formatPct(change), pctColor(change)),
      _StatCardData(Icons.inventory_2, AppTheme.error, 'Low Stock', '$lowStockCount Items', 'Critical', AppTheme.error),
      _StatCardData(Icons.account_balance, AppTheme.warning, 'Ledger Account', CurrencyFormatter.format(context.read<LedgerProvider>().totalOutstanding), 'Outstanding', AppTheme.warning),
    ];

    if (isDesktop) {
      return Row(
        children: cards.map((c) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: cards.indexOf(c) > 0 ? 24 : 0),
              child: _StatCard(data: c, isDesktop: true),
            ),
          );
        }).toList(),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _StatCard(data: cards[0], isDesktop: false)),
            const SizedBox(width: 16),
            Expanded(child: _StatCard(data: cards[1], isDesktop: false)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _StatCard(data: cards[2], isDesktop: false)),
            const SizedBox(width: 16),
            Expanded(child: _StatCard(data: cards[3], isDesktop: false)),
          ],
        ),
      ],
    );
  }

  // ── Chart Card ──────────────────────────────────────────────────

  Widget _buildChartCard(bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isDesktop ? 'Sales Performance' : 'Weekly Revenue',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (isDesktop) ...[
                    const SizedBox(height: 2),
                    Text('Real-time revenue tracking over 24 hours',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
              if (isDesktop)
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('Revenue',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: const _DashboardChart(),
          ),
          if (isDesktop)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['08:00 AM', '12:00 PM', '04:00 PM', '08:00 PM', '12:00 AM']
                    .map((t) => Text(t, style: const TextStyle(fontSize: 10, color: Colors.grey)))
                    .toList(),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']
                    .map((d) => Text(d, style: const TextStyle(fontSize: 10, color: Colors.grey)))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  // ── Recent Transactions ─────────────────────────────────────────

  Widget _buildRecentTransactions(List<dynamic> sales, bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Transactions',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    final parent = context.findAncestorStateOfType<_DashboardScreenState>()!;
                    parent.setState(() => parent._selectedIndex = 3);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('View All',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppTheme.primary),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward, size: 14, color: AppTheme.primary),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isDesktop)
            _buildSalesTable(sales)
          else
            _buildSalesCardList(sales),
        ],
      ),
    );
  }

  Widget _buildSalesTable(List<dynamic> sales) {
    if (sales.isEmpty) return _buildEmptyState();
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppTheme.darkCard.withValues(alpha: 0.5)),
          horizontalMargin: 24,
          columnSpacing: 48,
          columns: const [
            DataColumn(label: Text('ID', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Customer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Amount', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Action', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), numeric: true),
          ],
          rows: sales.map((s) {
            final name = s.user?['name'] as String? ?? 'Guest';
            final status = (s.status as String?) ?? 'COMPLETED';
            final statusColor = status == 'COMPLETED' ? AppTheme.success : status == 'PENDING' ? AppTheme.warning : AppTheme.error;
            final statusLabel = status == 'COMPLETED' ? 'Paid' : status;
            return DataRow(cells: [
              DataCell(Text('#${s.id.substring(0, 6)}', style: const TextStyle(fontSize: 13))),
              DataCell(
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: (status == 'COMPLETED' ? AppTheme.success : status == 'PENDING' ? AppTheme.warning : AppTheme.error).withValues(alpha: 0.2),
                      child: Text(_initials(name), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor)),
                    ),
                    const SizedBox(width: 8),
                    Text(name, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              DataCell(Text(CurrencyFormatter.format(s.total), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
              DataCell(_buildStatusBadge(statusLabel, statusColor)),
              DataCell(
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                  color: AppTheme.darkSurface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onSelected: (value) {
                    if (value == 'details') {
                      _showSaleDetail(context, s);
                    } else if (value == 'print') {
                      final shopName = context.read<AuthProvider>().shop?.shopName;
                      ReceiptService.printReceipt(s, shopName: shopName);
                    } else if (value == 'share') {
                      final shopName = context.read<AuthProvider>().shop?.shopName;
                      ReceiptService.shareReceipt(s, shopName: shopName);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'details', child: ListTile(leading: Icon(Icons.visibility, size: 18), title: Text('View Details', style: TextStyle(fontSize: 13)), dense: true, contentPadding: EdgeInsets.zero)),
                    const PopupMenuItem(value: 'print', child: ListTile(leading: Icon(Icons.print, size: 18), title: Text('Print Receipt', style: TextStyle(fontSize: 13)), dense: true, contentPadding: EdgeInsets.zero)),
                    const PopupMenuItem(value: 'share', child: ListTile(leading: Icon(Icons.share, size: 18), title: Text('Share Receipt', style: TextStyle(fontSize: 13)), dense: true, contentPadding: EdgeInsets.zero)),
                  ],
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSalesCardList(List<dynamic> sales) {
    if (sales.isEmpty) return _buildEmptyState();
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: sales.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final s = sales[i];
        final name = s.user?['name'] as String? ?? 'Guest';
        final status = (s.status as String?) ?? 'COMPLETED';
        final statusColor = status == 'COMPLETED' ? AppTheme.success : status == 'PENDING' ? AppTheme.warning : AppTheme.error;
        final paymentMethod = (s.paymentMethod as String?) ?? 'CASH';
        final timeAgo = _timeAgo(s.createdAt as DateTime);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.darkSurface,
            borderRadius: BorderRadius.circular(_cardRadius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.darkSurface,
                child: Text(_initials(name), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primary)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('$timeAgo \u2022 $paymentMethod',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(CurrencyFormatter.format(s.total), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  _buildStatusBadge(status == 'COMPLETED' ? 'Paid' : status, statusColor),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.03),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.receipt_long, size: 40, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 8),
          Text('No recent sales', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ── Stat Card Data Class ───────────────────────────────────────────

class _StatCardData {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String badgeText;
  final Color badgeColor;
  const _StatCardData(this.icon, this.iconColor, this.label, this.value, this.badgeText, this.badgeColor);
}

// ── Stat Card Widget ──────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final _StatCardData data;
  final bool isDesktop;

  const _StatCard({required this.data, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: data.iconColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(data.icon, size: 24, color: data.iconColor),
              ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: data.badgeColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(data.badgeText,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: data.badgeColor, letterSpacing: 0.03),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(data.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 0.05,
            ),
          ),
          const SizedBox(height: 4),
          Text(data.value,
            style: isDesktop
                ? const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)
                : Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// ── Popular Products Card ─────────────────────────────────────────

class _PopularProductsCard extends StatelessWidget {
  final List<dynamic> products;
  final VoidCallback? onViewInventory;

  const _PopularProductsCard({required this.products, this.onViewInventory});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Popular Products',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          if (products.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('No products', style: TextStyle(color: Colors.grey, fontSize: 13))),
            )
          else
            ...products.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: p.imageUrl != null && p.imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(p.imageUrl, fit: BoxFit.cover),
                          )
                        : const Icon(Icons.inventory_2, size: 20, color: Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name ?? 'Product',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text('${p.category ?? 'General'} \u2022 ${p.stock} sold',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(CurrencyFormatter.format(p.price),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.primary),
                  ),
                ],
              ),
            )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onViewInventory,
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                side: BorderSide(color: AppTheme.darkBorder.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('View Inventory'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chart Widget ──────────────────────────────────────────────────

class _DashboardChart extends StatefulWidget {
  const _DashboardChart();

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
    final saleProv = context.read<SaleProvider>();
    await saleProv.loadSummary();
    if (!mounted) return;
    final summary = saleProv.summary;
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
