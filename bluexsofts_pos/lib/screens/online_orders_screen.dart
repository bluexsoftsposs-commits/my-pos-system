import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/currency_formatter.dart';
import '../providers/online_order_provider.dart';
import '../providers/auth_provider.dart';
import '../services/plan_service.dart';
import 'plans_screen.dart';

class OnlineOrdersScreen extends StatefulWidget {
  const OnlineOrdersScreen({super.key});

  @override
  State<OnlineOrdersScreen> createState() => _OnlineOrdersScreenState();
}

class _OnlineOrdersScreenState extends State<OnlineOrdersScreen> {
  bool? _hasOnlineStore;
  bool _checkingPlan = true;

  @override
  void initState() {
    super.initState();
    _checkPlan();
  }

  Future<void> _checkPlan() async {
    final auth = context.read<AuthProvider>();
    if (auth.isSuperAdmin) {
      setState(() { _hasOnlineStore = true; _checkingPlan = false; });
      context.read<OnlineOrderProvider>().loadOrders(status: 'PENDING');
      return;
    }

    final shopId = auth.shop?.id;
    if (shopId == null) {
      setState(() { _hasOnlineStore = false; _checkingPlan = false; });
      return;
    }

    try {
      final sub = await PlanService().getSubscription(shopId);
      final plan = sub?['subscription']?['plan'] as Map<String, dynamic>?;
      final hasStore = plan?['onlineStore'] == true;

      if (mounted) {
        setState(() { _hasOnlineStore = hasStore; _checkingPlan = false; });
        if (hasStore) {
          context.read<OnlineOrderProvider>().loadOrders(status: 'PENDING');
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() { _hasOnlineStore = false; _checkingPlan = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingPlan) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasOnlineStore != true) {
      return _buildLockedScreen();
    }

    return _buildOrdersScreen();
  }

  Widget _buildLockedScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Online Orders'),
        backgroundColor: AppTheme.darkCard,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.lock_outline, size: 40, color: AppTheme.warning),
              ),
              const SizedBox(height: 24),
              const Text(
                'Online Store Not Available',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Your current plan does not include an online store. '
                'Upgrade to Pro to start accepting online orders.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[400]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PlansScreen()),
                ),
                icon: const Icon(Icons.subscriptions),
                label: const Text('View Plans'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersScreen() {
    final provider = context.watch<OnlineOrderProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Online Orders'),
        backgroundColor: AppTheme.darkCard,
        actions: [
          if (provider.pendingCount > 0)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${provider.pendingCount} pending',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.error),
                ),
              ),
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.loadOrders(status: 'PENDING'),
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : provider.orders.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.orders.length,
                    itemBuilder: (context, index) {
                      return _OrderCard(
                        order: provider.orders[index] as Map<String, dynamic>,
                        onStatusChange: (newStatus) async {
                          final id = (provider.orders[index] as Map<String, dynamic>)['id'] as String;
                          await provider.updateStatus(id, newStatus);
                        },
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.storefront, size: 64, color: Colors.grey[700]),
          const SizedBox(height: 16),
          const Text('No pending orders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Online orders will appear here automatically.',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  final Map<String, dynamic> order;
  final Function(String) onStatusChange;

  const _OrderCard({required this.order, required this.onStatusChange});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _expanded = false;

  Color _statusColor(String status) {
    switch (status) {
      case 'PENDING': return const Color(0xFFF39C12);
      case 'CONFIRMED': return const Color(0xFF3498DB);
      case 'PREPARING': return const Color(0xFF9B59B6);
      case 'READY': return const Color(0xFF2ECC71);
      case 'COMPLETED': return const Color(0xFF27AE60);
      case 'CANCELLED': return const Color(0xFFE74C3C);
      default: return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'PENDING': return 'Pending';
      case 'CONFIRMED': return 'Confirmed';
      case 'PREPARING': return 'Preparing';
      case 'READY': return 'Ready';
      case 'COMPLETED': return 'Completed';
      case 'CANCELLED': return 'Cancelled';
      default: return status;
    }
  }

  List<Map<String, dynamic>> _nextValidStatuses(String current) {
    switch (current) {
      case 'PENDING': return [
        {'status': 'CONFIRMED', 'label': 'Confirm', 'color': const Color(0xFF3498DB)},
        {'status': 'CANCELLED', 'label': 'Cancel', 'color': const Color(0xFFE74C3C)},
      ];
      case 'CONFIRMED': return [
        {'status': 'PREPARING', 'label': 'Start Preparing', 'color': const Color(0xFF9B59B6)},
      ];
      case 'PREPARING': return [
        {'status': 'READY', 'label': 'Mark Ready', 'color': const Color(0xFF2ECC71)},
      ];
      case 'READY': return [
        {'status': 'COMPLETED', 'label': 'Complete', 'color': const Color(0xFF27AE60)},
      ];
      default: return [];
    }
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.order['status'] as String? ?? 'PENDING';
    final items = widget.order['items'] as List<dynamic>? ?? [];
    final total = (widget.order['totalAmount'] as num?)?.toDouble() ?? 0;
    final color = _statusColor(status);
    final nextStatuses = _nextValidStatuses(status);

    return Card(
      color: AppTheme.darkCard,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: color.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '#${(widget.order['id'] as String).substring(0, 8).toUpperCase()}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _statusLabel(status),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        CurrencyFormatter.format(total),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        widget.order['customerName'] as String? ?? '',
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.phone, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        widget.order['customerPhone'] as String? ?? '',
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(widget.order['createdAt'] as String? ?? ''),
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, color: Color(0xFF2A2A2A)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.order['customerAddress'] as String? ?? '',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Items', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  ...items.map((item) {
                    final itemMap = item as Map<String, dynamic>;
                    final product = itemMap['product'] as Map<String, dynamic>? ?? {};
                    final qty = (itemMap['quantity'] as num?)?.toInt() ?? 0;
                    final subtotal = (itemMap['subtotal'] as num?)?.toDouble() ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              product['name'] as String? ?? 'Item',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Text('x$qty', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(width: 16),
                          Text(CurrencyFormatter.format(subtotal), style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    );
                  }),
                  if (nextStatuses.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: nextStatuses.map((next) {
                        final isCancel = next['status'] == 'CANCELLED';
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: TextButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: AppTheme.darkSurface,
                                  title: Text('${isCancel ? 'Cancel' : 'Update'} Order'),
                                  content: Text(isCancel
                                      ? 'Stock will be restored. Are you sure?'
                                      : 'Mark order as ${next['label']}?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(),
                                      child: const Text('No'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(ctx).pop();
                                        widget.onStatusChange(next['status'] as String);
                                      },
                                      child: Text(isCancel ? 'Yes, Cancel' : 'Yes'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: Icon(
                              isCancel ? Icons.cancel_outlined : Icons.check_circle_outline,
                              size: 16,
                              color: next['color'] as Color,
                            ),
                            label: Text(
                              next['label'] as String,
                              style: TextStyle(fontSize: 12, color: next['color'] as Color),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
