import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/admin_service.dart';
import '../core/theme.dart';
import '../views/shared/stat_card.dart';
import '../core/currency_formatter.dart';
import 'login_screen.dart';

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
const _plans = ['NONE', 'BASIC', 'STANDARD', 'PREMIUM'];
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
      ],
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

  Widget _buildShopCard({
    required Map<String, dynamic> shop,
    required VoidCallback onToggle,
    required VoidCallback onExtend,
  }) {
    final plan = shop['subscriptionPlan'] as String? ?? 'No Plan';
    final status = shop['subscriptionStatus'] as String? ?? '';
    final shopName = shop['shopName'] as String? ?? 'Unnamed Shop';
    final category = shop['category'] as String? ?? 'General';
    final isActive = shop['isActive'] as bool? ?? true;
    final salesCount = shop['_count'] is Map ? (shop['_count'] as Map)['sales'] as int? ?? 0 : 0;
    final branchCount = shop['_count'] is Map ? (shop['_count'] as Map)['branches'] as int? ?? 0 : 0;

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
                              isExpired ? 'LAST SETTLEMENT' : 'MONTHLY REVENUE',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                color: Color(0xFF9E9E9E),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$salesCount',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  suspended ? _buildSuspendedActions(onToggle, shop)
                      : isExpired ? _buildExpiredActions(onExtend, onToggle, shop)
                      : _buildActiveActions(onToggle, onExtend, shop),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveActions(VoidCallback onToggle, VoidCallback onExtend, Map<String, dynamic> shop) {
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
      ],
    );
  }

  Widget _buildSuspendedActions(VoidCallback onToggle, Map<String, dynamic> shop) {
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
      ],
    );
  }

  Widget _buildExpiredActions(VoidCallback onExtend, VoidCallback onToggle, Map<String, dynamic> shop) {
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
      ],
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
    final plan = shop['subscriptionPlan'] as String? ?? 'NONE';
    final status = shop['subscriptionStatus'] as String? ?? 'NONE';
    final category = shop['category'] as String? ?? 'General';
    final isActive = shop['isActive'] as bool? ?? true;
    final usersCount = shop['_count'] is Map ? (shop['_count'] as Map)['users'] as int? ?? 0 : 0;
    final salesCount = shop['_count'] is Map ? (shop['_count'] as Map)['sales'] as int? ?? 0 : 0;
    final branchCount = shop['_count'] is Map ? (shop['_count'] as Map)['branches'] as int? ?? 0 : 0;
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
              _detailRow('Plan', plan),
              _detailRow('Status', status),
              _detailRow('Category', category),
              _detailRow('Active', isActive ? 'Yes' : 'No'),
              _detailRow('Days Remaining', daysRemaining),
              const Divider(color: Color(0xFF474554)),
              _sectionHeader('Activity'),
              _detailRow('Total Sales', '$salesCount'),
              _detailRow('Total Users', '$usersCount'),
              _detailRow('Branches', '$branchCount'),
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
                              Row(
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
                                          '${admin['email'] ?? ''}',
                                          style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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
}
