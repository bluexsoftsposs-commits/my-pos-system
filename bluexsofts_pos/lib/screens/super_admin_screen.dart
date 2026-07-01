import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/admin_service.dart';
import '../core/theme.dart';
import '../views/shared/stat_card.dart';
import '../views/admin/shop_list_tile.dart';
import '../views/admin/user_list_tile.dart';
import 'login_screen.dart';

class SuperAdminScreen extends StatefulWidget {
  const SuperAdminScreen({super.key});

  @override
  State<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends State<SuperAdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  Map<String, dynamic>? _stats;
  List<dynamic> _shops = [];
  List<dynamic> _users = [];
  bool _loading = true;
  final _adminService = AdminService();

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

      final usersData = await _adminService.getUsers();
      if (usersData != null) _users = usersData['users'] ?? [];
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
            const Text('Super Admin Panel'),
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
              color: AppTheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout, color: AppTheme.error),
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
          indicatorColor: AppTheme.accent,
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
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _buildDashboardTab(),
                _buildShopsTab(),
                _buildAdminsTab(),
              ],
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
          value: '\$${(_stats!['totalRevenue'] as num).toStringAsFixed(2)}',
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
        ...(_stats!['planBreakdown'] as List).map((p) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.darkBorder.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 3)),
            ],
          ),
          child: ListTile(
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.subscriptions, color: AppTheme.primary),
            ),
            title: Text('${p['plan']}', style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${p['count']} shops',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accent),
              ),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildShopsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _shops.length,
      itemBuilder: (context, index) {
        final shop = _shops[index];
        return ShopListTile(
          shop: shop as Map<String, dynamic>,
          onToggle: () async {
            await _adminService.toggleShop(shop['id']);
            _loadData();
          },
          onExtend: () async {
            await _adminService.extendSubscription(shop['id']);
            _loadData();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Subscription extended by 30 days'),
                  backgroundColor: AppTheme.success,
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildAdminsTab() {
    final adminShops = _shops.where((s) {
      final users = s['users'] as List?;
      return users != null && users.isNotEmpty;
    }).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showCreateAdminDialog,
              icon: const Icon(Icons.person_add),
              label: const Text('Create New Admin'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 4,
                shadowColor: AppTheme.accent.withOpacity(0.4),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: adminShops.length,
                  itemBuilder: (context, index) {
                    final shop = adminShops[index];
                    final admin = (shop['users'] as List).first as Map<String, dynamic>;
                    final usersCount = shop['_count']?['users'] ?? 0;
                    final dateStr = admin['createdAt'] as String? ?? '';
                    final date = dateStr.isNotEmpty
                        ? dateStr.split('T')[0]
                        : '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.darkCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.darkBorder.withOpacity(0.5)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 3)),
                        ],
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
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${admin['name']}'.substring(0, 1).toUpperCase(),
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
                                        '${admin['name']}',
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                      ),
                                      Text(
                                        '${admin['email']}',
                                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _detailChip(Icons.store, 'Shop', '${shop['shopName']}'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _detailChip(Icons.people, 'Users', '$usersCount'),
                                const SizedBox(width: 12),
                                _detailChip(Icons.calendar_today, 'Since', date),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _detailChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text('$label: ', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Colors.white)),
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
        backgroundColor: AppTheme.darkSurface,
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
                      backgroundColor: AppTheme.success,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to create admin'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              } catch (e) {
                print('UNHANDLED ERROR in create admin dialog: $e');
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppTheme.error,
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
