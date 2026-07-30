import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';
import '../../core/currency_formatter.dart';
import '../../services/supplier_service.dart';
import 'supplier_ledger_screen.dart';

class AdminSuppliersScreen extends StatefulWidget {
  const AdminSuppliersScreen({super.key});

  @override
  State<AdminSuppliersScreen> createState() => _AdminSuppliersScreenState();
}

class _AdminSuppliersScreenState extends State<AdminSuppliersScreen> {
  List<dynamic> _suppliers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final resp = await ApiClient.get('/suppliers/shop');
      final result = ApiClient.parseResponse(resp);
      if (result['success']) {
        final data = result['data'] as Map<String, dynamic>;
        _suppliers = (data['suppliers'] as List<dynamic>?) ?? [];
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _showAddSupplierDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _AddSupplierDialog(onDone: _load),
    );
  }

  void _showLedger(Map<String, dynamic> supplier) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SupplierLedgerScreen(supplier: supplier),
      ),
    );
  }

  void _showTransactionDialog(Map<String, dynamic> supplier) {
    showDialog(
      context: context,
      builder: (ctx) => _TransactionDialog(
        supplierId: supplier['id'],
        onDone: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1024;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Suppliers',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Suppliers linked to your shop.',
                            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _showAddSupplierDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Supplier'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _suppliers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person_outline, size: 64, color: Colors.grey[600]),
                                const SizedBox(height: 16),
                                Text('No suppliers linked to your shop',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                              ],
                            ),
                          )
                        : isDesktop
                            ? _buildDesktopList()
                            : _buildMobileList(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDesktopList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppTheme.darkCard),
          dataRowColor: WidgetStateProperty.all(Colors.transparent),
          horizontalMargin: 16,
          columnSpacing: 24,
          showCheckboxColumn: false,
          border: TableBorder(
            horizontalInside: BorderSide(color: AppTheme.darkBorder.withValues(alpha: 0.3), width: 0.5),
          ),
          columns: [
            DataColumn(label: _header('Business Name')),
            DataColumn(label: _header('Contact Person')),
            DataColumn(label: _header('Phone')),
            DataColumn(label: _header('Balance')),
            DataColumn(label: _header('Actions'), numeric: true),
          ],
          rows: _suppliers.map((s) {
            final bal = (s['pendingBalance'] as num?)?.toDouble() ?? 0;
            return DataRow(cells: [
              DataCell(Text('${s['businessName']}', style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Text('${s['supplierName']}')),
              DataCell(Text('${s['phone']}')),
              DataCell(Text(CurrencyFormatter.format(bal),
                style: TextStyle(color: bal > 0 ? AppTheme.error : AppTheme.success, fontWeight: FontWeight.w600))),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _action(Icons.account_balance_wallet, AppTheme.info, () => _showLedger(s)),
                  const SizedBox(width: 8),
                  _action(Icons.add_circle_outline, AppTheme.success, () => _showTransactionDialog(s)),
                ],
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _suppliers.length,
      itemBuilder: (_, i) {
        final s = _suppliers[i];
        final bal = (s['pendingBalance'] as num?)?.toDouble() ?? 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.darkBorder.withValues(alpha: 0.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.person, color: AppTheme.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${s['businessName']}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          Text('${s['supplierName']}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('Balance: ', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                    Text(CurrencyFormatter.format(bal),
                      style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14,
                        color: bal > 0 ? AppTheme.error : AppTheme.success,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => _showLedger(s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Ledger', style: TextStyle(fontSize: 12, color: AppTheme.info, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _showTransactionDialog(s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Transaction', style: TextStyle(fontSize: 12, color: AppTheme.success, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _header(String t) => Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: Colors.grey));

  Widget _action(IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

// ── Add Supplier Dialog ─────────────────────────────────────────────

class _AddSupplierDialog extends StatefulWidget {
  final VoidCallback onDone;
  const _AddSupplierDialog({required this.onDone});

  @override
  State<_AddSupplierDialog> createState() => _AddSupplierDialogState();
}

class _AddSupplierDialogState extends State<_AddSupplierDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _businessCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _businessCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    _gstCtrl.dispose();
    _panCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ApiClient.post('/suppliers/shop/create', {
        'supplierName': _nameCtrl.text.trim(),
        'businessName': _businessCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'state': _stateCtrl.text.trim(),
        'pincode': _pincodeCtrl.text.trim(),
        'gstNumber': _gstCtrl.text.trim(),
        'panNumber': _panCtrl.text.trim(),
      });
      if (!mounted) return;
      Navigator.pop(context);
      widget.onDone();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Supplier added'), backgroundColor: AppTheme.success),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add supplier'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Add Supplier'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Supplier Name *', prefixIcon: Icon(Icons.person)),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _businessCtrl,
                  decoration: const InputDecoration(labelText: 'Business Name', prefixIcon: Icon(Icons.business)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone *', prefixIcon: Icon(Icons.phone)),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on)),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextFormField(
                      controller: _cityCtrl,
                      decoration: const InputDecoration(labelText: 'City', prefixIcon: Icon(Icons.location_city)),
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: TextFormField(
                      controller: _stateCtrl,
                      decoration: const InputDecoration(labelText: 'State'),
                    )),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextFormField(
                      controller: _pincodeCtrl,
                      decoration: const InputDecoration(labelText: 'Pincode'),
                      keyboardType: TextInputType.number,
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: TextFormField(
                      controller: _gstCtrl,
                      decoration: const InputDecoration(labelText: 'GST No.'),
                    )),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _panCtrl,
                  decoration: const InputDecoration(labelText: 'PAN No.'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Add Supplier'),
        ),
      ],
    );
  }
}

// ── Transaction Dialog ──────────────────────────────────────────────

class _TransactionDialog extends StatefulWidget {
  final String supplierId;
  final VoidCallback onDone;
  const _TransactionDialog({required this.supplierId, required this.onDone});

  @override
  State<_TransactionDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends State<_TransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'PURCHASE';
  final _amountCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _refCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ApiClient.post('/suppliers/${widget.supplierId}/shop-transactions', {
        'type': _type,
        'amount': double.parse(_amountCtrl.text),
        'referenceNo': _refCtrl.text,
        'description': _descCtrl.text,
      });
      if (!mounted) return;
      Navigator.pop(context);
      widget.onDone();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to record transaction'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Record Transaction'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _type,
                dropdownColor: AppTheme.darkCard,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'PURCHASE', child: Text('Purchase')),
                  DropdownMenuItem(value: 'PAYMENT', child: Text('Payment')),
                  DropdownMenuItem(value: 'RETURN', child: Text('Return')),
                ],
                onChanged: (v) => setState(() => _type = v ?? 'PURCHASE'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _refCtrl,
                decoration: const InputDecoration(labelText: 'Reference No. (optional)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
        ),
      ],
    );
  }
}
