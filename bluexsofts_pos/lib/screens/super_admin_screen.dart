import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/admin_service.dart';
import '../core/theme.dart';
import '../views/shared/stat_card.dart';
import '../core/currency_formatter.dart';
import 'login_screen.dart';
import 'admin/plans_management_screen.dart';

IconData _categoryIcon(String cat) {
  switch (cat) {
    case 'Grocery': return Icons.shopping_basket;
    case 'Electronics': return Icons.electrical_services;
    case 'Restaurant': return Icons.restaurant;
    case 'Pharmacy': return Icons.medication;
    case 'Clothing': return Icons.checkroom;
    case 'General': return Icons.store;
    default: return Icons.storefront;
  }
}

const _categories = ['Grocery', 'Electronics', 'Restaurant', 'Pharmacy', 'Clothing', 'General', 'Other'];
const _plans = ['NONE', 'Lite', 'Plus', 'Pro', 'BASIC', 'STANDARD', 'PREMIUM'];
const _extendOptions = [30, 60, 90];

class SuperAdminScreen extends StatefulWidget {
  const SuperAdminScreen({super.key});

  @override
  State<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends State<SuperAdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  Map<String, dynamic>? _stats;
  List<dynamic> _shops = [];
  bool _loading = true;
  final _adminService = AdminService();
  String _searchQuery = '';

