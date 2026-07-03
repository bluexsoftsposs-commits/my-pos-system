import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../core/theme.dart';

class PlansManagementScreen extends StatefulWidget {
  const PlansManagementScreen({super.key});

  @override
  State<PlansManagementScreen> createState() => _PlansManagementScreenState();
}

class _PlansManagementScreenState extends State<PlansManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _adminService = AdminService();

  List<dynamic> _plans = [];
  List<dynamic> _shops = [];
  bool _loadingPlans = true;
  bool _loadingShops = true;
  int _shopPage = 1;
  static const int _pageSize = 5;
  String _searchQuery = '';
  int _totalShops = 0;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        setState(() {});
      }
    });
    _loadPlans();
    _loadShops();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPlans() async {
    setState(() => _loadingPlans = true);
    try {
      final data = await _adminService.getPlansList();
      if (data != null) _plans = data;
    } catch (_) {}
    if (mounted) setState(() => _loadingPlans = false);
  }

  Future<void> _loadShops() async {
    setState(() => _loadingShops = true);
    try {
      final data = await _adminService.getShopsSubscriptions(
        page: _shopPage,
        limit: _pageSize,
        search: _searchQuery,
      );
      if (data != null) {
        _shops = data['shops'] ?? [];
        _totalShops = data['total'] as int? ?? 0;
        _totalPages = data['totalPages'] as int? ?? 1;
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingShops = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: const Icon(Icons.subscriptions, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text('Plans & Subscriptions'),
          ],
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppTheme.accent,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey[500],
          tabs: const [
            Tab(text: 'Plans'),
            Tab(text: 'Shop Subscriptions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildPlansTab(),
          _buildSubscriptionsTab(),
        ],
      ),
    );
  }

  // ── Tab 1: Plans ─────────────────────────────────────────────

  Widget _buildPlansTab() {
    return _loadingPlans
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppTheme.spaceMd, AppTheme.spaceMd, AppTheme.spaceMd, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Manage Plans (${_plans.length})',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.accentGradient,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: _showAddPlanDialog,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spaceSm),
              Expanded(
                child: _plans.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.subscriptions,
                                size: 64, color: Colors.grey[700]),
                            const SizedBox(height: 12),
                            Text('No plans found',
                                style: TextStyle(color: Colors.grey[500])),
                          ],
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final isDesktop = constraints.maxWidth >= 800;
                          if (isDesktop) {
                            return GridView.builder(
                              padding: const EdgeInsets.all(AppTheme.spaceMd),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: AppTheme.spaceMd,
                                crossAxisSpacing: AppTheme.spaceMd,
                                childAspectRatio: 0.75,
                              ),
                              itemCount: _plans.length,
                              itemBuilder: (context, i) =>
                                  _buildPlanCard(_plans[i] as Map<String, dynamic>),
                            );
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.all(AppTheme.spaceMd),
                            itemCount: _plans.length,
                            itemBuilder: (context, i) => Padding(
                              padding: const EdgeInsets.only(bottom: AppTheme.spaceMd),
                              child: _buildPlanCard(_plans[i] as Map<String, dynamic>),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final name = plan['name'] as String? ?? '';
    final billingCycle = plan['billingCycle'] as String? ?? '';
    final price = plan['price'] as num? ?? 0;
    final setupFee = plan['setupFee'] as num? ?? 0;
    final isActive = plan['isActive'] as bool? ?? true;
    final cycleLabel = billingCycle == 'MONTHLY'
        ? 'Monthly'
        : billingCycle == 'ANNUAL'
            ? 'Annual'
            : 'One-time';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.darkBorder.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spaceMd),
            decoration: BoxDecoration(
              gradient: isActive
                  ? AppTheme.cardGradientBlue
                  : LinearGradient(
                      colors: [
                        AppTheme.darkSurface,
                        AppTheme.darkCard,
                      ],
                    ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusFull),
                      ),
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (!isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.3),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusFull),
                        ),
                        child: const Text(
                          'Inactive',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceSm),
                Text(
                  'PKR ${_formatNum(price)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '/ $cycleLabel',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'Setup: PKR ${_formatNum(setupFee)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spaceMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _planDetail('Products', '${plan['productsLimit'] ?? 0}'),
                  const SizedBox(height: 4),
                  _planDetail('Sales Points', '${plan['salesPointsLimit'] ?? 0}'),
                  const SizedBox(height: 4),
                  _planDetail('FBR', plan['fbrConnect'] == true ? 'Yes' : 'No'),
                  const SizedBox(height: 4),
                  _planDetail('Support', plan['techSupport'] == true ? 'Yes' : 'No'),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: _smallBtn(
                          icon: Icons.edit,
                          label: 'Edit',
                          onTap: () => _showEditPlanDialog(plan),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _smallBtn(
                          icon: isActive
                              ? Icons.visibility_off
                              : Icons.visibility,
                          label: isActive ? 'Deactivate' : 'Activate',
                          color: isActive ? AppTheme.error : AppTheme.success,
                          onTap: () => _togglePlan(plan),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _planDetail(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        Text(value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _smallBtn({
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    final c = color ?? AppTheme.accent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: c),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: c),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPlanDialog() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    String billingCycle = 'MONTHLY';
    final priceCtrl = TextEditingController();
    final setupFeeCtrl = TextEditingController();
    final originalSetupFeeCtrl = TextEditingController();
    final productsLimitCtrl = TextEditingController();
    final salesPointsLimitCtrl = TextEditingController();
    bool fbrConnect = false;
    bool techSupport = false;
    bool onlineStore = false;
    bool updates = false;
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.darkSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Add Plan'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Plan Name',
                        prefixIcon: Icon(Icons.label),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: billingCycle,
                      decoration: const InputDecoration(
                        labelText: 'Billing Cycle',
                        prefixIcon: Icon(Icons.repeat),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'MONTHLY', child: Text('Monthly')),
                        DropdownMenuItem(
                            value: 'ANNUAL', child: Text('Annual')),
                        DropdownMenuItem(
                            value: 'ONETIME', child: Text('One-time')),
                      ],
                      onChanged: (v) =>
                          setDialogState(() => billingCycle = v ?? 'MONTHLY'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: priceCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Price',
                              prefixIcon: Icon(Icons.attach_money),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: setupFeeCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Setup Fee',
                              prefixIcon: Icon(Icons.money_off),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: originalSetupFeeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Original Setup Fee (for strikethrough)',
                        prefixIcon: Icon(Icons.money_off_csred),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: productsLimitCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Products Limit',
                              prefixIcon: Icon(Icons.inventory),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: salesPointsLimitCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Sales Points',
                              prefixIcon: Icon(Icons.people),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Features',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _featureToggle('FBR Connect', fbrConnect, (v) =>
                        setDialogState(() => fbrConnect = v)),
                    _featureToggle('Tech Support', techSupport, (v) =>
                        setDialogState(() => techSupport = v)),
                    _featureToggle('Online Store', onlineStore, (v) =>
                        setDialogState(() => onlineStore = v)),
                    _featureToggle('Updates', updates,
                        (v) => setDialogState(() => updates = v)),
                  ],
                ),
              ),
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
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => saving = true);
                      try {
                        await _adminService.createPlan({
                          'name': nameCtrl.text.trim(),
                          'billingCycle': billingCycle,
                          'price': num.tryParse(priceCtrl.text)?.toDouble() ?? 0,
                          'setupFee':
                              num.tryParse(setupFeeCtrl.text)?.toDouble() ?? 0,
                          'originalSetupFee': num.tryParse(
                                  originalSetupFeeCtrl.text)
                              ?.toDouble(),
                          'productsLimit':
                              int.tryParse(productsLimitCtrl.text) ?? 0,
                          'salesPointsLimit':
                              int.tryParse(salesPointsLimitCtrl.text) ?? 0,
                          'fbrConnect': fbrConnect,
                          'techSupport': techSupport,
                          'onlineStore': onlineStore,
                          'updates': updates,
                        });
                        if (!ctx.mounted) return;
                        Navigator.of(ctx).pop();
                        _loadPlans();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Plan created'),
                            backgroundColor: AppTheme.success,
                          ),
                        );
                      } catch (e) {
                        setDialogState(() => saving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AppTheme.error,
                            ),
                          );
                        }
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPlanDialog(Map<String, dynamic> plan) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: plan['name'] as String? ?? '');
    String billingCycle = plan['billingCycle'] as String? ?? 'MONTHLY';
    final priceCtrl = TextEditingController(
        text: '${plan['price'] ?? ''}');
    final setupFeeCtrl = TextEditingController(
        text: '${plan['setupFee'] ?? ''}');
    final originalSetupFeeCtrl = TextEditingController(
        text: '${plan['originalSetupFee'] ?? ''}');
    final productsLimitCtrl = TextEditingController(
        text: '${plan['productsLimit'] ?? ''}');
    final salesPointsLimitCtrl = TextEditingController(
        text: '${plan['salesPointsLimit'] ?? ''}');
    bool fbrConnect = plan['fbrConnect'] == true;
    bool techSupport = plan['techSupport'] == true;
    bool onlineStore = plan['onlineStore'] == true;
    bool updates = plan['updates'] == true;
    bool saving = false;
    final planId = plan['id'] as String;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.darkSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Edit ${plan['name'] ?? 'Plan'}'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Plan Name',
                        prefixIcon: Icon(Icons.label),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: billingCycle,
                      decoration: const InputDecoration(
                        labelText: 'Billing Cycle',
                        prefixIcon: Icon(Icons.repeat),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'MONTHLY', child: Text('Monthly')),
                        DropdownMenuItem(
                            value: 'ANNUAL', child: Text('Annual')),
                        DropdownMenuItem(
                            value: 'ONETIME', child: Text('One-time')),
                      ],
                      onChanged: (v) =>
                          setDialogState(() => billingCycle = v ?? 'MONTHLY'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: priceCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Price',
                              prefixIcon: Icon(Icons.attach_money),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: setupFeeCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Setup Fee',
                              prefixIcon: Icon(Icons.money_off),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: originalSetupFeeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Original Setup Fee',
                        prefixIcon: Icon(Icons.money_off_csred),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: productsLimitCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Products Limit',
                              prefixIcon: Icon(Icons.inventory),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: salesPointsLimitCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Sales Points',
                              prefixIcon: Icon(Icons.people),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Features',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _featureToggle('FBR Connect', fbrConnect, (v) =>
                        setDialogState(() => fbrConnect = v)),
                    _featureToggle('Tech Support', techSupport, (v) =>
                        setDialogState(() => techSupport = v)),
                    _featureToggle('Online Store', onlineStore, (v) =>
                        setDialogState(() => onlineStore = v)),
                    _featureToggle('Updates', updates,
                        (v) => setDialogState(() => updates = v)),
                  ],
                ),
              ),
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
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => saving = true);
                      try {
                        await _adminService.updatePlan(planId, {
                          'name': nameCtrl.text.trim(),
                          'billingCycle': billingCycle,
                          'price': num.tryParse(priceCtrl.text)?.toDouble() ?? 0,
                          'setupFee':
                              num.tryParse(setupFeeCtrl.text)?.toDouble() ?? 0,
                          'originalSetupFee': num.tryParse(
                                  originalSetupFeeCtrl.text)
                              ?.toDouble(),
                          'productsLimit':
                              int.tryParse(productsLimitCtrl.text) ?? 0,
                          'salesPointsLimit':
                              int.tryParse(salesPointsLimitCtrl.text) ?? 0,
                          'fbrConnect': fbrConnect,
                          'techSupport': techSupport,
                          'onlineStore': onlineStore,
                          'updates': updates,
                        });
                        if (!ctx.mounted) return;
                        Navigator.of(ctx).pop();
                        _loadPlans();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Plan updated'),
                            backgroundColor: AppTheme.success,
                          ),
                        );
                      } catch (e) {
                        setDialogState(() => saving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AppTheme.error,
                            ),
                          );
                        }
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.accent,
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Future<void> _togglePlan(Map<String, dynamic> plan) async {
    final planId = plan['id'] as String;
    final name = plan['name'] as String? ?? '';
    final isActive = plan['isActive'] as bool? ?? true;
    final action = isActive ? 'deactivate' : 'activate';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: Text(isActive ? 'Deactivate Plan' : 'Activate Plan'),
        content: Text('Are you sure you want to $action "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(isActive ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adminService.deactivatePlan(planId);
        _loadPlans();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Plan ${isActive ? 'deactivated' : 'activated'}'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }

  // ── Tab 2: Shop Subscriptions ────────────────────────────────

  Widget _buildSubscriptionsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppTheme.spaceMd, AppTheme.spaceMd, AppTheme.spaceMd, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Shop Subscriptions',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '$_totalShops total',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceSm),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search by shop name...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: AppTheme.darkCard,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusMd),
                    borderSide:
                        BorderSide(color: AppTheme.darkBorder),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (v) {
                  _searchQuery = v;
                  _shopPage = 1;
                  _loadShops();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spaceSm),
        Expanded(
          child: _loadingShops && _shops.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _shops.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.store,
                              size: 64, color: Colors.grey[700]),
                          const SizedBox(height: 12),
                          Text('No shops found',
                              style: TextStyle(color: Colors.grey[500])),
                        ],
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final isDesktop = constraints.maxWidth >= 1024;
                        if (isDesktop) {
                          return Column(
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  child: _buildDesktopTable(),
                                ),
                              ),
                              if (_totalPages > 1) _buildPagination(),
                            ],
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spaceMd),
                          itemCount: _shops.length,
                          itemBuilder: (context, i) => Padding(
                            padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
                            child: _buildMobileCard(
                                _shops[i] as Map<String, dynamic>),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildDesktopTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor:
            WidgetStateProperty.all(AppTheme.darkCard.withValues(alpha: 0.5)),
        horizontalMargin: AppTheme.spaceMd,
        columnSpacing: 32,
        columns: const [
          DataColumn(
              label: Text('Shop Name',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          DataColumn(
              label: Text('Plan',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          DataColumn(
              label: Text('Billing',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          DataColumn(
              label: Text('Products',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          DataColumn(
              label: Text('Sales Points',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          DataColumn(
              label: Text('Status',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          DataColumn(
              label: Text('Action',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              numeric: true),
        ],
        rows: _shops.map((s) {
          final shop = s as Map<String, dynamic>;
          final name = shop['shopName'] as String? ?? '';
          final planName = shop['subscriptionPlan'] as String? ?? 'NONE';
          final status = shop['subscriptionStatus'] as String? ?? '';
          final isActive = shop['isActive'] as bool? ?? true;
          final subs = shop['subscriptions'] as List? ?? [];
          final activeSub = subs.isNotEmpty ? subs.first as Map<String, dynamic> : null;
          final subPlan = activeSub?['plan'] as Map<String, dynamic>?;
          final billingCycle = subPlan?['billingCycle'] as String? ?? '';
          final cycleLabel = billingCycle == 'MONTHLY'
              ? 'Monthly'
              : billingCycle == 'ANNUAL'
                  ? 'Annual'
                  : billingCycle == 'ONETIME' ? 'One-time' : '-';
          final count = shop['_count'] as Map<String, dynamic>? ?? {};
          final productsUsed = count['products'] as int? ?? 0;
          final productsLimit = subPlan?['productsLimit'] as int? ?? 0;
          final usersCount = count['users'] as int? ?? 0;
          final salesPointsLimit = subPlan?['salesPointsLimit'] as int? ?? 0;

          return DataRow(cells: [
            DataCell(Text(name, style: const TextStyle(fontSize: 13))),
            DataCell(Text(planName, style: const TextStyle(fontSize: 13))),
            DataCell(Text(cycleLabel, style: const TextStyle(fontSize: 13))),
            DataCell(Text('$productsUsed / $productsLimit',
                style: const TextStyle(fontSize: 13))),
            DataCell(Text('$usersCount / $salesPointsLimit',
                style: const TextStyle(fontSize: 13))),
            DataCell(_statusChip(status, isActive)),
            DataCell(
              _tableActionBtn(shop),
            ),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildMobileCard(Map<String, dynamic> shop) {
    final name = shop['shopName'] as String? ?? '';
    final planName = shop['subscriptionPlan'] as String? ?? 'NONE';
    final status = shop['subscriptionStatus'] as String? ?? '';
    final isActive = shop['isActive'] as bool? ?? true;
    final subs = shop['subscriptions'] as List? ?? [];
    final activeSub = subs.isNotEmpty ? subs.first as Map<String, dynamic> : null;
    final subPlan = activeSub?['plan'] as Map<String, dynamic>?;
    final billingCycle = subPlan?['billingCycle'] as String? ?? '';
    final cycleLabel = billingCycle == 'MONTHLY'
        ? 'Monthly'
        : billingCycle == 'ANNUAL'
            ? 'Annual'
            : 'One-time';
    final count = shop['_count'] as Map<String, dynamic>? ?? {};
    final productsUsed = count['products'] as int? ?? 0;
    final productsLimit = subPlan?['productsLimit'] as int? ?? 0;
    final usersCount = count['users'] as int? ?? 0;
    final salesPointsLimit = subPlan?['salesPointsLimit'] as int? ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.darkBorder.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                ),
                _statusChip(status, isActive),
              ],
            ),
            const SizedBox(height: AppTheme.spaceSm),
            Row(
              children: [
                _chip(label: planName, color: AppTheme.accent),
                const SizedBox(width: 6),
                if (billingCycle.isNotEmpty)
                  _chip(label: cycleLabel, color: AppTheme.info),
              ],
            ),
            const SizedBox(height: AppTheme.spaceSm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Products: $productsUsed / $productsLimit',
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
                Text('Users: $usersCount / $salesPointsLimit',
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: AppTheme.spaceSm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showChangePlanDialog(shop),
                icon: const Icon(Icons.swap_horiz, size: 16),
                label: const Text('Change Plan', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.accent,
                  side: BorderSide(color: AppTheme.accent.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _tableActionBtn(Map<String, dynamic> shop) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
      color: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      onSelected: (value) {
        if (value == 'change_plan') {
          _showChangePlanDialog(shop);
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'change_plan',
          child: ListTile(
            leading: Icon(Icons.swap_horiz, size: 18),
            title: Text('Change Plan', style: TextStyle(fontSize: 13)),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  void _showChangePlanDialog(Map<String, dynamic> shop) {
    final shopId = shop['id'] as String;
    final shopName = shop['shopName'] as String? ?? '';
    String? selectedPlanId;
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.darkSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.swap_horiz, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Change Plan — $shopName',
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          content: SizedBox(
            width: 300,
            child: _plans.isEmpty
                ? const Text('No plans available')
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _plans.map((p) {
                      final plan = p as Map<String, dynamic>;
                      final pid = plan['id'] as String;
                      final pname = plan['name'] as String? ?? '';
                      final cycle = plan['billingCycle'] as String? ?? '';
                      final price = plan['price'] as num? ?? 0;
                      final isActive = plan['isActive'] as bool? ?? true;
                      if (!isActive) return const SizedBox.shrink();

                      return RadioListTile<String>(
                        value: pid,
                        groupValue: selectedPlanId,
                        title: Text('$pname — $cycle',
                            style: const TextStyle(fontSize: 14)),
                        subtitle: Text('PKR ${_formatNum(price)}',
                            style: const TextStyle(fontSize: 12)),
                        activeColor: AppTheme.accent,
                        onChanged: (v) =>
                            setDialogState(() => selectedPlanId = v),
                      );
                    }).toList(),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedPlanId == null || saving
                  ? null
                  : () async {
                      setDialogState(() => saving = true);
                      try {
                        await _adminService.changeShopSubscription(
                            shopId, selectedPlanId!);
                        if (!ctx.mounted) return;
                        Navigator.of(ctx).pop();
                        _loadShops();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Plan changed successfully'),
                            backgroundColor: AppTheme.success,
                          ),
                        );
                      } catch (e) {
                        setDialogState(() => saving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AppTheme.error,
                            ),
                          );
                        }
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Change Plan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status, bool isActive) {
    if (!isActive && status == 'ACTIVE') {
      return _chipRaw('Suspended', AppTheme.warning);
    }
    Color color;
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        color = AppTheme.success;
        break;
      case 'EXPIRED':
        color = AppTheme.error;
        break;
      case 'PENDING':
        color = AppTheme.warning;
        break;
      default:
        color = Colors.grey;
    }
    return _chipRaw(
      status.isEmpty ? 'NONE' : '${status[0]}${status.substring(1).toLowerCase()}',
      color,
    );
  }

  Widget _chipRaw(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPagination() {
    final fromItem = ((_shopPage - 1) * _pageSize) + 1;
    final toItem = (_shopPage * _pageSize) > _totalShops
        ? _totalShops
        : (_shopPage * _pageSize);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.darkBorder.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$fromItem–$toItem of $_totalShops',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13),
          ),
          const SizedBox(width: AppTheme.spaceMd),
          ..._buildPageNumbers(),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers() {
    final pages = <Widget>[];
    final maxVisible = 5;
    int start = (_shopPage - 2).clamp(1, _totalPages - maxVisible + 1);
    int end = (start + maxVisible - 1).clamp(1, _totalPages);

    if (_totalPages <= maxVisible) {
      start = 1;
      end = _totalPages;
    }

    if (_shopPage > 1) {
      pages.add(_pageNumBtn(Icons.chevron_left, _shopPage - 1));
    }

    for (int i = start; i <= end; i++) {
      pages.add(_pageNumBtn(i));
    }

    if (_shopPage < _totalPages) {
      pages.add(_pageNumBtn(Icons.chevron_right, _shopPage + 1));
    }

    return pages;
  }

  Widget _pageNumBtn(dynamic pageOrIcon, [int? targetPage]) {
    final bool isIcon;
    final int page;
    final IconData? icon;

    if (pageOrIcon is IconData) {
      isIcon = true;
      icon = pageOrIcon;
      page = targetPage ?? 1;
    } else {
      isIcon = false;
      icon = null;
      page = pageOrIcon as int;
    }

    final isActive = !isIcon && page == _shopPage;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: isActive ? AppTheme.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          onTap: isActive
              ? null
              : () {
                  setState(() => _shopPage = page);
                  _loadShops();
                },
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            child: isIcon
                ? Icon(icon, size: 18, color: Colors.grey[400])
                : Text(
                    '$page',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? Colors.white : Colors.grey[400],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  String _formatNum(num n) {
    return n.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }
}
