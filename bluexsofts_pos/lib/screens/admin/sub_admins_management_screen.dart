import 'package:flutter/material.dart';
import '../../services/subadmin_service.dart';
import '../../core/theme.dart';

const _availablePermissions = [
  ('create_admin', 'Create Admins'),
  ('edit_admin', 'Edit Admins'),
  ('manage_shops', 'Manage Shops'),
  ('change_plan', 'Change Plans'),
  ('view_reports', 'View Reports'),
  ('manage_suppliers', 'Manage Suppliers'),
];

class SubAdminsManagementScreen extends StatefulWidget {
  const SubAdminsManagementScreen({super.key});

  @override
  State<SubAdminsManagementScreen> createState() => _SubAdminsManagementScreenState();
}

class _SubAdminsManagementScreenState extends State<SubAdminsManagementScreen> {
  final _service = SubAdminService();
  List<dynamic> _subAdmins = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getSubAdmins();
      if (data != null) _subAdmins = data['subAdmins'] ?? [];
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(gradient: AppTheme.accentGradient, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.admin_panel_settings, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text('Sub-Admins'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateDialog,
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _subAdmins.isEmpty
              ? const Center(child: Text('No sub-admins yet'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _subAdmins.length,
                  itemBuilder: (context, index) {
                    final sa = _subAdmins[index] as Map<String, dynamic>;
                    final perms = (sa['permissions'] as List? ?? []).cast<String>();
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
                                  decoration: BoxDecoration(gradient: AppTheme.accentGradient, borderRadius: BorderRadius.circular(10)),
                                  child: Center(
                                    child: Text(
                                      '${sa['name'] ?? '?'}'.substring(0, 1).toUpperCase(),
                                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${sa['name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                      Text('${sa['email'] ?? ''}', style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12)),
                                    ],
                                  ),
                                ),
                                PopupMenuButton(
                                  color: const Color(0xFF201F1F),
                                  icon: Icon(Icons.more_vert, color: Colors.grey[500]),
                                  onSelected: (v) {
                                    if (v == 'edit') _showEditDialog(sa);
                                    if (v == 'delete') _confirmDelete(sa);
                                  },
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit, color: Color(0xFF6C5CE7)), title: Text('Edit'))),
                                    const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Color(0xFFD63031)), title: Text('Delete'))),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (sa['title'] != null && sa['title'].toString().isNotEmpty)
                                  _chip(Icons.badge, '${sa['title']}'),
                                if (sa['region'] != null && sa['region'].toString().isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  _chip(Icons.location_on, '${sa['region']}'),
                                ],
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: sa['isActive'] == true ? const Color(0xFF00B894).withOpacity(0.1) : const Color(0xFFD63031).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    sa['isActive'] == true ? 'Active' : 'Inactive',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: sa['isActive'] == true ? const Color(0xFF00B894) : const Color(0xFFD63031)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (perms.isNotEmpty)
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: perms.map((p) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6C5CE7).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    p.replaceAll('_', ' '),
                                    style: const TextStyle(fontSize: 10, color: Color(0xFFC6BFFF)),
                                  ),
                                )).toList(),
                              )
                            else
                              const Text('No permissions assigned', style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
                          ],
                        ),
                      ),
                    );
                  },
                ),
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

  List<String> _defaultPermissions() => _availablePermissions.map((e) => e.$1).toList();

  void _showCreateDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    final regionCtrl = TextEditingController();
    final selectedPerms = _defaultPermissions().toSet();
    bool saving = false;
    bool isActive = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF201F1F),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Create Sub-Admin'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
                const SizedBox(height: 8),
                TextFormField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 8),
                TextFormField(controller: passwordCtrl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
                const SizedBox(height: 8),
                TextFormField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title (e.g., Regional Manager)')),
                const SizedBox(height: 8),
                TextFormField(controller: regionCtrl, decoration: const InputDecoration(labelText: 'Region')),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Permissions', style: Theme.of(context).textTheme.titleSmall),
                ),
                const SizedBox(height: 4),
                ..._availablePermissions.map((entry) {
                  final (value, label) = entry;
                  return CheckboxListTile(
                    title: Text(label, style: const TextStyle(fontSize: 13)),
                    value: selectedPerms.contains(value),
                    onChanged: (v) => setDialogState(() {
                      if (v == true) selectedPerms.add(value); else selectedPerms.remove(value);
                    }),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: saving ? null : () async {
                setDialogState(() => saving = true);
                try {
                  await _service.createSubAdmin({
                    'name': nameCtrl.text.trim(),
                    'email': emailCtrl.text.trim(),
                    'password': passwordCtrl.text.trim(),
                    'title': titleCtrl.text.trim(),
                    'region': regionCtrl.text.trim(),
                    'permissions': selectedPerms.toList(),
                    'isActive': isActive,
                  });
                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop();
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sub-admin created'), backgroundColor: Color(0xFF00B894)),
                  );
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

  void _showEditDialog(Map<String, dynamic> sa) {
    final titleCtrl = TextEditingController(text: sa['title'] as String? ?? '');
    final regionCtrl = TextEditingController(text: sa['region'] as String? ?? '');
    final selectedPerms = (sa['permissions'] as List? ?? []).cast<String>().toSet();
    bool saving = false;
    bool isActive = sa['isActive'] as bool? ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF201F1F),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit Sub-Admin'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
                const SizedBox(height: 8),
                TextFormField(controller: regionCtrl, decoration: const InputDecoration(labelText: 'Region')),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Active'),
                  value: isActive,
                  onChanged: (v) => setDialogState(() => isActive = v),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Permissions', style: Theme.of(context).textTheme.titleSmall),
                ),
                const SizedBox(height: 4),
                ..._availablePermissions.map((entry) {
                  final (value, label) = entry;
                  return CheckboxListTile(
                    title: Text(label, style: const TextStyle(fontSize: 13)),
                    value: selectedPerms.contains(value),
                    onChanged: (v) => setDialogState(() {
                      if (v == true) selectedPerms.add(value); else selectedPerms.remove(value);
                    }),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: saving ? null : () async {
                setDialogState(() => saving = true);
                try {
                  await _service.updateSubAdmin(sa['id'] as String, {
                    'title': titleCtrl.text.trim(),
                    'region': regionCtrl.text.trim(),
                    'permissions': selectedPerms.toList(),
                    'isActive': isActive,
                  });
                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop();
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Updated'), backgroundColor: Color(0xFF00B894)),
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

  void _confirmDelete(Map<String, dynamic> sa) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF201F1F),
        title: const Text('Delete Sub-Admin'),
        content: Text('Delete ${sa['name'] ?? ''}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD63031)),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _service.deleteSubAdmin(sa['id'] as String);
              _loadData();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