  List<dynamic> get _filteredShops {
    if (_searchQuery.isEmpty) return _shops;
    final q = _searchQuery.toLowerCase();
    final result = <dynamic>[];
    for (final s in _shops) {
      if (s is Map<String, dynamic>) {
        final name = (s['shopName'] as String? ?? '').toLowerCase();
        final plan = (s['subscriptionPlan'] as String? ?? '').toLowerCase();
        final cat = (s['category'] as String? ?? '').toLowerCase();
        if (name.contains(q) || plan.contains(q) || cat.contains(q)) {
          result.add(s);
        }
      }
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final statsData = await _adminService.getStats();
      if (statsData != null) _stats = statsData;

      final shopsData = await _adminService.getShops();
      if (shopsData != null) _shops = shopsData['shops'] ?? [];

    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

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
              child: const Icon(Icons.admin_panel_settings, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text('Super Admin'),
          ],
        ),
        actions: [
          Container(
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.subscriptions, size: 20),
              tooltip: 'Manage Plans & Subscriptions',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PlansManagementScreen()),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          ),
          const SizedBox(width: 4),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFD63031).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout, color: Color(0xFFD63031)),
              onPressed: () async {
                await auth.logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: const Color(0xFFC6BFFF),
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey[500],
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Shops'),
            Tab(text: 'Admins'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth > 800 ? 800.0 : double.infinity;
                return Center(
                  child: SizedBox(
                    width: maxWidth,
                    child: TabBarView(
                      controller: _tabCtrl,
                      children: [
                        _buildDashboardTab(),
                        _buildShopsTab(),
                        _buildAdminsTab(),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildDashboardTab() {
    if (_stats == null) return const Center(child: Text('No data'));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
              'Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StatCard(
          title: 'Total Shops',
          value: '${_stats!['totalShops']}',
          icon: Icons.store,
          color: AppTheme.primary,
          gradient: AppTheme.cardGradientBlue,
        ),
        StatCard(
          title: 'Active Shops',
          value: '${_stats!['activeShops']}',
          icon: Icons.check_circle,
          color: AppTheme.success,
          gradient: AppTheme.cardGradientGreen,
        ),
        StatCard(
          title: 'Total Users',
          value: '${_stats!['totalUsers']}',
          icon: Icons.people,
          color: AppTheme.info,
          gradient: const LinearGradient(
            colors: [Color(0xFF0891B2), Color(0xFF0E7490)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        StatCard(
          title: 'Admins',
          value: '${_stats!['totalAdmins']}',
          icon: Icons.admin_panel_settings,
          color: AppTheme.accent,
          gradient: AppTheme.cardGradientPurple,
        ),
        StatCard(
          title: 'Cashiers',
          value: '${_stats!['totalCashiers']}',
          icon: Icons.person,
          color: AppTheme.warning,
          gradient: const LinearGradient(
            colors: [Color(0xFFD97706), Color(0xFFB45309)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        StatCard(
          title: 'Total Sales',
          value: '${_stats!['totalSales']}',
          icon: Icons.receipt_long,
          color: Colors.cyan,
          gradient: const LinearGradient(
            colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        StatCard(
          title: 'Total Revenue',
          value: CurrencyFormatter.formatWithDecimals((_stats!['totalRevenue'] as num)),
          icon: Icons.attach_money,
          color: AppTheme.success,
          gradient: AppTheme.cardGradientGreen,
        ),
        const SizedBox(height: 20),
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
              'Plans Breakdown',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...(_stats!['planBreakdown'] as List).map((p) {
          final planName = '${p['plan'] ?? 'Unknown'}';
          final planCount = '${p['count'] ?? 0}';
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF201F1F),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C5CE7).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.subscriptions, color: Color(0xFF6C5CE7)),
              ),
              title: Text(planName, style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C5CE7).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$planCount shops',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6C5CE7)),
                ),
              ),
            ),
          );
        }),
        if (_buildAdminSummary().isNotEmpty) ...[
          const SizedBox(height: 20),
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
                'Admins Summary',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._buildAdminSummary(),
        ],
      ],
    );
  }

  List<Widget> _buildAdminSummary() {
    final adminMap = <String, Map<String, dynamic>>{};
    for (final s in _shops) {
      if (s is! Map<String, dynamic>) continue;
      final users = s['users'] as List? ?? [];
      if (users.isEmpty) continue;
      final admin = users.first as Map<String, dynamic>;
      final email = admin['email'] as String? ?? '';
      final name = admin['name'] as String? ?? 'Unknown';
      if (email.isEmpty) continue;

      if (!adminMap.containsKey(email)) {
        adminMap[email] = {
          'name': name,
          'email': email,
          'shopCount': 0,
          'totalUsers': 0,
          'totalSales': 0,
          'totalRevenue': 0.0,
          'shops': <String>[],
        };
      }
      final entry = adminMap[email]!;
      entry['shopCount'] = (entry['shopCount'] as int) + 1;
      entry['totalUsers'] = (entry['totalUsers'] as int) + ((s['_count'] is Map ? (s['_count'] as Map)['users'] as int? ?? 0 : 0));
      entry['totalSales'] = (entry['totalSales'] as int) + ((s['_count'] is Map ? (s['_count'] as Map)['sales'] as int? ?? 0 : 0));
      entry['totalRevenue'] = (entry['totalRevenue'] as num) + (s['totalRevenue'] as num? ?? 0);
      (entry['shops'] as List<String>).add(s['shopName'] as String? ?? '');
    }

    return adminMap.entries.map((e) {
      final a = e.value;
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF201F1F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppTheme.accentGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${a['name']}'.substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${a['name']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        Text('${a['email']}', style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _summaryStat('${a['shopCount']}', 'Shops'),
                  _summaryStat('${a['totalUsers']}', 'Users'),
                  _summaryStat('${a['totalSales']}', 'Sales'),
                  if ((a['totalRevenue'] as num) > 0)
                    _summaryStat(CurrencyFormatter.format(a['totalRevenue'] as num), 'Revenue'),
                ],
              ),
              if ((a['shops'] as List).isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: (a['shops'] as List<String>).map((s) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C5CE7).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(s, style: const TextStyle(fontSize: 11, color: Color(0xFFC6BFFF))),
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _summaryStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
        ],
      ),
    );
  }

  Widget _buildShopsTab() {
    int activeCount = 0;
    for (final s in _shops) {
      if (s is Map<String, dynamic> && s['subscriptionStatus'] == 'ACTIVE' && s['isActive'] != false) {
        activeCount++;
      }
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Manage Shops',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C5CE7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add_business, color: Colors.white),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '$activeCount Active Merchants',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search shops...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: const Color(0xFF201F1F),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF474554)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _filteredShops.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.store, size: 64, color: Colors.grey[700]),
                      const SizedBox(height: 12),
                      Text('No shops found', style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final shopCards = _filteredShops.map((item) {
                      if (item is! Map<String, dynamic>) return const SizedBox.shrink();
                      return _buildShopCard(
                        shop: item,
                        onToggle: () async {
                          final id = item['id'] as String?;
                          if (id != null) {
                            await _adminService.toggleShop(id);
                            _loadData();
                          }
                        },
                        onExtend: () async {
                          final id = item['id'] as String?;
                          if (id != null) {
                            final success = await _adminService.extendSubscription(id);
                            if (success) _loadData();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(success ? 'Subscription extended by 30 days' : 'Failed to extend'),
                                  backgroundColor: success ? const Color(0xFF00B894) : const Color(0xFFD63031),
                                ),
                              );
                            }
                          }
                        },
                        onDelete: () => _confirmDeleteShop(item),
                      );
                    }).toList();

                    if (width > 1200) {
                      return GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 1.6,
                        ),
                        itemCount: shopCards.length,
                        itemBuilder: (context, index) => shopCards[index],
                      );
                    }
                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: shopCards,
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _shopPlanName(Map<String, dynamic> shop) {
    final subs = shop['subscriptions'] as List? ?? [];
    if (subs.isNotEmpty) {
      final sub = subs.first as Map<String, dynamic>;
      final subPlan = sub['plan'] as Map<String, dynamic>?;
      if (subPlan != null && subPlan['name'] != null) {
        final bc = subPlan['billingCycle'] as String? ?? '';
        return bc.isNotEmpty ? '${subPlan['name']} ($bc)' : '${subPlan['name']}';
      }
    }
    return shop['subscriptionPlan'] as String? ?? 'No Plan';
  }

  Widget _buildShopCard({
    required Map<String, dynamic> shop,
    required VoidCallback onToggle,
    required VoidCallback onExtend,
    required VoidCallback onDelete,
  }) {
    final plan = _shopPlanName(shop);
    final status = shop['subscriptionStatus'] as String? ?? '';
    final shopName = shop['shopName'] as String? ?? 'Unnamed Shop';
    final category = shop['category'] as String? ?? 'General';
    final isActive = shop['isActive'] as bool? ?? true;
    final salesCount = shop['_count'] is Map ? (shop['_count'] as Map)['sales'] as int? ?? 0 : 0;
    final branchCount = shop['_count'] is Map ? (shop['_count'] as Map)['branches'] as int? ?? 0 : 0;
    final totalRevenue = shop['totalRevenue'] as num? ?? 0;
    final usersList = shop['users'] as List? ?? [];
    final adminUser = usersList.isNotEmpty ? usersList.first as Map<String, dynamic> : null;

    Color statusColor;
    switch (status) {
      case 'ACTIVE':
        statusColor = isActive ? const Color(0xFF00B894) : const Color(0xFFFDCB6E);
        break;
      case 'PENDING':
        statusColor = const Color(0xFFFDCB6E);
        break;
      case 'EXPIRED':
        statusColor = const Color(0xFFD63031);
        break;
      default:
        statusColor = Colors.grey;
    }

    final statusLabel = !isActive && status == 'ACTIVE' ? 'SUSPENDED' : (status.isEmpty ? 'NONE' : '${status[0]}${status.substring(1).toLowerCase()}');
    final isExpired = status == 'EXPIRED';
    final suspended = status == 'ACTIVE' && !isActive;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF201F1F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
            Padding(
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
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(_categoryIcon(category), color: statusColor, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shopName,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$category \u2022 Plan: $plan  \u2022  $salesCount sales',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (adminUser != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.person, size: 12, color: const Color(0xFF6C5CE7)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Managed by ${adminUser['name'] ?? 'Unknown'}',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF6C5CE7)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.white.withOpacity(0.08)),
                        bottom: BorderSide(color: Colors.white.withOpacity(0.08)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                        if (branchCount > 0) ...[
                          const SizedBox(width: 16),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.business, size: 11, color: const Color(0xFF9E9E9E)),
                              const SizedBox(width: 4),
                              Text(
                                '$branchCount branch${branchCount > 1 ? 'es' : ''}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
                              ),
                            ],
                          ),
                        ],
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              isExpired ? 'LAST SETTLEMENT' : 'REVENUE',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                color: Color(0xFF9E9E9E),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              totalRevenue > 0 ? CurrencyFormatter.format(totalRevenue) : '--',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: totalRevenue > 0 ? Colors.white : const Color(0xFF9E9E9E)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  suspended
                      ? _buildSuspendedActions(onToggle, onDelete, shop)
                      : isExpired
                          ? _buildExpiredActions(onExtend, onToggle, onDelete, shop)
                          : _buildActiveActions(onToggle, onExtend, onDelete, shop),
                  if (usersList.length > 1) ...[
                    const SizedBox(height: 8),
                    _buildExpandableUsers(shop, usersList),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveActions(VoidCallback onToggle, VoidCallback onExtend, VoidCallback onDelete, Map<String, dynamic> shop) {
    return Row(
      children: [
        Expanded(child: _actionBtn(label: 'View', icon: Icons.visibility_outlined, onTap: () => _showShopDetails(shop))),
        const SizedBox(width: 8),
        Expanded(child: _actionBtn(label: 'Edit', icon: Icons.edit_outlined, onTap: () => _showEditDialog(shop))),
        const SizedBox(width: 8),
        Expanded(
          child: _actionBtn(
            label: 'Suspend',
            icon: Icons.block,
            color: const Color(0xFFD63031),
            onTap: onToggle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _actionBtn(
            label: 'Delete',
            icon: Icons.delete_forever,
            color: const Color(0xFFD63031),
            onTap: onDelete,
          ),
        ),
      ],
    );
  }

  Widget _buildSuspendedActions(VoidCallback onToggle, VoidCallback onDelete, Map<String, dynamic> shop) {
    return Row(
      children: [
        Expanded(child: _actionBtn(label: 'View', icon: Icons.visibility_outlined, onTap: () => _showShopDetails(shop))),
        const SizedBox(width: 8),
        Expanded(child: _actionBtn(label: 'Edit', icon: Icons.edit_outlined, onTap: () => _showEditDialog(shop))),
        const SizedBox(width: 8),
        Expanded(
          child: _actionBtn(
            label: 'Activate',
            icon: Icons.check_circle,
            color: const Color(0xFF00B894),
            onTap: onToggle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _actionBtn(
            label: 'Delete',
            icon: Icons.delete_forever,
            color: const Color(0xFFD63031),
            onTap: onDelete,
          ),
        ),
      ],
    );
  }

  Widget _buildExpiredActions(VoidCallback onExtend, VoidCallback onToggle, VoidCallback onDelete, Map<String, dynamic> shop) {
    return Row(
      children: [
        Expanded(child: _actionBtn(label: 'View', icon: Icons.visibility_outlined, onTap: () => _showShopDetails(shop))),
        const SizedBox(width: 8),
        Expanded(
          child: _actionBtn(
            label: 'Renew',
            icon: Icons.history,
            color: const Color(0xFF6C5CE7),
            onTap: onExtend,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _actionBtn(
            label: 'Archive',
            icon: Icons.delete_outline,
            color: const Color(0xFFD63031),
            onTap: onToggle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _actionBtn(
            label: 'Delete',
            icon: Icons.delete_forever,
            color: const Color(0xFFD63031),
            onTap: onDelete,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableUsers(Map<String, dynamic> shop, List<dynamic> usersList) {
    final usersCount = shop['_count'] is Map ? (shop['_count'] as Map)['users'] as int? ?? 0 : 0;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6C5CE7).withOpacity(0.15)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        childrenPadding: EdgeInsets.zero,
        leading: Icon(Icons.people, size: 18, color: const Color(0xFF6C5CE7)),
        title: Text(
          '$usersCount User${usersCount == 1 ? '' : 's'}',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
        ),
        children: usersList.map<Widget>((u) {
          if (u is! Map<String, dynamic>) return const SizedBox.shrink();
          final uname = u['name'] as String? ?? 'Unknown';
          final uemail = u['email'] as String? ?? '';
          final urole = u['role'] as String? ?? '';
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C5CE7).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      uname.substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Color(0xFF6C5CE7), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(uname, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white)),
                      Text(uemail, style: const TextStyle(fontSize: 10, color: Color(0xFF9E9E9E))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: urole == 'ADMIN'
                        ? const Color(0xFF6C5CE7).withOpacity(0.15)
                        : const Color(0xFF00B894).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    urole,
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: urole == 'ADMIN' ? const Color(0xFF6C5CE7) : const Color(0xFF00B894)),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _actionBtn({
    required String label,
    required IconData icon,
    Color? color,
    required VoidCallback onTap,
  }) {
    final isDestructive = color == const Color(0xFFD63031);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isDestructive ? const Color(0xFFD63031).withOpacity(0.1) : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color ?? const Color(0xFFE0E0E0)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color ?? const Color(0xFFE0E0E0)),
            ),
          ],
        ),
      ),
    );
  }

  void _showShopDetails(Map<String, dynamic> shop) {
    final shopName = shop['shopName'] as String? ?? 'Shop';
    final subs = shop['subscriptions'] as List? ?? [];
    final activeSub = subs.isNotEmpty ? subs.first as Map<String, dynamic> : null;
    final subPlan = activeSub?['plan'] as Map<String, dynamic>?;
    final planName = subPlan?['name'] as String? ?? shop['subscriptionPlan'] as String? ?? 'NONE';
    final billingCycle = subPlan?['billingCycle'] as String? ?? '';
    final planLabel = billingCycle.isNotEmpty ? '$planName ($billingCycle)' : planName;
    final status = shop['subscriptionStatus'] as String? ?? 'NONE';
    final category = shop['category'] as String? ?? 'General';
    final isActive = shop['isActive'] as bool? ?? true;
    final usersCount = shop['_count'] is Map ? (shop['_count'] as Map)['users'] as int? ?? 0 : 0;
    final salesCount = shop['_count'] is Map ? (shop['_count'] as Map)['sales'] as int? ?? 0 : 0;
    final branchCount = shop['_count'] is Map ? (shop['_count'] as Map)['branches'] as int? ?? 0 : 0;
    final totalRevenue = shop['totalRevenue'] as num? ?? 0;
    final endsAtStr = shop['subscriptionEndsAt'] as String?;
    final daysRemaining = endsAtStr != null && endsAtStr.isNotEmpty
        ? '${(DateTime.parse(endsAtStr).difference(DateTime.now()).inDays).clamp(0, 99999)} days'
        : 'N/A';
    final adminList = shop['users'] as List? ?? [];
    final lastPayment = shop['payments'] as List?;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF201F1F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(_categoryIcon(category), color: const Color(0xFF6C5CE7), size: 24),
            const SizedBox(width: 10),
            Expanded(child: Text(shopName, style: const TextStyle(fontSize: 18))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader('Subscription'),
              _detailRow('Plan', planLabel),
              _detailRow('Status', status),
              _detailRow('Category', category),
              _detailRow('Active', isActive ? 'Yes' : 'No'),
              _detailRow('Days Remaining', daysRemaining),
              const Divider(color: Color(0xFF474554)),
              _sectionHeader('Activity'),
              _detailRowWithIcon(Icons.trending_up, 'Total Sales', '$salesCount'),
              _detailRowWithIcon(Icons.people, 'Total Users', '$usersCount'),
              _detailRowWithIcon(Icons.business, 'Branches', '$branchCount'),
              if (totalRevenue > 0) _detailRowWithIcon(Icons.attach_money, 'Revenue', CurrencyFormatter.format(totalRevenue)),
              if (adminList.isNotEmpty) ...[
                const Divider(color: Color(0xFF474554)),
                _sectionHeader('Admin'),
                for (final a in adminList)
                  if (a is Map<String, dynamic>)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              gradient: AppTheme.accentGradient,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                '${a['name'] ?? '?'}'.substring(0, 1).toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${a['name'] ?? 'Unknown'}', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                              Text('${a['email'] ?? ''}', style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    ),
              ],
              if (lastPayment != null && lastPayment.isNotEmpty) ...[
                const Divider(color: Color(0xFF474554)),
                _sectionHeader('Last Payment'),
                for (final p in lastPayment)
                  if (p is Map<String, dynamic>)
                    _detailRow(
                      '${p['paymentMethod'] ?? 'Unknown'}',
                      'Rs ${p['amount'] ?? 0}',
                    ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: Color(0xFF6C5CE7),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _detailRowWithIcon(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Row(
              children: [
                Icon(icon, size: 16, color: const Color(0xFF9E9E9E)),
                const SizedBox(width: 6),
                Flexible(child: Text(label, style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13))),
              ],
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> shop) {
    final shopId = shop['id'] as String? ?? '';
    final nameCtrl = TextEditingController(text: shop['shopName'] as String? ?? '');
    String selectedCategory = shop['category'] as String? ?? 'General';
    String selectedPlan = shop['subscriptionPlan'] as String? ?? 'NONE';
    String selectedExtend = '30';
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF201F1F),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Edit Shop'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Shop Name',
                    prefixIcon: Icon(Icons.store),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setDialogState(() => selectedCategory = v ?? 'General'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedPlan,
                  decoration: const InputDecoration(
                    labelText: 'Subscription Plan',
                    prefixIcon: Icon(Icons.subscriptions),
                  ),
                  items: _plans.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) => setDialogState(() => selectedPlan = v ?? 'NONE'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedExtend,
                  decoration: const InputDecoration(
                    labelText: 'Extend Subscription',
                    prefixIcon: Icon(Icons.timer),
                  ),
                  items: [
                    const DropdownMenuItem(value: '0', child: Text("Don't extend")),
                    ..._extendOptions.map((d) => DropdownMenuItem(value: '$d', child: Text('+$d days'))),
                  ],
                  onChanged: (v) => setDialogState(() => selectedExtend = v ?? '0'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      setDialogState(() => saving = true);
                      try {
                        final extendDays = int.tryParse(selectedExtend) ?? 0;
                        if (extendDays > 0) {
                          await _adminService.extendSubscription(shopId, days: extendDays);
                        }
                        await _adminService.updateShop(
                          shopId,
                          shopName: nameCtrl.text.trim(),
                          category: selectedCategory,
                        );
                        if (!ctx.mounted) return;
                        Navigator.of(ctx).pop();
                        _loadData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Shop updated'), backgroundColor: Color(0xFF00B894)),
                        );
                      } catch (e) {
                        setDialogState(() => saving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFD63031)),
                          );
                        }
                      }
                    },
              child: saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminsTab() {
    final adminShops = <Map<String, dynamic>>[];
    for (final s in _shops) {
      if (s is Map<String, dynamic>) {
        final users = s['users'] as List?;
        if (users != null && users.isNotEmpty) {
          adminShops.add(s);
        }
      }
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showCreateAdminDialog,
              icon: const Icon(Icons.person_add),
              label: const Text('Create New Admin'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 4,
                shadowColor: const Color(0xFF6C5CE7).withOpacity(0.4),
              ),
            ),
          ),
        ),
        Expanded(
          child: adminShops.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.admin_panel_settings, size: 64, color: Colors.grey[600]),
                      const SizedBox(height: 12),
                      const Text('No admins found', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: adminShops.length,
                  itemBuilder: (context, index) {
                    final shop = adminShops[index];
                    final usersList = shop['users'] as List? ?? [];
                    final admin = usersList.isNotEmpty ? usersList.first as Map<String, dynamic> : <String, dynamic>{};
                    final usersCount = shop['_count'] is Map ? (shop['_count'] as Map)['users'] as int? ?? 0 : 0;
                    final dateStr = admin['createdAt'] as String? ?? '';
                    final date = dateStr.isNotEmpty ? dateStr.split('T')[0] : '';

                    // Find all shops managed by this admin
                    final adminShopsForUser = adminShops
                        .where((s) {
                          final users = s['users'] as List? ?? [];
                          return users.any((u) => u is Map<String, dynamic> && u['email'] == admin['email']);
                        })
                        .map((s) => s['shopName'] as String? ?? '')
                        .where((n) => n.isNotEmpty)
                        .toList();
                    final adminEmail = admin['email'] as String? ?? '';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF201F1F),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.06)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () => _showAdminDetails(adminEmail, adminShops),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.accentGradient,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${admin['name'] ?? '?'}'.substring(0, 1).toUpperCase(),
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
                                            '${admin['name'] ?? 'Unknown'}',
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white),
                                          ),
                                          Text(
                                            '${adminEmail}',
                                            style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _chip(Icons.store, '${shop['shopName'] ?? 'Unknown'}'),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  _chip(Icons.people, '$usersCount users'),
                                  const SizedBox(width: 8),
                                  _chip(Icons.calendar_today, date),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (adminShopsForUser.length > 1)
                                    _chip(Icons.business, '${adminShopsForUser.length} shops'),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () => _confirmDeleteAdmin(admin, adminShopsForUser),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD63031).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.delete_outline, size: 14, color: const Color(0xFFD63031)),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Deactivate',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFFD63031),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF6C5CE7).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF6C5CE7)),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Colors.white)),
        ],
      ),
    );
  }

  void _showAdminDetails(String adminEmail, List<Map<String, dynamic>> adminShops) {
    final admin = adminShops
        .expand((s) => (s['users'] as List? ?? []).cast<Map<String, dynamic>>())
        .firstWhere((u) => u['email'] == adminEmail, orElse: () => <String, dynamic>{});
    final name = admin['name'] as String? ?? 'Admin';
    final shopsManaged = adminShops
        .where((s) {
          final users = s['users'] as List? ?? [];
          return users.any((u) => u is Map<String, dynamic> && u['email'] == adminEmail);
        })
        .toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF201F1F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(name, style: const TextStyle(fontSize: 18))),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(adminEmail,
                    style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _chip(Icons.store, '${shopsManaged.length} Shop${shopsManaged.length == 1 ? '' : 's'}'),
                  const SizedBox(width: 8),
                  _chip(Icons.people, '${adminShops.fold(0, (sum, s) => sum + ((s['_count'] is Map ? (s['_count'] as Map)['users'] as int? ?? 0 : 0)))} users'),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: Color(0xFF474554)),
              const SizedBox(height: 4),
              Text('Shops Managed', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: const Color(0xFF6C5CE7))),
              const SizedBox(height: 8),
              ...shopsManaged.map((s) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF6C5CE7).withOpacity(0.12)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C5CE7).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.store, size: 16, color: Color(0xFF6C5CE7)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s['shopName'] as String? ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.white)),
                          Text('${s['_count'] is Map ? (s['_count'] as Map)['sales'] as int? ?? 0 : 0} sales',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
                        ],
                      ),
                    ),
                    Text(
                      s['subscriptionPlan'] as String? ?? '',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF6C5CE7), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showCreateAdminDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final shopNameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF201F1F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person_add, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Create New Admin'),
          ],
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: shopNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Shop Name',
                    prefixIcon: Icon(Icons.store),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Admin Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                final success = await _adminService.createAdmin(
                  shopName: shopNameCtrl.text.trim(),
                  name: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  password: passwordCtrl.text.trim(),
                );
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
                if (success) {
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Admin created successfully'),
                      backgroundColor: Color(0xFF00B894),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to create admin'),
                      backgroundColor: Color(0xFFD63031),
                    ),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: const Color(0xFFD63031),
                    ),
                  );
                }
              }
            },
            child: const Text('Create Admin'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteShop(Map<String, dynamic> shop) {
    final shopName = shop['shopName'] as String? ?? 'this shop';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF201F1F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber, color: Color(0xFFD63031)),
            const SizedBox(width: 8),
            const Text('Delete Shop', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "$shopName" and all its data (users, sales, products, etc.)? This cannot be undone.',
          style: const TextStyle(color: Color(0xFFE0E0E0)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD63031)),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final id = shop['id'] as String?;
              if (id == null) return;
              try {
                final success = await _adminService.deleteShop(id);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Shop permanently deleted' : 'Failed to delete shop'),
                    backgroundColor: success ? const Color(0xFF00B894) : const Color(0xFFD63031),
                  ),
                );
                if (success) _loadData();
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFD63031)),
                );
              }
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAdmin(Map<String, dynamic> admin, List<String> managedShops) {
    final name = admin['name'] as String? ?? 'Unknown';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF201F1F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber, color: Color(0xFFD63031)),
            const SizedBox(width: 8),
            const Text('Deactivate Admin', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Text(
          'Are you sure you want to deactivate "$name"? Their ${managedShops.length} shop(s) will also be deactivated. This can be reversed later by reactivating.',
          style: const TextStyle(color: Color(0xFFE0E0E0)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD63031)),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final id = admin['id'] as String?;
              if (id == null) return;
              try {
                final success = await _adminService.deleteAdmin(id);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Admin deactivated' : 'Failed to deactivate admin'),
                    backgroundColor: success ? const Color(0xFF00B894) : const Color(0xFFD63031),
                  ),
                );
                if (success) _loadData();
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFD63031)),
                );
              }
            },
            child: const Text('Deactivate Admin'),
          ),
        ],
      ),
    );
  }
}
