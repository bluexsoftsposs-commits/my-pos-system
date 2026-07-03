import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../services/plan_service.dart';
import '../core/theme.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  final _service = PlanService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthProvider>();
      final shopId = auth.shop?.id;
      if (shopId != null) {
        _data = await _service.getSubscription(shopId);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load subscription data')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sub = _data?['subscription'] as Map<String, dynamic>?;
    final usage = _data?['usage'] as Map<String, dynamic>?;
    final plan = sub?['plan'] as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(title: const Text('My Plan')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppTheme.spaceMd),
                child: plan == null
                    ? _buildNoPlan()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildPlanCard(plan, sub),
                          const SizedBox(height: AppTheme.spaceLg),
                          if (usage != null) ...[
                            _buildUsageBar(
                              label: 'Products',
                              used: usage['productsUsed'] as int? ?? 0,
                              limit: usage['productsLimit'] as int? ?? 0,
                            ),
                            const SizedBox(height: AppTheme.spaceMd),
                            _buildUsageBar(
                              label: 'Sales Points',
                              used: usage['salesPointsUsed'] as int? ?? 0,
                              limit: usage['salesPointsLimit'] as int? ?? 0,
                            ),
                          ],
                          const SizedBox(height: AppTheme.spaceXl),
                          _buildUpgradeSection(),
                        ],
                      ),
              ),
            ),
    );
  }

  Widget _buildNoPlan() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: const Icon(Icons.subscriptions_outlined,
                  size: 40, color: AppTheme.warning),
            ),
            const SizedBox(height: AppTheme.spaceLg),
            Text(
              'No Active Plan',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spaceSm),
            Text(
              'You don\'t have an active subscription.\nContact us to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppTheme.spaceLg),
            _buildContactButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan, Map<String, dynamic>? sub) {
    final name = plan['name'] as String? ?? '';
    final billingCycle = plan['billingCycle'] as String? ?? '';
    final price = plan['price'] as num? ?? 0;
    final setupFee = plan['setupFee'] as num? ?? 0;
    final originalSetupFee = plan['originalSetupFee'] as num?;
    final endDate = sub?['endDate'] as String?;
    final status = sub?['status'] as String? ?? '';

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
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceLg),
            decoration: BoxDecoration(
              gradient: AppTheme.cardGradientBlue,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
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
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusFull),
                      ),
                      child: Text(
                        cycleLabel,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceMd),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'PKR ${_formatNum(price)}',
                      style: Theme.of(context)
                          .textTheme
                          .headlineLarge
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '/ $cycleLabel',
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceSm),
                Row(
                  children: [
                    Text(
                      'Setup: PKR ${_formatNum(setupFee)}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                    if (originalSetupFee != null &&
                        originalSetupFee > setupFee) ...[
                      const SizedBox(width: 8),
                      Text(
                        'PKR ${_formatNum(originalSetupFee)}',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.spaceLg),
            child: Column(
              children: [
                _buildFeatureRow(
                    plan, 'fbrConnect', 'FBR Connect', Icons.account_balance),
                const SizedBox(height: AppTheme.spaceSm),
                _buildFeatureRow(
                    plan, 'techSupport', 'Tech Support', Icons.headset_mic),
                const SizedBox(height: AppTheme.spaceSm),
                _buildFeatureRow(
                    plan, 'onlineStore', 'Online Store', Icons.storefront),
                const SizedBox(height: AppTheme.spaceSm),
                _buildFeatureRow(
                    plan, 'updates', 'Updates', Icons.system_update),
                if (status.isNotEmpty) ...[
                  const Divider(
                      color: AppTheme.darkBorder, height: AppTheme.spaceLg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Status',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)),
                      _buildStatusChip(status),
                    ],
                  ),
                  if (endDate != null) ...[
                    const SizedBox(height: AppTheme.spaceSm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Expires',
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                        Text(_formatDate(endDate),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(
      Map<String, dynamic> plan, String key, String label, IconData icon) {
    final included = plan[key] == true;
    return Row(
      children: [
        Icon(
          included ? Icons.check_circle : Icons.cancel_outlined,
          size: 20,
          color: included ? AppTheme.success : AppTheme.darkBorder,
        ),
        const SizedBox(width: AppTheme.spaceSm),
        Icon(icon,
            size: 16,
            color: included
                ? Colors.white70
                : AppTheme.darkBorder),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: included
                ? Colors.white
                : AppTheme.darkBorder,
          ),
        ),
      ],
    );
  }

  Widget _buildUsageBar({
    required String label,
    required int used,
    required int limit,
  }) {
    final pct = limit > 0 ? used / limit : 0.0;
    Color barColor;
    if (pct >= 0.9) {
      barColor = AppTheme.error;
    } else if (pct >= 0.7) {
      barColor = AppTheme.warning;
    } else {
      barColor = AppTheme.success;
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.darkBorder.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              Text(
                '$used / $limit',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              backgroundColor: AppTheme.darkBorder.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation(barColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeSection() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.darkBorder.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: const Icon(Icons.support_agent,
                    color: AppTheme.accent, size: 22),
              ),
              const SizedBox(width: AppTheme.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Need to upgrade?',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Contact us to switch to a better plan.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMd),
          _buildContactButtons(),
        ],
      ),
    );
  }

  Widget _buildContactButtons() {
    return Row(
      children: [
        Expanded(
          child: _contactBtn(
            icon: Icons.phone,
            label: 'Call',
            onTap: () => _launchUrl('tel:+923247593673'),
          ),
        ),
        const SizedBox(width: AppTheme.spaceSm),
        Expanded(
          child: _contactBtn(
            icon: Icons.chat,
            label: 'WhatsApp',
            onTap: () => _launchUrl('https://wa.me/923247593673'),
          ),
        ),
      ],
    );
  }

  Widget _contactBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.accent,
        side: BorderSide(color: AppTheme.accent.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'active':
        color = AppTheme.success;
        break;
      case 'expired':
        color = AppTheme.error;
        break;
      default:
        color = AppTheme.warning;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    }
  }

  String _formatNum(num n) {
    return n.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
