import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/invoice_provider.dart';
import '../providers/auth_provider.dart';
import '../models/invoice.dart';
import '../core/theme.dart';
import '../services/receipt_service.dart';
import '../core/currency_formatter.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final _searchCtrl = TextEditingController();
  DateTimeRange? _dateRange;
  int _currentPage = 1;
  static const int _pageSize = 5;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<InvoiceProvider>().loadInvoices());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  DateTimeRange get _defaultMonth {
    final now = DateTime.now();
    return DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: now,
    );
  }

  DateTimeRange get _effectiveRange => _dateRange ?? _defaultMonth;

  Future<void> _load() async {
    final from = _dateRange != null
        ? DateFormat('yyyy-MM-dd').format(_dateRange!.start) + 'T00:00:00.000Z'
        : null;
    final to = _dateRange != null
        ? DateFormat('yyyy-MM-dd').format(_dateRange!.end) + 'T23:59:59.999Z'
        : null;
    final search = _searchCtrl.text.isNotEmpty ? _searchCtrl.text.trim() : null;
    await context.read<InvoiceProvider>().loadInvoices(from: from, to: to, search: search);
  }

  @override
  Widget build(BuildContext context) {
    final invProv = context.watch<InvoiceProvider>();
    final auth = context.watch<AuthProvider>();
    final invoices = invProv.invoices;
    final totalAmount = invoices.fold<double>(0, (sum, inv) => sum + inv.total);

    final totalItems = invoices.length;
    final fromItem = totalItems > 0 ? ((_currentPage - 1) * _pageSize) + 1 : 0;
    final toItem = (_currentPage * _pageSize) > totalItems ? totalItems : (_currentPage * _pageSize);
    final totalPages = (totalItems / _pageSize).ceil();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;

        if (isDesktop) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(invProv, invoices),
              const SizedBox(height: AppTheme.spaceLg),
              _buildStatsRow(invoices.length, totalAmount),
              const SizedBox(height: AppTheme.spaceLg),
              Expanded(
                child: invProv.isLoading && invoices.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : invoices.isEmpty
                        ? _buildEmptyState()
                        : Column(
                            children: [
                              Expanded(
                                child: _buildDesktopTable(invoices, auth.shop?.shopName),
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
              _buildHeader(invProv, invoices),
              const SizedBox(height: AppTheme.spaceLg),
              _buildStatsRow(invoices.length, totalAmount),
              const SizedBox(height: AppTheme.spaceLg),
              if (invProv.isLoading && invoices.isEmpty)
                const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (invoices.isEmpty)
                _buildEmptyState()
              else ...[
                _buildMobileList(invoices, auth.shop?.shopName),
                if (totalItems > _pageSize)
                  _buildPagination(totalItems, fromItem, toItem, totalPages),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(InvoiceProvider invProv, List<Invoice> invoices) {
    final range = _effectiveRange;
    final dateStr =
        '${DateFormat('MMM dd').format(range.start)} - ${DateFormat('MMM dd, yyyy').format(range.end)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.spaceMd, AppTheme.spaceMd, AppTheme.spaceMd, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Invoices',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage and track all generated invoices.',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
          const SizedBox(height: AppTheme.spaceMd),
          SizedBox(
            height: 40,
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by invoice number...',
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _currentPage = 1;
                          _load();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  borderSide: BorderSide(color: AppTheme.darkBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  borderSide: BorderSide(color: AppTheme.darkBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                ),
                filled: true,
                fillColor: AppTheme.darkSurface,
              ),
              onSubmitted: (_) {
                _currentPage = 1;
                _load();
              },
            ),
          ),
          const SizedBox(height: AppTheme.spaceSm),
          Row(
            children: [
              _buildDateRangePill(dateStr),
              const SizedBox(width: AppTheme.spaceSm),
              _buildIconButton(Icons.download_outlined, 'Export', () =>
                  _exportCsv(invoices)),
              const Spacer(),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: invProv.isLoading
                      ? null
                      : () async {
                          setState(() => _isRefreshing = true);
                          debugPrint('[Invoices Refresh] Starting _load…');
                          await _load();
                          debugPrint('[Invoices Refresh] _load done, error=${invProv.error}');
                          if (invProv.error != null && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(invProv.error!),
                                backgroundColor: AppTheme.error,
                              ),
                            );
                            invProv.clearError();
                          }
                          setState(() => _isRefreshing = false);
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

  Widget _buildDateRangePill(String dateStr) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        onTap: () => _pickDateRange(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today, size: 16, color: AppTheme.primary),
            const SizedBox(width: AppTheme.spaceSm),
            Text(
              dateStr,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 4),
            Icon(Icons.expand_more, size: 18, color: Colors.grey[500]),
          ],
        ),
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

  Widget _buildStatsRow(int count, double total) {
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
              _buildStatCard('Total Invoices', '$count', '', AppTheme.primary, Icons.receipt),
              _buildStatCard('Total Amount', CurrencyFormatter.format(total), '', AppTheme.success, Icons.account_balance_wallet),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, String trend, Color valueColor, IconData icon) {
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
              if (trend.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  trend,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.success,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(List<Invoice> invoices, String? shopName) {
    final displayInvoices = invoices
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
                  DataColumn(label: _buildHeaderText('Invoice #')),
                  DataColumn(label: _buildHeaderText('Date')),
                  DataColumn(label: _buildHeaderText('Amount'), numeric: true),
                  DataColumn(label: _buildHeaderText('Payment')),
                  DataColumn(label: _buildHeaderText('Actions'), numeric: true),
                ],
                rows: displayInvoices.map((inv) {
                  final dateStr = DateFormat('MMM dd, yyyy').format(inv.createdAt);
                  final timeStr = DateFormat('hh:mm a').format(inv.createdAt);

                  return DataRow(
                    onSelectChanged: (_) => _showInvoiceDetail(inv, shopName),
                    cells: [
                      DataCell(
                        Text(inv.invoiceNumber, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                      DataCell(
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dateStr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            Text(timeStr, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                          ],
                        ),
                      ),
                      DataCell(
                        Text(
                          CurrencyFormatter.formatWithDecimals(inv.total),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primary),
                        ),
                      ),
                      DataCell(Text(inv.paymentMethod, style: const TextStyle(fontSize: 14))),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _buildActionIcon(Icons.print_outlined, () {
                              if (inv.sale != null) {
                                ReceiptService.printReceipt(inv.sale!, shopName: shopName);
                              }
                            }),
                            const SizedBox(width: 4),
                            _buildActionIcon(Icons.more_vert, () => _showInvoiceDetail(inv, shopName)),
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

  Widget _buildActionIcon(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 20, color: Colors.grey[500]),
        ),
      ),
    );
  }

  Widget _buildMobileList(List<Invoice> invoices, String? shopName) {
    final displayInvoices = invoices
        .skip((_currentPage - 1) * _pageSize)
        .take(_pageSize)
        .toList();
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
      itemCount: displayInvoices.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return const SizedBox(height: 0);
        final inv = displayInvoices[index - 1];
        return _buildInvoiceCard(inv, shopName);
      },
    );
  }

  Widget _buildInvoiceCard(Invoice inv, String? shopName) {
    final dateStr = DateFormat('MMM dd, yyyy').format(inv.createdAt);
    final timeStr = DateFormat('hh:mm a').format(inv.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.darkBorder.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        onTap: () => _showInvoiceDetail(inv, shopName),
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
                child: const Icon(Icons.receipt, color: Colors.white, size: 22),
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
                            inv.invoiceNumber,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.primary),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          CurrencyFormatter.formatWithDecimals(inv.total),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          '$dateStr • $timeStr',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildPaidBadge(),
                        const SizedBox(width: 8),
                        Icon(Icons.payment, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 2),
                        Text(
                          inv.paymentMethod,
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                        if (inv.user != null) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.person_outline, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 2),
                          Text(
                            '${inv.user?['name'] ?? ''}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[600], size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaidBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: const Color(0xFF6DFAD2).withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF6DFAD2),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'Paid',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6DFAD2),
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
            child: Icon(Icons.receipt_long_outlined, size: 40, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          const Text(
            'No invoices yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Invoices will appear here once sales are completed.',
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
            'Showing $fromItem - $toItem of $totalItems invoices',
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

  void _exportCsv(List<Invoice> invoices) {
    final buffer = StringBuffer();
    buffer.writeln('Date,Invoice #,Amount,Payment Method');
    for (final inv in invoices) {
      final date = DateFormat('yyyy-MM-dd').format(inv.createdAt);
      buffer.writeln('$date,${inv.invoiceNumber},${inv.total.toStringAsFixed(2)},${inv.paymentMethod}');
    }
    final csv = buffer.toString();
    final bytes = utf8.encode(csv);
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'invoices_export.csv')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      initialDateRange: _effectiveRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primary,
              surface: AppTheme.darkSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateRange = picked;
        _currentPage = 1;
      });
      _load();
    }
  }

  void _showInvoiceDetail(Invoice inv, String? shopName) {
    final dateStr = DateFormat('MMM dd, yyyy  hh:mm a').format(inv.createdAt);
    final sale = inv.sale;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMd),
            child: ListView(
              controller: scrollController,
              children: [
                _buildDetailHeader(inv, dateStr, sale, shopName),
                const SizedBox(height: AppTheme.spaceMd),
                _buildDetailInfoCard(inv, dateStr, shopName),
                const SizedBox(height: AppTheme.spaceMd),
                if (sale != null && sale.saleItems.isNotEmpty)
                  _buildDetailItemsCard(sale),
                if (sale != null && sale.saleItems.isNotEmpty)
                  const SizedBox(height: AppTheme.spaceMd),
                _buildDetailTotalsCard(inv),
                const SizedBox(height: AppTheme.spaceMd),
                if (sale != null)
                  _buildDetailActions(sale, shopName),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailHeader(Invoice inv, String dateStr, dynamic sale, String? shopName) {
    return Row(
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
          child: const Icon(Icons.receipt, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                inv.invoiceNumber,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppTheme.primary),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text('Invoice Details', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (sale != null)
              _buildDetailIcon(Icons.print, AppTheme.primary,
                  () => ReceiptService.printReceipt(sale, shopName: shopName)),
            if (sale != null)
              const SizedBox(width: 2),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[800]!.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => Navigator.of(context).pop(),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.close, color: Colors.grey, size: 18),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailIcon(IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }

  Widget _buildDetailInfoCard(Invoice inv, String dateStr, String? shopName) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.darkBorder.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Invoice Information',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey[500],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSm),
          _detailRow('Invoice #', inv.invoiceNumber),
          const SizedBox(height: 6),
          _detailRow('Date', dateStr),
          const SizedBox(height: 6),
          _detailRow('Payment', inv.paymentMethod),
          if (inv.user != null) ...[
            const SizedBox(height: 6),
            _detailRow('Cashier', '${inv.user?['name'] ?? ''}'),
          ],
          if (shopName != null) ...[
            const SizedBox(height: 6),
            _detailRow('Shop', shopName),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      ],
    );
  }

  Widget _buildDetailItemsCard(dynamic sale) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.darkBorder.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Items (${sale.saleItems.length})',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey[500],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSm),
          ...sale.saleItems.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.darkSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${item.quantity}x',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[500]),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product?['name'] as String? ?? 'Product',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Qty: ${item.quantity} × ${CurrencyFormatter.formatWithDecimals(item.price)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                Text(
                  CurrencyFormatter.formatWithDecimals(item.price * item.quantity),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.primary),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildDetailTotalsCard(Invoice inv) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.darkBorder.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          _totalRow('Subtotal', CurrencyFormatter.formatWithDecimals(inv.subtotal)),
          if (inv.tax > 0) ...[
            const SizedBox(height: 6),
            _totalRow('Tax', CurrencyFormatter.formatWithDecimals(inv.tax)),
          ],
          if (inv.discount > 0) ...[
            const SizedBox(height: 6),
            _totalRow(
              'Discount',
              '-${CurrencyFormatter.formatWithDecimals(inv.discount)}',
              valueColor: AppTheme.warning,
            ),
          ],
          const SizedBox(height: 8),
          const Divider(color: AppTheme.darkBorder, height: 1),
          const SizedBox(height: 8),
          _totalRow('TOTAL', CurrencyFormatter.formatWithDecimals(inv.total),
              isBold: true, valueColor: AppTheme.success),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? Colors.white : Colors.grey[400],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: FontWeight.bold,
            color: valueColor ?? (isBold ? AppTheme.success : null),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailActions(dynamic sale, String? shopName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: Border.all(color: AppTheme.darkBorder),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              onTap: () => ReceiptService.printReceipt(sale, shopName: shopName),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.print, size: 18, color: Colors.grey[400]),
                    const SizedBox(width: 8),
                    const Text('Print Receipt', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
