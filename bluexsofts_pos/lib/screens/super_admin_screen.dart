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
            Tab(text: 'Users'),
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
                _buildUsersTab(),
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

  Widget _buildUsersTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final u = _users[index];
        return UserListTile(
          user: u as Map<String, dynamic>,
          onDeactivate: () async {
            await _adminService.deactivateUser(u['id']);
            _loadData();
          },
        );
      },
    );
  }
}
