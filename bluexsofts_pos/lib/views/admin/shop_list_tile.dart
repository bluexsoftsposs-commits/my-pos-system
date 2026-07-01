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
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: active ? AppTheme.primary.withOpacity(0.15) : Colors.grey.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.store, color: active ? AppTheme.primary : Colors.grey, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shop['shopName'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Plan: $plan | Users: ${shop['_count']?['users'] ?? 0} | Sales: ${shop['_count']?['sales'] ?? 0}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: active
                              ? AppTheme.success.withOpacity(0.15)
                              : AppTheme.error.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          active ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 10,
                            color: active ? AppTheme.success : AppTheme.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton(
              color: AppTheme.darkSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'toggle', child: Row(
                  children: [Icon(Icons.toggle_on, size: 18), SizedBox(width: 8), Text('Toggle Active')],
                )),
                const PopupMenuItem(value: 'extend', child: Row(
                  children: [Icon(Icons.date_range, size: 18), SizedBox(width: 8), Text('Extend 30 days')],
                )),
              ],
              onSelected: (v) {
                if (v == 'toggle') onToggle();
                if (v == 'extend') onExtend();
              },
            ),
          ],
        ),
      ),
    );
  }
}
