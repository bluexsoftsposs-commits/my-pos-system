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
        title: const Text('Super Admin Panel'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          IconButton(
            icon: const Icon(Icons.logout),
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
        ],
        bottom: TabBar(
          controller: _tabCtrl,
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
        StatCard(title: 'Total Shops', value: '${_stats!['totalShops']}', icon: Icons.store, color: AppTheme.primary),
        const SizedBox(height: 8),
        StatCard(title: 'Active Shops', value: '${_stats!['activeShops']}', icon: Icons.check_circle, color: AppTheme.success),
        const SizedBox(height: 8),
        StatCard(title: 'Total Users', value: '${_stats!['totalUsers']}', icon: Icons.people, color: AppTheme.info),
        const SizedBox(height: 8),
        StatCard(title: 'Admins', value: '${_stats!['totalAdmins']}', icon: Icons.admin_panel_settings, color: AppTheme.accent),
        const SizedBox(height: 8),
        StatCard(title: 'Cashiers', value: '${_stats!['totalCashiers']}', icon: Icons.person, color: AppTheme.warning),
        const SizedBox(height: 8),
        StatCard(title: 'Total Sales', value: '${_stats!['totalSales']}', icon: Icons.receipt_long, color: Colors.cyan),
        const SizedBox(height: 8),
        StatCard(title: 'Total Revenue', value: '\$${(_stats!['totalRevenue'] as num).toStringAsFixed(2)}', icon: Icons.attach_money, color: AppTheme.success),
        const SizedBox(height: 16),
        Text('Plans Breakdown', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...(_stats!['planBreakdown'] as List).map((p) => Card(
          child: ListTile(
            leading: const Icon(Icons.subscriptions, color: AppTheme.primary),
            title: Text('${p['plan']}'),
            trailing: Text('${p['count']} shops', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                const SnackBar(content: Text('Subscription extended by 30 days')),
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
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        Expanded(
          child: adminShops.isEmpty
              ? const Center(child: Text('No admins found'))
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

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppTheme.primary.withOpacity(0.2),
                                  child: const Icon(Icons.admin_panel_settings, color: AppTheme.primary),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${admin['name']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                      Text('${admin['email']}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            _detailRow(Icons.store, 'Shop', '${shop['shopName']}'),
                            const SizedBox(height: 4),
                            _detailRow(Icons.people, 'Total Users', '$usersCount'),
                            const SizedBox(height: 4),
                            _detailRow(Icons.calendar_today, 'Admin Since', date),
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

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text('$label: ', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
      ],
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
        title: const Text('Create New Admin'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: shopNameCtrl,
                  decoration: const InputDecoration(labelText: 'Shop Name'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Admin Name'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordCtrl,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
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
                    const SnackBar(content: Text('Admin created successfully'), backgroundColor: AppTheme.success),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to create admin'), backgroundColor: AppTheme.error),
                  );
                }
              } catch (e) {
                print('UNHANDLED ERROR in create admin dialog: $e');
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
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
