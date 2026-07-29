import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/supplier_service.dart';
import '../core/theme.dart';
import '../core/currency_formatter.dart';
import '../views/shared/stat_card.dart';
import 'login_screen.dart';

class SupplierScreen extends StatefulWidget {
  const SupplierScreen({super.key});

  @override
  State<SupplierScreen> createState() => _SupplierScreenState();
}

class _SupplierScreenState extends State<SupplierScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _supplierService = SupplierService();

  Map<String, dynamic>? _stats;
  List<dynamic> _transactions = [];
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _supplierId;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final statsData = await _supplierService.getStats();
      if (statsData != null) {
        _stats = statsData['stats'] as Map<String, dynamic>?;
        _transactions = statsData['recentTransactions'] as List<dynamic>? ?? [];
        final userId = context.read<AuthProvider>().user?.id;
        if (userId != null) {
          final profileData = await _supplierService.getProfile(userId);
          if (profileData != null) {
            _profile = profileData['supplier'] as Map<String, dynamic>?;
            _supplierId = _profile?['id'] as String?;
          }
        }
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF00B894), Color(0xFF00CEC9)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text('Supplier Panel'),
          ],
        ),
        actions: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFD63031).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout, color: Color(0xFFD63031)),
              onPressed: () async {
                await auth.logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: const Color(0xFF00B894),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey[500],
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Ledger'),
            Tab(text: 'Transactions'),
            Tab(text: 'Profile'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _buildDashboardTab(),
                _buildLedgerTab(),
                _buildTransactionsTab(),
                _buildProfileTab(),
              ],
            ),
    );
  }

  Widget _buildDashboardTab() {
    final pendingBalance = (_stats?['pendingBalance'] as num?) ?? 0;
    final balanceColor = pendingBalance >= 0 ? const Color(0xFF00B894) : const Color(0xFFD63031);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF00B894), Color(0xFF00CEC9)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Supplier Dashboard', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Manage your transactions and ledger', style: TextStyle(color: Colors.white.withOpacity(0.7))),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_stats != null) ...[
          StatCard(
            title: 'Total Sales Value',
            value: CurrencyFormatter.formatWithDecimals((_stats!['totalSalesValue'] as num?) ?? 0),
            icon: Icons.trending_up,
            color: AppTheme.primary,
            gradient: AppTheme.cardGradientBlue,
          ),
          StatCard(
            title: 'Total Payments Received',
            value: CurrencyFormatter.formatWithDecimals((_stats!['totalPayments'] as num?) ?? 0),
            icon: Icons.payments,
            color: AppTheme.success,
            gradient: AppTheme.cardGradientGreen,
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [balanceColor.withOpacity(0.1), balanceColor.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: balanceColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: balanceColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                  child: Icon(pendingBalance >= 0 ? Icons.account_balance_wallet : Icons.warning, color: balanceColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pending Balance', style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.formatWithDecimals(pendingBalance),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: balanceColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              width: 4, height: 20,
              decoration: BoxDecoration(gradient: AppTheme.accentGradient, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 10),
            Text('Recent Transactions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 12),
        if (_transactions.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF201F1F),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(child: Text('No transactions yet', style: TextStyle(color: Colors.grey[500]))),
          )
        else
          ...(_transactions.take(5).map((t) {
            final tx = t as Map<String, dynamic>;
            final type = tx['type'] as String? ?? '';
            final amount = (tx['amount'] as num?) ?? 0;
            final typeColor = type == 'PURCHASE' ? const Color(0xFF6C5CE7) : type == 'PAYMENT' ? const Color(0xFF00B894) : const Color(0xFFD63031);
            final typeIcon = type == 'PURCHASE' ? Icons.shopping_cart : type == 'PAYMENT' ? Icons.payments : Icons.replay;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF201F1F),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: ListTile(
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: typeColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                  child: Icon(typeIcon, color: typeColor, size: 20),
                ),
                title: Text('$type - PKR ${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text(tx['referenceNo'] as String? ?? tx['description'] as String? ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
                trailing: Text(_formatDate(tx['createdAt'] as String? ?? ''), style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
              ),
            );
          })),
      ],
    );
  }

  Widget _buildLedgerTab() {
    if (_stats == null) return const Center(child: Text('No ledger data'));
    final pendingBalance = (_stats!['pendingBalance'] as num?) ?? 0;
    final balanceColor = pendingBalance >= 0 ? const Color(0xFF00B894) : const Color(0xFFD63031);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Container(
              width: 4, height: 20,
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF00B894), Color(0xFF00CEC9)]), borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 10),
            Text('Ledger Summary', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF201F1F),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(
            children: [
              _ledgerRow('Total Sales Value', CurrencyFormatter.formatWithDecimals((_stats!['totalSalesValue'] as num?) ?? 0), const Color(0xFF6C5CE7)),
              const Divider(color: Color(0xFF474554)),
              _ledgerRow('Total Payments', CurrencyFormatter.formatWithDecimals((_stats!['totalPayments'] as num?) ?? 0), const Color(0xFF00B894)),
              const Divider(color: Color(0xFF474554)),
              _ledgerRow('Pending Balance', CurrencyFormatter.formatWithDecimals(pendingBalance), balanceColor),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: balanceColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: balanceColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(pendingBalance >= 0 ? Icons.check_circle : Icons.error, color: balanceColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  pendingBalance >= 0
                      ? 'You are owed PKR ${pendingBalance.toStringAsFixed(2)}'
                      : 'You owe PKR ${(pendingBalance.abs()).toStringAsFixed(2)}',
                  style: TextStyle(color: balanceColor, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _ledgerRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF9E9E9E))),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showTransactionDialog('PURCHASE'),
                  icon: const Icon(Icons.shopping_cart, size: 18),
                  label: const Text('Purchase'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showTransactionDialog('PAYMENT'),
                  icon: const Icon(Icons.payments, size: 18),
                  label: const Text('Payment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00B894),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showTransactionDialog('RETURN'),
                  icon: const Icon(Icons.replay, size: 18),
                  label: const Text('Return'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD63031),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _transactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: Colors.grey[600]),
                      const SizedBox(height: 12),
                      Text('No transactions', style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final tx = _transactions[index] as Map<String, dynamic>;
                      final type = tx['type'] as String? ?? '';
                      final amount = (tx['amount'] as num?) ?? 0;
                      final typeColor = type == 'PURCHASE' ? const Color(0xFF6C5CE7) : type == 'PAYMENT' ? const Color(0xFF00B894) : const Color(0xFFD63031);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF201F1F),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(color: typeColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                                child: Icon(
                                  type == 'PURCHASE' ? Icons.shopping_cart : type == 'PAYMENT' ? Icons.payments : Icons.replay,
                                  color: typeColor, size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('$type - PKR ${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                    if (tx['referenceNo'] != null)
                                      Text('Ref: ${tx['referenceNo']}', style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
                                    if (tx['description'] != null)
                                      Text('${tx['description']}', style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
                                  ],
                                ),
                              ),
                              Text(_formatDate(tx['createdAt'] as String? ?? ''), style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildProfileTab() {
    final p = _profile;
    if (p == null) return const Center(child: Text('No profile data'));

    final isVerified = p['isVerified'] as bool? ?? false;
    final isActive = p['isActive'] as bool? ?? true;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF201F1F),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF00B894), Color(0xFF00CEC9)]),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    '${p['supplierName'] ?? '?'}'.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('${p['supplierName'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text('${p['businessName'] ?? ''}', style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isVerified ? const Color(0xFF00B894).withOpacity(0.1) : const Color(0xFFFDCB6E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(isVerified ? Icons.verified : Icons.pending, size: 14, color: isVerified ? const Color(0xFF00B894) : const Color(0xFFFDCB6E)),
                        const SizedBox(width: 4),
                        Text(isVerified ? 'Verified' : 'Pending Verification', style: TextStyle(fontSize: 12, color: isVerified ? const Color(0xFF00B894) : const Color(0xFFFDCB6E))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: isActive ? const Color(0xFF00B894) : const Color(0xFFD63031)),
                  ),
                  const SizedBox(width: 4),
                  Text(isActive ? 'Active' : 'Inactive', style: TextStyle(fontSize: 12, color: isActive ? const Color(0xFF00B894) : const Color(0xFFD63031))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF201F1F),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Business Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              _profileRow('Phone', '${p['phone'] ?? ''}'),
              _profileRow('Email', '${p['email'] ?? ''}'),
              _profileRow('Address', '${p['address'] ?? ''}'),
              _profileRow('City', '${p['city'] ?? ''}'),
              _profileRow('State', '${p['state'] ?? ''}'),
              _profileRow('Pincode', '${p['pincode'] ?? ''}'),
              if (p['gstNumber'] != null) _profileRow('GST No.', '${p['gstNumber']}'),
              if (p['panNumber'] != null) _profileRow('PAN No.', '${p['panNumber']}'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _showEditProfileDialog,
            icon: const Icon(Icons.edit),
            label: const Text('Edit Profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _profileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }

  void _showTransactionDialog(String type) {
    final amountCtrl = TextEditingController();
    final refCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF201F1F),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: type == 'PURCHASE' ? const Color(0xFF6C5CE7).withOpacity(0.15) : type == 'PAYMENT' ? const Color(0xFF00B894).withOpacity(0.15) : const Color(0xFFD63031).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  type == 'PURCHASE' ? Icons.shopping_cart : type == 'PAYMENT' ? Icons.payments : Icons.replay,
                  color: type == 'PURCHASE' ? const Color(0xFF6C5CE7) : type == 'PAYMENT' ? const Color(0xFF00B894) : const Color(0xFFD63031),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text('Record $type'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: amountCtrl,
                  decoration: const InputDecoration(labelText: 'Amount (PKR)', prefixIcon: Icon(Icons.attach_money)),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: refCtrl,
                  decoration: const InputDecoration(labelText: 'Reference No.', prefixIcon: Icon(Icons.receipt)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description)),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: saving ? null : () async {
                final amount = double.tryParse(amountCtrl.text);
                if (amount == null || amount <= 0) return;
                setDialogState(() => saving = true);
                try {
                  if (_supplierId == null) return;
                  await _supplierService.createTransaction(_supplierId!, {
                    'type': type,
                    'amount': amount,
                    'referenceNo': refCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                  });
                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop();
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$type recorded'), backgroundColor: const Color(0xFF00B894)),
                  );
                } catch (e) {
                  setDialogState(() => saving = false);
                }
              },
              child: saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('Record $type'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    if (_profile == null) return;
    final p = _profile!;
    final nameCtrl = TextEditingController(text: p['supplierName'] as String? ?? '');
    final businessCtrl = TextEditingController(text: p['businessName'] as String? ?? '');
    final gstCtrl = TextEditingController(text: p['gstNumber'] as String? ?? '');
    final panCtrl = TextEditingController(text: p['panNumber'] as String? ?? '');
    final bankAccCtrl = TextEditingController(text: p['bankAccountNo'] as String? ?? '');
    final bankNameCtrl = TextEditingController(text: p['bankName'] as String? ?? '');
    final ifscCtrl = TextEditingController(text: p['ifscCode'] as String? ?? '');
    final phoneCtrl = TextEditingController(text: p['phone'] as String? ?? '');
    final addressCtrl = TextEditingController(text: p['address'] as String? ?? '');
    final cityCtrl = TextEditingController(text: p['city'] as String? ?? '');
    final stateCtrl = TextEditingController(text: p['state'] as String? ?? '');
    final pincodeCtrl = TextEditingController(text: p['pincode'] as String? ?? '');
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF201F1F),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Supplier Name')),
                const SizedBox(height: 8),
                TextFormField(controller: businessCtrl, decoration: const InputDecoration(labelText: 'Business Name')),
                const SizedBox(height: 8),
                TextFormField(controller: gstCtrl, decoration: const InputDecoration(labelText: 'GST Number')),
                const SizedBox(height: 8),
                TextFormField(controller: panCtrl, decoration: const InputDecoration(labelText: 'PAN Number')),
                const SizedBox(height: 8),
                TextFormField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
                const SizedBox(height: 8),
                TextFormField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address')),
                const SizedBox(height: 8),
                TextFormField(controller: cityCtrl, decoration: const InputDecoration(labelText: 'City')),
                const SizedBox(height: 8),
                TextFormField(controller: stateCtrl, decoration: const InputDecoration(labelText: 'State')),
                const SizedBox(height: 8),
                TextFormField(controller: pincodeCtrl, decoration: const InputDecoration(labelText: 'Pincode')),
                const SizedBox(height: 8),
                const Text('Bank Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                TextFormField(controller: bankAccCtrl, decoration: const InputDecoration(labelText: 'Bank Account No.')),
                const SizedBox(height: 8),
                TextFormField(controller: bankNameCtrl, decoration: const InputDecoration(labelText: 'Bank Name')),
                const SizedBox(height: 8),
                TextFormField(controller: ifscCtrl, decoration: const InputDecoration(labelText: 'IFSC Code')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: saving ? null : () async {
                setDialogState(() => saving = true);
                try {
                  if (_supplierId == null) return;
                  await _supplierService.updateProfile(_supplierId!, {
                    'supplierName': nameCtrl.text.trim(),
                    'businessName': businessCtrl.text.trim(),
                    'gstNumber': gstCtrl.text.trim(),
                    'panNumber': panCtrl.text.trim(),
                    'bankAccountNo': bankAccCtrl.text.trim(),
                    'bankName': bankNameCtrl.text.trim(),
                    'ifscCode': ifscCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim(),
                    'address': addressCtrl.text.trim(),
                    'city': cityCtrl.text.trim(),
                    'state': stateCtrl.text.trim(),
                    'pincode': pincodeCtrl.text.trim(),
                  });
                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop();
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated'), backgroundColor: Color(0xFF00B894)),
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

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateStr.split('T')[0];
    }
  }
}
