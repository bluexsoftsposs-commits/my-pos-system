import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';
import '../../core/currency_formatter.dart';

class SupplierLedgerScreen extends StatefulWidget {
  final Map<String, dynamic> supplier;
  const SupplierLedgerScreen({super.key, required this.supplier});

  @override
  State<SupplierLedgerScreen> createState() => _SupplierLedgerScreenState();
}

class _SupplierLedgerScreenState extends State<SupplierLedgerScreen> {
  List<dynamic> _transactions = [];
  bool _loading = true;
  int _page = 1;
  int _totalPages = 1;
  String? _typeFilter;
  DateTimeRange? _dateRange;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
        if (_page < _totalPages) _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _page = 1;
    _transactions = [];
    await _fetch();
    setState(() => _loading = false);
  }

  Future<void> _loadMore() async {
    _page++;
    await _fetch();
  }

  Future<void> _fetch() async {
    try {
      String url = '/suppliers/${widget.supplier['id']}/transactions?page=$_page&limit=50';
      if (_typeFilter != null) url += '&type=$_typeFilter';

      final resp = await ApiClient.get(url);
      final result = ApiClient.parseResponse(resp);
      if (result['success']) {
        final data = result['data'] as Map<String, dynamic>;
        final txns = data['transactions'] as List<dynamic>? ?? [];
        if (mounted) {
          setState(() {
            _transactions.addAll(txns);
            _totalPages = data['totalPages'] as int? ?? 1;
          });
        }
      }
    } catch (_) {}
  }

  List<dynamic> get _sortedTransactions {
    final sorted = List<dynamic>.from(_transactions);
    sorted.sort((a, b) {
      final da = DateTime.parse(a['createdAt'] as String);
      final db = DateTime.parse(b['createdAt'] as String);
      return da.compareTo(db);
    });

    if (_dateRange != null) {
      sorted.removeWhere((t) {
        final dt = DateTime.parse(t['createdAt'] as String);
        return dt.isBefore(_dateRange!.start) || dt.isAfter(_dateRange!.end.add(const Duration(days: 1)));
      });
    }
    return sorted;
  }

  double _computeRunningBalance(List<dynamic> txns, int index) {
    double balance = 0;
    for (int i = 0; i <= index && i < txns.length; i++) {
      final t = txns[i];
      final type = t['type'] as String? ?? '';
      final amount = (t['amount'] as num?)?.toDouble() ?? 0;
      if (type == 'PURCHASE') balance += amount;
      else if (type == 'PAYMENT') balance -= amount;
      else if (type == 'RETURN') balance -= amount;
    }
    return balance;
  }

  void _showDateFilter() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _dateRange ?? DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now),
      builder: (ctx, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppTheme.primary,
            surface: AppTheme.darkSurface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.supplier;
    final sales = (s['totalSalesValue'] as num?)?.toDouble() ?? 0;
    final payments = (s['totalPayments'] as num?)?.toDouble() ?? 0;
    final balance = (s['pendingBalance'] as num?)?.toDouble() ?? 0;
    final balanceColor = balance > 0 ? AppTheme.error : AppTheme.success;

    final txns = _sortedTransactions;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${s['businessName'] ?? s['supplierName'] ?? ''}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            Text('Supplier Ledger', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter by type',
            onPressed: () => _showTypeFilter(),
          ),
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Filter by date',
            onPressed: _showDateFilter,
          ),
          if (_typeFilter != null || _dateRange != null)
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: 'Clear filters',
              onPressed: () {
                setState(() {
                  _typeFilter = null;
                  _dateRange = null;
                });
              },
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryBar(sales, payments, balance, balanceColor),
          if (_typeFilter != null || _dateRange != null)
            _buildActiveFilters(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : txns.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.receipt_long, size: 64, color: Colors.grey[600]),
                            const SizedBox(height: 16),
                            Text('No transactions', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(16),
                        itemCount: txns.length + (_page < _totalPages ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= txns.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          final t = txns[index];
                          final runningBal = _computeRunningBalance(txns, index);
                          return _buildTransactionTile(t, runningBal);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(double sales, double payments, double balance, Color balanceColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        border: Border(bottom: BorderSide(color: AppTheme.darkBorder.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          Expanded(
            child: _summaryItem('Purchases', CurrencyFormatter.format(sales), AppTheme.primary, Icons.shopping_cart),
          ),
          Container(width: 1, height: 40, color: AppTheme.darkBorder.withValues(alpha: 0.3)),
          Expanded(
            child: _summaryItem('Payments', CurrencyFormatter.format(payments), AppTheme.success, Icons.payments),
          ),
          Container(width: 1, height: 40, color: AppTheme.darkBorder.withValues(alpha: 0.3)),
          Expanded(
            child: _summaryItem('Balance', CurrencyFormatter.format(balance), balanceColor,
              balance > 0 ? Icons.warning : Icons.check_circle),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: color)),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
      ],
    );
  }

  Widget _buildActiveFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.darkCard,
      child: Row(
        children: [
          if (_typeFilter != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('Type: $_typeFilter', style: const TextStyle(fontSize: 12, color: AppTheme.primary)),
            ),
          if (_typeFilter != null && _dateRange != null) const SizedBox(width: 8),
          if (_dateRange != null)
            Expanded(
              child: Text(
                '${_dateRange!.start.day}/${_dateRange!.start.month}/${_dateRange!.start.year} - ${_dateRange!.end.day}/${_dateRange!.end.month}/${_dateRange!.end.year}',
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> t, double runningBal) {
    final type = t['type'] as String? ?? '';
    final amount = (t['amount'] as num?)?.toDouble() ?? 0;
    final date = t['createdAt'] as String? ?? '';
    final ref = t['referenceNo'] as String? ?? '';
    final desc = t['description'] as String? ?? '';

    Color typeColor;
    IconData typeIcon;
    String typeLabel;
    bool isCredit;

    switch (type) {
      case 'PURCHASE':
        typeColor = const Color(0xFF6C5CE7);
        typeIcon = Icons.shopping_cart;
        typeLabel = 'Stock Received';
        isCredit = true;
        break;
      case 'PAYMENT':
        typeColor = const Color(0xFF00B894);
        typeIcon = Icons.payments;
        typeLabel = 'Payment Made';
        isCredit = false;
        break;
      case 'RETURN':
        typeColor = const Color(0xFFD63031);
        typeIcon = Icons.replay;
        typeLabel = 'Return';
        isCredit = false;
        break;
      default:
        typeColor = Colors.grey;
        typeIcon = Icons.receipt;
        typeLabel = type;
        isCredit = false;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.darkBorder.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(typeIcon, color: typeColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(typeLabel, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    if (ref.isNotEmpty)
                      Text('Ref: $ref', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  ],
                ),
              ),
              Text(
                CurrencyFormatter.format(amount),
                style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 15,
                  color: isCredit ? AppTheme.primary : AppTheme.success,
                ),
              ),
            ],
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(desc, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              Text(_formatDate(date), style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              const Spacer(),
              Text(
                'Balance: ${CurrencyFormatter.format(runningBal)}',
                style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: runningBal > 0 ? AppTheme.error : AppTheme.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTypeFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Filter by Type', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.all_inclusive, color: Colors.white),
                title: const Text('All'),
                selected: _typeFilter == null,
                onTap: () { Navigator.pop(ctx); setState(() => _typeFilter = null); },
              ),
              ListTile(
                leading: const Icon(Icons.shopping_cart, color: Color(0xFF6C5CE7)),
                title: const Text('Stock Received'),
                selected: _typeFilter == 'PURCHASE',
                onTap: () { Navigator.pop(ctx); setState(() => _typeFilter = 'PURCHASE'); },
              ),
              ListTile(
                leading: const Icon(Icons.payments, color: Color(0xFF00B894)),
                title: const Text('Payment Made'),
                selected: _typeFilter == 'PAYMENT',
                onTap: () { Navigator.pop(ctx); setState(() => _typeFilter = 'PAYMENT'); },
              ),
              ListTile(
                leading: const Icon(Icons.replay, color: Color(0xFFD63031)),
                title: const Text('Return'),
                selected: _typeFilter == 'RETURN',
                onTap: () { Navigator.pop(ctx); setState(() => _typeFilter = 'RETURN'); },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr.split('T')[0];
    }
  }
}
