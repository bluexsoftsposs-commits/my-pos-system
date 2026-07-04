import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/plan_service.dart';
import '../core/theme.dart';
import '../core/currency_formatter.dart';
import '../core/env_config.dart';
import 'login_screen.dart';
import 'plans_screen.dart';
import '../services/printer_service.dart';
import '../services/printer_settings_service.dart';
import '../views/settings/printer_settings_sheet.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _taxCtrl;
  final _planService = PlanService();
  Map<String, dynamic>? _subData;
  bool _loadingPlan = true;

  @override
  void initState() {
    super.initState();
    final cart = context.read<CartProvider>();
    _taxCtrl = TextEditingController(text: (cart.taxRate * 100).toStringAsFixed(0));
    _loadPlan();
  }

  @override
  void dispose() {
    _taxCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPlan() async {
    try {
      final auth = context.read<AuthProvider>();
      final shopId = auth.shop?.id;
      if (shopId != null) {
        _subData = await _planService.getSubscription(shopId);
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingPlan = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cart = context.watch<CartProvider>();
    final shop = auth.shop;

    final sub = _subData?['subscription'] as Map<String, dynamic>?;
    final usage = _subData?['usage'] as Map<String, dynamic>?;
    final plan = sub?['plan'] as Map<String, dynamic>?;

    final productsUsed = usage?['productsUsed'] as int? ?? 0;
    final productsLimit = usage?['productsLimit'] as int? ?? 0;
    final planName = plan?['name'] as String? ?? '';
    final billingCycle = plan?['billingCycle'] as String? ?? '';
    final planPrice = plan?['price'] as num? ?? 0;
    final fbrConnect = plan?['fbrConnect'] == true;
    final onlineStore = plan?['onlineStore'] == true;
    final techSupport = plan?['techSupport'] == true;
    final salesPointsLimit = plan?['salesPointsLimit'] as int? ?? 1;

    final hasActivePlan = plan != null;
    final endDateStr = sub?['endDate'] as String?;
    final endDate = endDateStr != null ? DateTime.tryParse(endDateStr) : null;
    final daysRemaining = endDate != null ? endDate.difference(DateTime.now()).inDays.clamp(0, 99999) : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── My Plan ──────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2D1B69), Color(0xFF6C5CE7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.subscriptions, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text('My Plan', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w700,
                  )),
                ],
              ),
              const SizedBox(height: 16),
              if (_loadingPlan)
                const SizedBox(
                  height: 40,
                  child: Center(child: CircularProgressIndicator(color: Colors.white)),
                )
              else if (!hasActivePlan) ...[
                Text('No Active Plan', style: const TextStyle(color: Colors.white70, fontSize: 15)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PlansScreen()),
                    ),
                    icon: const Icon(Icons.upgrade, size: 18),
                    label: const Text('Choose a Plan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF6C5CE7),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$planName — ${billingCycle[0]}${billingCycle.substring(1).toLowerCase()}',
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${CurrencyFormatter.format(planPrice)}/mo',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        daysRemaining != null ? '$daysRemaining days left' : 'Active',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                if (endDate != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Renewal: ${DateFormat('MMM dd, yyyy').format(endDate)}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                  ),
                ],
                if (productsLimit > 0) ...[
                  const SizedBox(height: 14),
                  _buildUsageBar(productsUsed, productsLimit),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Feature Checklist ────────────────────────────────
        if (plan != null) ...[
          _buildFeatureChecklist(planName, salesPointsLimit, fbrConnect, onlineStore, techSupport),
          const SizedBox(height: 16),
        ],

        // ── Shop Information ─────────────────────────────────
        _buildSection(
          icon: Icons.store,
          title: 'Shop Information',
          children: [
            _infoRow('Shop Name', shop?.shopName ?? 'N/A'),
            _infoRow('Plan', planName.isNotEmpty ? planName : (shop?.subscriptionPlan ?? 'NONE')),
            if (endDate != null) _infoRow('Expiry', DateFormat('MMM dd, yyyy').format(endDate)),
            _infoRow('Status', shop?.isActive == true ? 'Active' : 'Inactive'),
          ],
        ),
        const SizedBox(height: 12),

        // ── User Profile ─────────────────────────────────────
        _buildSection(
          icon: Icons.person,
          title: 'User Profile',
          children: [
            _infoRow('Name', auth.user?.name ?? 'N/A'),
            _infoRow('Email', auth.user?.email ?? 'N/A'),
            _infoRow('Role', auth.user?.role ?? 'N/A'),
          ],
        ),
        const SizedBox(height: 12),

        // ── Printer Settings ────────────────────────────────
        _buildSection(
          icon: Icons.print,
          title: 'Printer Settings',
          children: [
            FutureBuilder<PrinterConfig>(
              future: PrinterSettingsService.loadConfig(),
              builder: (context, snapshot) {
                final config = snapshot.data ?? const PrinterConfig();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          config.enabled
                              ? Icons.check_circle
                              : Icons.cancel,
                          size: 18,
                          color: config.enabled
                              ? AppTheme.success
                              : AppTheme.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          config.enabled
                              ? 'Printer connected'
                              : 'No printer configured',
                          style: TextStyle(
                            color: config.enabled
                                ? AppTheme.success
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    if (config.enabled)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          config.type == PrinterType.wifi
                              ? 'WiFi: ${config.wifiIp ?? "N/A"}:${config.wifiPort}'
                              : 'Bluetooth: ${config.bluetoothMac ?? "N/A"}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final result = await showModalBottomSheet<bool>(
                            context: context,
                            backgroundColor: const Color(0xFF201F1F),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                            ),
                            builder: (_) => PrinterSettingsSheet(
                              initialConfig: config,
                            ),
                          );
                          if (result == true && mounted) {
                            setState(() {});
                          }
                        },
                        icon: const Icon(Icons.settings, size: 18),
                        label: const Text('Configure Printer'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Tax Settings ────────────────────────────────────
        _buildSection(
          icon: Icons.percent,
          title: 'Tax Settings',
          children: [
            TextFormField(
              controller: _taxCtrl,
              decoration: const InputDecoration(
                labelText: 'Tax Rate (%)',
                suffixText: '%',
                prefixIcon: Icon(Icons.percent),
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) {
                final rate = double.tryParse(v);
                if (rate != null) {
                  cart.setTaxRate(rate / 100);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── App Info ─────────────────────────────────────────
        _buildSection(
          icon: Icons.info_outline,
          title: 'App Info',
          children: [
            _infoRow('Version', '1.0.0'),
            _infoRow('API URL', EnvConfig.apiBaseUrl),
          ],
        ),
        const SizedBox(height: 24),

        // ── Logout ───────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _logout(auth),
            icon: const Icon(Icons.logout, color: AppTheme.error),
            label: const Text('Logout', style: TextStyle(color: AppTheme.error)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.error),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // ── Reusable section card ─────────────────────────────────
  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF201F1F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    gradient: AppTheme.accentGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }

  // ── Usage bar (reused from products screen) ───────────────
  Widget _buildUsageBar(int used, int limit) {
    final pct = limit > 0 ? (used / limit) : 0.0;
    Color barColor;
    if (pct >= 0.9) {
      barColor = AppTheme.error;
    } else if (pct >= 0.7) {
      barColor = AppTheme.warning;
    } else {
      barColor = Colors.white;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.inventory_2, size: 14, color: Colors.white70),
            const SizedBox(width: 6),
            Text('Products', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
            const Spacer(),
            Text('$used / $limit', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: Colors.white.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation(barColor),
          ),
        ),
      ],
    );
  }

  // ── Feature checklist ─────────────────────────────────────
  Widget _buildFeatureChecklist(String planName, int salesPoints, bool hasFbr, bool hasStore, bool hasSupport) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF201F1F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    gradient: AppTheme.accentGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.checklist, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 10),
                const Text('Plan Features', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 12),
            _featureRow(Icons.people, 'Sales Points', '$salesPoints sales point${salesPoints > 1 ? 's' : ''}', null),
            const Divider(color: Color(0xFF2A2A2A), height: 1),
            _featureRow(Icons.account_balance, 'FBR Connect',
              hasFbr ? 'Connected' : 'Not available on your plan — upgrade to Plus or Pro',
              hasFbr ? null : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PlansScreen())),
            ),
            const Divider(color: Color(0xFF2A2A2A), height: 1),
            _featureRow(Icons.storefront, 'Online Store',
              hasStore ? 'Included' : 'Not available on your plan — upgrade to Pro',
              hasStore ? null : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PlansScreen())),
            ),
            const Divider(color: Color(0xFF2A2A2A), height: 1),
            _featureRow(Icons.support_agent, 'Tech Support',
              hasSupport ? 'Included' : 'Not available',
              null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureRow(IconData icon, String label, String subtitle, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF6C5CE7)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.white)),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: subtitle.startsWith('Not') ? const Color(0xFFD63031) : const Color(0xFF00B894))),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.lock, size: 16, color: const Color(0xFF9E9E9E))
            else
              const Icon(Icons.check_circle, size: 16, color: Color(0xFF00B894)),
          ],
        ),
      ),
    );
  }

  // ── Logout ────────────────────────────────────────────────
  Future<void> _logout(AuthProvider auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF201F1F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout', style: TextStyle(fontSize: 18)),
        content: const Text('Are you sure you want to logout?', style: TextStyle(color: Color(0xFFE0E0E0))),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Logout', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await auth.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}
