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

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: role == 'ADMIN' ? AppTheme.primary.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
          child: Icon(
            role == 'ADMIN' ? Icons.admin_panel_settings : Icons.person,
            color: role == 'ADMIN' ? AppTheme.primary : Colors.grey,
          ),
        ),
        title: Text(user['name'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user['email'] as String? ?? ''),
            Row(
              children: [
                Text('$role', style: TextStyle(fontSize: 11, color: AppTheme.info)),
                const SizedBox(width: 8),
                Text(active ? 'Active' : 'Inactive', style: TextStyle(fontSize: 11, color: active ? AppTheme.success : AppTheme.error)),
                const SizedBox(width: 8),
                Text(user['shop']?['shopName'] ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
        trailing: active
            ? IconButton(
                icon: const Icon(Icons.block, color: AppTheme.error),
                onPressed: onDeactivate,
              )
            : null,
      ),
    );
  }
}
