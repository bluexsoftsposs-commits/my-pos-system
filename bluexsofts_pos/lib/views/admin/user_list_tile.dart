import 'package:flutter/material.dart';
import '../../core/theme.dart';

class UserListTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onDeactivate;
  const UserListTile({super.key, required this.user, required this.onDeactivate});

  @override
  Widget build(BuildContext context) {
    final role = user['role'] as String? ?? '';
    final active = user['isActive'] as bool? ?? true;
    final roleColor = role == 'Admin' ? AppTheme.primary : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.darkBorder.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                role == 'Admin' ? Icons.admin_panel_settings : Icons.person,
                color: roleColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['name'] as String? ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user['email'] as String? ?? '',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(role, style: TextStyle(fontSize: 10, color: AppTheme.info)),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: active ? AppTheme.success.withOpacity(0.1) : AppTheme.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          active ? 'Active' : 'Inactive',
                          style: TextStyle(fontSize: 10, color: active ? AppTheme.success : AppTheme.error),
                        ),
                      ),
                      if (user['shop']?['shopName'] != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          user['shop']!['shopName'] as String,
                          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (active)
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.block, color: AppTheme.error, size: 20),
                  onPressed: onDeactivate,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
