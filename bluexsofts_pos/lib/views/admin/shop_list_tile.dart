import 'package:flutter/material.dart';
import '../../core/theme.dart';

class ShopListTile extends StatelessWidget {
  final Map<String, dynamic> shop;
  final VoidCallback onToggle;
  final VoidCallback onExtend;
  const ShopListTile({super.key, required this.shop, required this.onToggle, required this.onExtend});

  @override
  Widget build(BuildContext context) {
    final plan = shop['subscriptionPlan'] as String? ?? 'NONE';
    final status = shop['subscriptionStatus'] as String? ?? 'NONE';
    final active = shop['isActive'] as bool? ?? true;

    final statusColor = switch (status) {
      'ACTIVE' => AppTheme.success,
      'PENDING' => AppTheme.warning,
      'EXPIRED' => AppTheme.error,
      _ => Colors.grey,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: active ? AppTheme.primary.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
          child: Icon(Icons.store, color: active ? AppTheme.primary : Colors.grey),
        ),
        title: Text(shop['shopName'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Plan: $plan | Users: ${shop['_count']?['users'] ?? 0} | Sales: ${shop['_count']?['sales'] ?? 0}'),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(status, style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                Text(
                  active ? 'Active' : 'Inactive',
                  style: TextStyle(fontSize: 10, color: active ? AppTheme.success : AppTheme.error),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'toggle', child: Text('Toggle Active')),
            const PopupMenuItem(value: 'extend', child: Text('Extend 30 days')),
          ],
          onSelected: (v) {
            if (v == 'toggle') onToggle();
            if (v == 'extend') onExtend();
          },
        ),
      ),
    );
  }
}
