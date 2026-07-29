import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/subadmin_service.dart';
import '../services/plan_service.dart';
import '../core/theme.dart';
import '../core/currency_formatter.dart';
import '../views/shared/stat_card.dart';
import 'login_screen.dart';

class SubAdminScreen extends StatefulWidget {
  const SubAdminScreen({super.key});

  @override
  State<SubAdminScreen> createState() => _SubAdminScreenState();
}

class _SubAdminScreenState extends State<SubAdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _subAdminService = SubAdminService();
  final _planService = PlanService();

  Map<String, dynamic>? _reports;
  List<dynamic> _admins = [];
  List<dynamic> _shops = [];
  List<dynamic> _plans = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
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
      final reportsData = await _subAdminService.getReports();
      if (reportsData != null) _reports = reportsData;

      final adminsData = await _subAdminService.getAdmins();
      if (adminsData != null) _admins = adminsData['admins'] ?? [];

      final shopsData = await _subAdminService.getShops();
      if (shopsData != null) _shops = shopsData['shops'] ?? [];

      final plansData = await _planService.getAllPlans();
      if (plansData != null) _plans = plansData;
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
              width: 32, height: 32,
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.admin_panel_settings, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text('Sub-Admin Panel'),
          ],
        ),
        actions: [
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
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey[500],
          isScrollable: true,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Admins'),
            Tab(text: 'Shops'),
            Tab(text: 'Plans'),
            Tab(text: 'Reports'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _buildDashboardTab(),
                _buildAdminsTab(),
                _buildShopsTab(),
                _buildPlansTab(),
                _buildReportsTab(),
              ],
            ),
    );
  }

  Widget _buildDashboardTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppTheme.cardGradientPurple,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sub-Admin Dashboard', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Manage shops, admins, and plans in your region', style: TextStyle(color: Colors.white.withOpacity(0.7))),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_reports != null) ...[
          StatCard(
            title: 'Total Shops',
            value: '${_reports!['totalShops'] ?? 0}',
            icon: Icons.store,
            color: AppTheme.primary,
            gradient: AppTheme.cardGradientBlue,
          ),
          StatCard(
            title: 'Total Users',
            value: '${_reports!['totalUsers'] ?? 0}',
            icon: Icons.people,
            color: AppTheme.success,
            gradient: AppTheme.cardGradientGreen,
          ),
          StatCard(
            title: 'Total Revenue',
            value: CurrencyFormatter.formatWithDecimals((_reports!['totalRevenue'] as num?) ?? 0),
            icon: Icons.attach_money,
            color: AppTheme.accent,
            gradient: AppTheme.cardGradientPurple,
          ),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF201F1F),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF6C5CE7).withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF6C5CE7), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You have ${_admins.length} admin(s) and ${_shops.length} shop(s) assigned to you.',
                  style: const TextStyle(color: Color(0xFFC6BFFF), fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdminsTab() {
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
              ),
            ),
          ),
        ),
        Expanded(
          child: _admins.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.admin_panel_settings, size: 64, color: Colors.grey[600]),
                      const SizedBox(height: 12),
                      Text('No admins found', style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _admins.length,
                  itemBuilder: (context, index) {
                    final admin = _admins[index] as Map<String, dynamic>;
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
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.accentGradient,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${admin['name'] ?? '?'}'.substring(0, 1).toUpperCase(),
                                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${admin['name'] ?? 'Unknown'}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                      Text('${admin['email'] ?? ''}', style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00B894).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6, height: 6,
                                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF00B894)),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text('Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF00B894))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (admin['shop'] != null) ...[
                              Row(
                                children: [
                                  const Icon(Icons.store, size: 14, color: Color(0xFF6C5CE7)),
                                  const SizedBox(width: 6),
                                  Text('${admin['shop']['shopName'] ?? ''}', style: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E))),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6C5CE7).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text('${admin['shop']['category'] ?? ''}', style: const TextStyle(fontSize: 10, color: Color(0xFFC6BFFF))),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _showEditAdminDialog(admin),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2A2A2A),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.edit_outlined, size: 14, color: Color(0xFFE0E0E0)),
                                          SizedBox(width: 4),
                                          Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: GestureDetector(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD63031).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.block, size: 14, color: Color(0xFF9E9E9E)),
                                          SizedBox(width: 4),
                                          Text('Delete (disabled)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9E9E9E))),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
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

  Widget _buildShopsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showCreateShopDialog,
              icon: const Icon(Icons.add_business),
              label: const Text('Create New Shop'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        Expanded(
          child: _shops.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.store, size: 64, color: Colors.grey[600]),
                      const SizedBox(height: 12),
                      Text('No shops assigned', style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _shops.length,
                  itemBuilder: (context, index) {
                    final shop = _shops[index] as Map<String, dynamic>;
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
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6C5CE7).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.store, color: Color(0xFF6C5CE7), size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${shop['shopName'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                      Text('Category: ${_categoryLabel(shop['category'] as String? ?? 'OTHER')}', style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6C5CE7).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text('${shop['subscriptionPlan'] ?? 'NONE'}', style: const TextStyle(fontSize: 11, color: Color(0xFFC6BFFF))),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _chip(Icons.people, '${shop['_count'] is Map ? (shop['_count'] as Map)['users'] ?? 0 : 0} users'),
                                const SizedBox(width: 8),
                                _chip(Icons.inventory_2, '${shop['_count'] is Map ? (shop['_count'] as Map)['products'] ?? 0 : 0} products'),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () => _showEditShopDialog(shop),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2A2A2A),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.edit_outlined, size: 14, color: Color(0xFFE0E0E0)),
                                        SizedBox(width: 4),
                                        Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ),
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

  Widget _buildPlansTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Container(
              width: 4, height: 20,
              decoration: BoxDecoration(gradient: AppTheme.accentGradient, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 10),
            Text('Available Plans', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 12),
        ...(_plans.isNotEmpty ? _plans : [
          {'name': 'Lite', 'billingCycle': 'MONTHLY', 'price': 1500, 'salesPointsLimit': 1, 'productsLimit': 200},
          {'name': 'Plus', 'billingCycle': 'MONTHLY', 'price': 3000, 'salesPointsLimit': 3, 'productsLimit': 500},
          {'name': 'Pro', 'billingCycle': 'MONTHLY', 'price': 5000, 'salesPointsLimit': 10, 'productsLimit': 2000},
        ]).map((plan) {
          final p = plan as Map<String, dynamic>;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF201F1F),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: ListTile(
              leading: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C5CE7).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.subscriptions, color: Color(0xFF6C5CE7)),
              ),
              title: Text('${p['name'] ?? ''} (${p['billingCycle'] ?? ''})', style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('PKR ${p['price'] ?? 0} - ${p['salesPointsLimit'] ?? 0} users, ${p['productsLimit'] ?? 0} products'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF9E9E9E)),
            ),
          );
        }),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E).withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF6C5CE7).withOpacity(0.15)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF6C5CE7), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'To change a plan for a shop, go to Shops tab and tap "Change Plan" button. This will require super admin approval.',
                  style: const TextStyle(color: Color(0xFFC6BFFF), fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReportsTab() {
    if (_reports == null) return const Center(child: Text('No report data'));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Container(
              width: 4, height: 20,
              decoration: BoxDecoration(gradient: AppTheme.accentGradient, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 10),
            Text('Reports', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 12),
        StatCard(
          title: 'Revenue',
          value: CurrencyFormatter.formatWithDecimals((_reports!['totalRevenue'] as num?) ?? 0),
          icon: Icons.attach_money,
          color: AppTheme.success,
          gradient: AppTheme.cardGradientGreen,
        ),
        StatCard(
          title: 'Total Shops',
          value: '${_reports!['totalShops'] ?? 0}',
          icon: Icons.store,
          color: AppTheme.primary,
          gradient: AppTheme.cardGradientBlue,
        ),
        StatCard(
          title: 'Users',
          value: '${_reports!['totalUsers'] ?? 0}',
          icon: Icons.people,
          color: AppTheme.accent,
          gradient: AppTheme.cardGradientPurple,
        ),
        if ((_reports!['categoryBreakdown'] as List?) != null) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 4, height: 20,
                decoration: BoxDecoration(gradient: AppTheme.accentGradient, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 10),
              Text('Category Breakdown', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          ...(_reports!['categoryBreakdown'] as List).map((c) {
            final cat = c as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF201F1F),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Icon(_categoryIcon('${cat['category'] ?? ''}'), color: const Color(0xFF6C5CE7)),
                title: Text('${cat['category'] ?? 'Unknown'}'),
                trailing: Text('${cat['count'] ?? 0} shops', style: const TextStyle(color: Color(0xFF6C5CE7), fontWeight: FontWeight.bold)),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF6C5CE7).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF6C5CE7)),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFFC6BFFF))),
        ],
      ),
    );
  }

  String _categoryLabel(String cat) {
    switch (cat) {
      case 'Grocery': return 'Grocery';
      case 'Electronics': return 'Electronics';
      case 'Restaurant': return 'Restaurant';
      case 'Pharmacy': return 'Pharmacy';
      case 'Clothing': return 'Clothing';
      case 'General': return 'General';
      default: return 'Other';
    }
  }

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

  void _showCreateAdminDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final shopNameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String selectedCategory = 'Other';
    bool saving = false;

    const categories = ['Grocery', 'Electronics', 'Restaurant', 'Pharmacy', 'Clothing', 'General', 'Other'];

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
                decoration: BoxDecoration(gradient: AppTheme.accentGradient, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.person_add, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Create Admin'),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('This will be sent to super admin for approval.', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: shopNameCtrl,
                    decoration: const InputDecoration(labelText: 'Shop Name', prefixIcon: Icon(Icons.store)),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(labelText: 'Shop Category', prefixIcon: Icon(Icons.category)),
                items: const ['Grocery', 'Electronics', 'Restaurant', 'Pharmacy', 'Clothing', 'General', 'Other']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                    onChanged: (v) => setDialogState(() => selectedCategory = v ?? 'OTHER'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Admin Name', prefixIcon: Icon(Icons.person)),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passwordCtrl,
                    decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
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
              onPressed: saving ? null : () async {
                if (!formKey.currentState!.validate()) return;
                setDialogState(() => saving = true);
                try {
                  final result = await _subAdminService.createAdmin({
                    'shopName': shopNameCtrl.text.trim(),
                    'name': nameCtrl.text.trim(),
                    'email': emailCtrl.text.trim(),
                    'password': passwordCtrl.text.trim(),
                    'category': selectedCategory,
                  });
                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop();
                  if (result != null) {
                    _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Admin creation sent for approval. Super admin has been notified.'),
                        backgroundColor: Color(0xFF00B894),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to submit request'), backgroundColor: Color(0xFFD63031)),
                    );
                  }
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
                  : const Text('Submit for Approval'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditAdminDialog(Map<String, dynamic> admin) {
    final nameCtrl = TextEditingController(text: admin['name'] as String? ?? '');
    final emailCtrl = TextEditingController(text: admin['email'] as String? ?? '');
    final formKey = GlobalKey<FormState>();
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
                decoration: BoxDecoration(gradient: AppTheme.accentGradient, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.edit, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Edit Admin'),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Changes will require super admin approval.', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: saving ? null : () async {
                setDialogState(() => saving = true);
                try {
                  final result = await _subAdminService.editAdmin(admin['id'] as String, {
                    'name': nameCtrl.text.trim(),
                    'email': emailCtrl.text.trim(),
                  });
                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop();
                  if (result != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Edit request sent for approval.'),
                        backgroundColor: Color(0xFF00B894),
                      ),
                    );
                  }
                } catch (e) {
                  setDialogState(() => saving = false);
                }
              },
              child: saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Request Approval'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateShopDialog() {
    final nameCtrl = TextEditingController();
    String selectedCategory = 'Other';
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
                decoration: BoxDecoration(gradient: AppTheme.accentGradient, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.add_business, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Create Shop'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Shop Name', prefixIcon: Icon(Icons.store)),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category)),
                items: const ['Grocery', 'Electronics', 'Restaurant', 'Pharmacy', 'Clothing', 'General', 'Other']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedCategory = v ?? 'Other'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: saving ? null : () async {
                setDialogState(() => saving = true);
                try {
                  final result = await _subAdminService.createShop({
                    'shopName': nameCtrl.text.trim(),
                    'category': selectedCategory,
                  });
                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop();
                  if (result != null) {
                    _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Shop created'), backgroundColor: Color(0xFF00B894)),
                    );
                  }
                } catch (e) {
                  setDialogState(() => saving = false);
                }
              },
              child: saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditShopDialog(Map<String, dynamic> shop) {
    final nameCtrl = TextEditingController(text: shop['shopName'] as String? ?? '');
    String selectedCategory = shop['category'] as String? ?? 'Other';
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
                decoration: BoxDecoration(gradient: AppTheme.accentGradient, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.edit, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Edit Shop'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Shop Name', prefixIcon: Icon(Icons.store)),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category)),
                items: const ['Grocery', 'Electronics', 'Restaurant', 'Pharmacy', 'Clothing', 'General', 'Other']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedCategory = v ?? 'Other'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: saving ? null : () async {
                setDialogState(() => saving = true);
                try {
                  await _subAdminService.editShop(shop['id'] as String, {
                    'shopName': nameCtrl.text.trim(),
                    'category': selectedCategory,
                  });
                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop();
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Shop updated'), backgroundColor: Color(0xFF00B894)),
                  );
                } catch (e) {
                  setDialogState(() => saving = false);
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
}
