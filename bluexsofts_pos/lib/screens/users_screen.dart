import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/theme.dart';
import '../services/user_service.dart';
import '../services/plan_service.dart';
import 'plans_screen.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<dynamic> _users = [];
  bool _loading = true;
  bool _isRefreshing = false;
  int _currentPage = 1;
  static const int _pageSize = 5;
  final _userService = UserService();
  final _planService = PlanService();
  int _usersUsed = 0;
  int _usersLimit = 0;
  String _planName = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadPlanUsage();
  }

  Future<void> _loadPlanUsage() async {
    try {
      final auth = context.read<AuthProvider>();
      final shopId = auth.shop?.id;
      if (shopId == null) return;
      final data = await _planService.getSubscription(shopId);
      if (!mounted) return;
      final usage = data?['usage'] as Map<String, dynamic>?;
      final sub = data?['subscription'] as Map<String, dynamic>?;
      final plan = sub?['plan'] as Map<String, dynamic>?;
      setState(() {
        _usersUsed = usage?['salesPointsUsed'] as int? ?? 0;
        _usersLimit = usage?['salesPointsLimit'] as int? ?? 0;
        _planName = plan?['name'] as String? ?? '';
      });
    } catch (_) {}
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final data = await _userService.getUsers();
      if (data != null) _users = data;
    } catch (_) {}
    setState(() => _loading = false);
  }

  bool get _isAtLimit => _usersLimit > 0 && _usersUsed >= _usersLimit;

  List<dynamic> get _filteredUsers => _users;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final users = _filteredUsers;
    final totalItems = users.length;
    final activeCount = users.where((u) => u['isActive'] == true).length;
    final fromItem = totalItems > 0 ? ((_currentPage - 1) * _pageSize) + 1 : 0;
    final toItem = (_currentPage * _pageSize) > totalItems ? totalItems : (_currentPage * _pageSize);
    final totalPages = (totalItems / _pageSize).ceil();

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1200;

          if (isDesktop) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(auth),
                if (_usersLimit > 0) ...[
                  const SizedBox(height: AppTheme.spaceMd),
                  _buildSalesPointBanner(),
                ],
                const SizedBox(height: AppTheme.spaceLg),
                _buildStatsRow(users.length, activeCount),
                const SizedBox(height: AppTheme.spaceLg),
                Expanded(
                  child: _loading && users.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : users.isEmpty
                          ? _buildEmptyState()
                          : Column(
                              children: [
                                Expanded(
                                  child: _buildDesktopTable(users),
                                ),
                                if (totalItems > _pageSize)
                                  _buildPagination(totalItems, fromItem, toItem, totalPages),
                              ],
                            ),
                ),
              ],
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceMd, 0, AppTheme.spaceMd, AppTheme.spaceMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(auth),
                if (_usersLimit > 0) ...[
                  const SizedBox(height: AppTheme.spaceMd),
                  _buildSalesPointBanner(),
                ],
                const SizedBox(height: AppTheme.spaceLg),
                _buildStatsRow(users.length, activeCount),
                const SizedBox(height: AppTheme.spaceLg),
                if (_loading && users.isEmpty)
                  const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (users.isEmpty)
                  _buildEmptyState()
                else ...[
                  _buildMobileList(users),
                  if (totalItems > _pageSize)
                    _buildPagination(totalItems, fromItem, toItem, totalPages),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: auth.isAdmin
          ? FloatingActionButton.extended(
              onPressed: _isAtLimit ? null : _showCreateUserDialog,
              icon: const Icon(Icons.person_add),
              label: const Text('Add Staff'),
              backgroundColor: _isAtLimit ? Colors.grey : AppTheme.accent,
            )
          : null,
    );
  }

  Widget _buildHeader(AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.spaceMd, AppTheme.spaceMd, AppTheme.spaceMd, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cashiers & Staff',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage your team members and their access permissions.',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
          const SizedBox(height: AppTheme.spaceMd),
          Row(
            children: [
              _buildIconButton(Icons.download_outlined, 'Export', () =>
                  _exportCsv(_users)),
              const Spacer(),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _isRefreshing
                      ? null
                      : () async {
                          setState(() => _isRefreshing = true);
                          debugPrint('[Refresh] Starting getUsers…');
                          try {
                            final data = await _userService.getUsers();
                            debugPrint('[Refresh] getUsers done');
                            if (data != null) {
                              setState(() => _users = data);
                            }
                          } catch (e) {
                            debugPrint('[Refresh] error: $e');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to refresh: $e'),
                                  backgroundColor: AppTheme.error,
                                ),
                              );
                            }
                          } finally {
                            setState(() => _isRefreshing = false);
                          }
                        },
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    child: _isRefreshing
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          )
                        : Icon(Icons.refresh,
                            color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, String label, VoidCallback onTap) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          onTap: onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: Colors.grey[400]),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(int totalUsers, int activeUsers) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth >= 900 ? 2 : 2;

          return GridView.count(
            crossAxisCount: crossAxisCount,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppTheme.spaceMd,
            crossAxisSpacing: AppTheme.spaceMd,
            childAspectRatio: 2.4,
            children: [
              _buildStatCard('Total Users', '$totalUsers', AppTheme.primary, Icons.people),
              _buildStatCard('Active Users', '$activeUsers', AppTheme.success, Icons.verified_user),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color valueColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.darkBorder.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Icon(icon, size: 20, color: valueColor.withValues(alpha: 0.3)),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(List<dynamic> users) {
    final displayUsers = users
        .skip((_currentPage - 1) * _pageSize)
        .take(_pageSize)
        .toList();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg - 1),
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(AppTheme.darkCard),
                dataRowColor: WidgetStateProperty.all(Colors.transparent),
                headingRowHeight: 48,
                dataRowMinHeight: 56,
                dataRowMaxHeight: 64,
                horizontalMargin: AppTheme.spaceMd,
                columnSpacing: 32,
                showCheckboxColumn: false,
                border: TableBorder(
                  horizontalInside: BorderSide(color: AppTheme.darkBorder.withValues(alpha: 0.3), width: 0.5),
                ),
                columns: [
                  DataColumn(label: _buildHeaderText('Name')),
                  DataColumn(label: _buildHeaderText('Email')),
                  DataColumn(label: _buildHeaderText('Role')),
                  DataColumn(label: _buildHeaderText('Status')),
                  DataColumn(label: _buildHeaderText('Actions'), numeric: true),
                ],
                rows: displayUsers.map((u) {
                  final isCashier = u['role'] == 'CASHIER';
                  final roleColor = isCashier ? AppTheme.accent : AppTheme.primary;

                  return DataRow(
                    cells: [
                      DataCell(
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: roleColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isCashier ? Icons.person : Icons.admin_panel_settings,
                                color: roleColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text('${u['name']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      DataCell(
                        Text('${u['email']}', style: const TextStyle(fontSize: 14)),
                      ),
                      DataCell(_buildRoleBadge(u['role'] as String? ?? 'CASHIER')),
                      DataCell(_buildActiveBadge(u['isActive'] == true)),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (u['id'] != context.read<AuthProvider>().user?.id)
                              _buildActionIcon(
                                u['isActive'] == true ? Icons.toggle_on : Icons.toggle_off_outlined,
                                u['isActive'] == true ? AppTheme.success : AppTheme.error,
                                () async {
                                  await _userService.updateUser(u['id'], {'isActive': u['isActive'] != true});
                                  _loadUsers();
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 24, color: color),
        ),
      ),
    );
  }

  Widget _buildMobileList(List<dynamic> users) {
    final displayUsers = users
        .skip((_currentPage - 1) * _pageSize)
        .take(_pageSize)
        .toList();
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
      itemCount: displayUsers.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return const SizedBox(height: 0);
        final u = displayUsers[index - 1];
        return _buildUserCard(u);
      },
    );
  }

  Widget _buildUserCard(dynamic u) {
    final isCashier = u['role'] == 'CASHIER';
    final roleIcon = isCashier ? Icons.person : Icons.admin_panel_settings;
    final auth = context.read<AuthProvider>();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.darkBorder.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C5CE7), Color(0xFF8B7EF6)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(roleIcon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${u['name']}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (u['id'] != auth.user?.id)
                        InkWell(
                          onTap: () async {
                            await _userService.updateUser(u['id'], {'isActive': u['isActive'] != true});
                            _loadUsers();
                          },
                          child: Icon(
                            u['isActive'] == true ? Icons.toggle_on : Icons.toggle_off_outlined,
                            color: u['isActive'] == true ? AppTheme.success : AppTheme.error,
                            size: 28,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${u['email']}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildRoleBadge(u['role'] as String? ?? 'CASHIER'),
                      const SizedBox(width: 6),
                      _buildActiveBadge(u['isActive'] == true),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    final isCashier = role == 'CASHIER';
    final roleColor = isCashier ? AppTheme.accent : AppTheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: roleColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: roleColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: roleColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            role,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: roleColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.success.withValues(alpha: 0.15)
            : AppTheme.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(
          color: (isActive ? AppTheme.success : AppTheme.error).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? AppTheme.success : AppTheme.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isActive ? AppTheme.success : AppTheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.darkSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.darkBorder),
            ),
            child: Icon(Icons.people_outline, size: 40, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          const Text(
            'No users yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Staff members will appear here once added by an admin.',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(int totalItems, int fromItem, int toItem, int totalPages) {
    return Container(
      margin: const EdgeInsets.fromLTRB(AppTheme.spaceMd, 0, AppTheme.spaceMd, AppTheme.spaceSm),
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.darkBorder.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing $fromItem - $toItem of $totalItems users',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
          Row(
            children: [
              _buildPageButton(Icons.chevron_left, _currentPage > 1, () {
                setState(() => _currentPage--);
              }),
              const SizedBox(width: 4),
              ...() {
                if (totalPages <= 5) {
                  return List.generate(totalPages, (i) => i + 1);
                }
                final int start =
                    (_currentPage - 2).clamp(1, totalPages - 4);
                final int end = (start + 4).clamp(start, totalPages);
                return List.generate(end - start + 1, (i) => start + i);
              }().map((page) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: _buildPageNumber(page, page == _currentPage),
                  )),
              const SizedBox(width: 4),
              _buildPageButton(Icons.chevron_right, _currentPage < totalPages, () {
                setState(() => _currentPage++);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageButton(IconData icon, bool enabled, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: enabled ? onTap : null,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: enabled ? AppTheme.darkBorder : Colors.transparent),
          ),
          child: Icon(
            icon,
            size: 18,
            color: enabled ? Colors.grey[400] : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildPageNumber(int page, bool isActive) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: () => setState(() => _currentPage = page),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primary.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Center(
            child: Text(
              '$page',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isActive ? AppTheme.primary : Colors.grey[400],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _exportCsv(List<dynamic> users) {
    final buffer = StringBuffer();
    buffer.writeln('Name,Email,Role,Status');
    for (final u in users) {
      final name = u['name'] ?? '';
      final email = u['email'] ?? '';
      final role = u['role'] ?? 'CASHIER';
      final status = u['isActive'] == true ? 'Active' : 'Inactive';
      buffer.writeln('$name,$email,$role,$status');
    }
    final csv = buffer.toString();
    final bytes = utf8.encode(csv);
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'users_export.csv')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  void _showCreateUserDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String role = 'CASHIER';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.darkSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_add, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Add Staff Member'),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passwordCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: role,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      prefixIcon: Icon(Icons.badge),
                    ),
                    dropdownColor: AppTheme.darkSurface,
                    items: const [
                      DropdownMenuItem(value: 'CASHIER', child: Text('Cashier')),
                      DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
                    ],
                    onChanged: (v) => setDialogState(() => role = v ?? 'CASHIER'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                await _userService.createUser(
                  name: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  password: passwordCtrl.text.trim(),
                  role: role,
                );
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
                _loadUsers();
              },
              child: const Text('Add User'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesPointBanner() {
    final pct = _usersLimit > 0 ? (_usersUsed / _usersLimit).clamp(0.0, 1.0) : 0.0;
    Color barColor;
    if (pct >= 0.9) {
      barColor = AppTheme.error;
    } else if (pct >= 0.7) {
      barColor = AppTheme.warning;
    } else {
      barColor = AppTheme.success;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isAtLimit
                ? AppTheme.error.withValues(alpha: 0.3)
                : AppTheme.darkBorder.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isAtLimit ? Icons.lock : Icons.people,
                  size: 16,
                  color: _isAtLimit ? AppTheme.error : Colors.grey[400],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Sales Points ($_planName)',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Text(
                  '$_usersUsed / $_usersLimit',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[400]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation(barColor),
              ),
            ),
            if (_isAtLimit) ...[
              const SizedBox(height: 6),
              InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PlansScreen()),
                ),
                child: Text(
                  '🔒 You\'ve reached your sales point limit. Upgrade to add more.',
                  style: TextStyle(fontSize: 11, color: AppTheme.error, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
