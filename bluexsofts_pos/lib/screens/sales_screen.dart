import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/sale_provider.dart';
import '../providers/auth_provider.dart';
import '../models/sale.dart';
import '../core/theme.dart';
import '../views/shared/detail_row.dart';
import '../services/receipt_service.dart';
import '../core/currency_formatter.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  DateTimeRange? _dateRange;
  int _currentPage = 1;
  static const int _pageSize = 5;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<SaleProvider>().loadSales();
      context.read<SaleProvider>().loadSummary();
    });
  }

  DateTimeRange get _defaultMonth {
    final now = DateTime.now();
    return DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: now,
    );
  }

  DateTimeRange get _effectiveRange => _dateRange ?? _defaultMonth;

  @override
  Widget build(BuildContext context) {
    final saleProv = context.watch<SaleProvider>();
    final sales = saleProv.sales;
    final totalSales = saleProv.summary?['allTime']?['total'] as num? ?? 0;
    final totalCount = saleProv.summary?['allTime']?['count'] as num? ?? 0;
    final avgOrder = totalCount > 0 ? (totalSales / totalCount).toDouble() : 0.0;
    final itemsSold = sales.fold<int>(0, (sum, s) =>
        sum + s.saleItems.fold<int>(0, (s2, item) => s2 + item.quantity));

    final totalItems = sales.length;
    final fromItem = totalItems > 0 ? ((_currentPage - 1) * _pageSize) + 1 : 0;
    final toItem = (_currentPage * _pageSize) > totalItems ? totalItems : (_currentPage * _pageSize);
    final totalPages = (totalItems / _pageSize).ceil();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1200;

        if (isDesktop) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(saleProv, sales),
              const SizedBox(height: AppTheme.spaceLg),
              _buildStatsRow(totalSales, totalCount, avgOrder, itemsSold),
              const SizedBox(height: AppTheme.spaceLg),
              Expanded(
                child: saleProv.isLoading && sales.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : sales.isEmpty
                        ? _buildEmptyState()
                        : Column(
                            children: [
                              Expanded(
                                child: _buildDesktopTable(sales, saleProv),
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
              _buildHeader(saleProv, sales),
              const SizedBox(height: AppTheme.spaceLg),
              _buildStatsRow(totalSales, totalCount, avgOrder, itemsSold),
              const SizedBox(height: AppTheme.spaceLg),
              if (saleProv.isLoading && sales.isEmpty)
                const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (sales.isEmpty)
                _buildEmptyState()
              else ...[
                _buildMobileList(sales, saleProv),
                if (totalItems > _pageSize)
                  _buildPagination(totalItems, fromItem, toItem, totalPages),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(SaleProvider saleProv, List<Sale> sales) {
    final range = _effectiveRange;
    final dateStr =
        '${DateFormat('MMM dd').format(range.start)} - ${DateFormat('MMM dd, yyyy').format(range.end)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.spaceMd, AppTheme.spaceMd, AppTheme.spaceMd, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sales History',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Track and manage your retail transactions efficiently.',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
          const SizedBox(height: AppTheme.spaceMd),
          Row(
            children: [
              _buildDateRangePill(dateStr),
              const SizedBox(width: AppTheme.spaceSm),
              _buildIconButton(Icons.download_outlined, 'Export', () =>
                  _exportCsv(sales)),
              const Spacer(),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: saleProv.isLoading
                      ? null
                      : () async {
                          setState(() => _isRefreshing = true);
                          debugPrint('[Refresh] Starting loadSales…');
                          await saleProv.loadSales();
                          debugPrint('[Refresh] loadSales done, error=${saleProv.error}');
                          debugPrint('[Refresh] Starting loadSummary…');
                          await saleProv.loadSummary();
                          debugPrint('[Refresh] loadSummary done');
                          if (saleProv.error != null && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(saleProv.error!),
                                backgroundColor: AppTheme.error,
                              ),
                            );
                            saleProv.clearError();
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

  Widget _buildStatsRow(num totalSales, num totalCount, double avgOrder, int itemsSold) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth >= 900 ? 4 : 2;

          return GridView.count(
            crossAxisCount: crossAxisCount,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppTheme.spaceMd,
            crossAxisSpacing: AppTheme.spaceMd,
            childAspectRatio: 2.4,
            children: [
              _buildStatCard('Total Sales', CurrencyFormatter.format(totalSales), '+0.0%', AppTheme.primary, Icons.account_balance_wallet),
              _buildStatCard('Transactions', '$totalCount', '+0.0%', Colors.white, Icons.receipt_long),
              _buildStatCard('Average Order', CurrencyFormatter.format(avgOrder), '', Colors.white, Icons.trending_up),
              _buildStatCard('Items Sold', '$itemsSold', '', AppTheme.success, Icons.inventory_2),
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

  Widget _buildDesktopTable(List<Sale> sales, SaleProvider saleProv) {
    final displaySales = sales
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
                  DataColumn(
                    label: _buildHeaderText('Date & Time'),
                  ),
                  DataColumn(
                    label: _buildHeaderText('Order ID'),
                  ),
                  DataColumn(
                    label: _buildHeaderText('Items'),
                  ),
                  DataColumn(
                    label: _buildHeaderText('Amount'),
                    numeric: true,
                  ),
                  DataColumn(
                    label: _buildHeaderText('Status'),
                  ),
                  DataColumn(
                    label: _buildHeaderText('Actions'),
                    numeric: true,
                  ),
                ],
                rows: displaySales.map((sale) {
                  final dateStr = DateFormat('MMM dd, yyyy').format(sale.createdAt);
                  final timeStr = DateFormat('hh:mm a').format(sale.createdAt);
                  final orderId = sale.invoice?['invoiceNumber'] != null
                      ? '#${sale.invoice!['invoiceNumber']}'
                      : '#${sale.id.substring(0, 8).toUpperCase()}';
                  final itemLabel = sale.saleItems.length == 1
                      ? '1 Item'
                      : '${sale.saleItems.length} Items';

                  return DataRow(
                    onSelectChanged: (_) => _showSaleDetails(sale),
                    cells: [
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
                        Text(orderId, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      ),
                      DataCell(
                        Text(itemLabel, style: const TextStyle(fontSize: 14)),
                      ),
                      DataCell(
                        Text(
                          CurrencyFormatter.formatWithDecimals(sale.total),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primary),
                        ),
                      ),
                      DataCell(_buildStatusBadge(sale.status)),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _buildActionIcon(Icons.print_outlined, () {
                              final auth = context.read<AuthProvider>();
                              ReceiptService.printReceipt(sale, shopName: auth.shop?.shopName);
                            }),
                            const SizedBox(width: 4),
                            _buildActionIcon(Icons.more_vert, () => _showSaleDetails(sale)),
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

  Widget _buildMobileList(List<Sale> sales, SaleProvider saleProv) {
    final displaySales = sales
        .skip((_currentPage - 1) * _pageSize)
        .take(_pageSize)
        .toList();
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
      itemCount: displaySales.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return const SizedBox(height: 0);
        final sale = displaySales[index - 1];
        return _buildSaleCard(sale);
      },
    );
  }

  Widget _buildSaleCard(Sale sale) {
    final dateStr = DateFormat('MMM dd, yyyy').format(sale.createdAt);
    final timeStr = DateFormat('hh:mm a').format(sale.createdAt);
    final orderId = sale.invoice?['invoiceNumber'] != null
        ? '#${sale.invoice!['invoiceNumber']}'
        : '#${sale.id.substring(0, 8).toUpperCase()}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.darkBorder.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        onTap: () => _showSaleDetails(sale),
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
                child: const Icon(Icons.receipt_long, color: Colors.white, size: 22),
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
                            orderId,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.primary),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          CurrencyFormatter.formatWithDecimals(sale.total),
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
                        _buildStatusBadge(sale.status),
                        const SizedBox(width: 8),
                        Text(
                          '${sale.saleItems.length} item${sale.saleItems.length == 1 ? '' : 's'}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                        if (sale.user != null) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.person_outline, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 2),
                          Text(
                            '${sale.user?['name'] ?? ''}',
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

  Widget _buildStatusBadge(String status) {
    final isPaid = status == 'COMPLETED';
    final isRefunded = status == 'REFUNDED';
    final isPending = status == 'PENDING';

    Color bgColor;
    Color textColor;
    Color dotColor;
    String label;

    if (isPaid) {
      bgColor = AppTheme.success.withValues(alpha: 0.15);
      textColor = const Color(0xFF6DFAD2);
      dotColor = const Color(0xFF6DFAD2);
      label = 'Paid';
    } else if (isRefunded) {
      bgColor = AppTheme.error.withValues(alpha: 0.15);
      textColor = const Color(0xFFFFB4AB);
      dotColor = const Color(0xFFFFB4AB);
      label = 'Refunded';
    } else {
      bgColor = AppTheme.warning.withValues(alpha: 0.15);
      textColor = AppTheme.warning;
      dotColor = AppTheme.warning;
      label = isPending ? 'Pending' : status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: dotColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
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
            'No sales yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Sales will appear here once you start making transactions.',
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
            'Showing $fromItem - $toItem of $totalItems orders',
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

  void _exportCsv(List<Sale> sales) {
    final buffer = StringBuffer();
    buffer.writeln('Date,Order ID,Items,Amount,Status,Payment Method');
    for (final sale in sales) {
      final date = DateFormat('yyyy-MM-dd').format(sale.createdAt);
      final orderId = sale.invoice?['invoiceNumber'] != null
          ? sale.invoice!['invoiceNumber']
          : sale.id.substring(0, 8).toUpperCase();
      final items = sale.saleItems.fold<int>(0, (s, i) => s + i.quantity);
      final amount = sale.total.toStringAsFixed(2);
      final status = sale.status;
      final payment = sale.paymentMethod;
      buffer.writeln('$date,$orderId,$items,$amount,$status,$payment');
    }
    final csv = buffer.toString();
    final bytes = utf8.encode(csv);
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'sales_export.csv')
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
      setState(() => _dateRange = picked);
      final saleProv = context.read<SaleProvider>();
      saleProv.loadSummary(
        from: picked.start.toIso8601String(),
        to: picked.end.toIso8601String(),
      );
    }
  }

  void _showSaleDetails(Sale sale) {
    final dateStr = DateFormat('MMM dd, yyyy  hh:mm a').format(sale.createdAt);
    final auth = context.read<AuthProvider>();
    final shopName = auth.shop?.shopName;
    final orderId = sale.invoice?['invoiceNumber'] != null
        ? '#${sale.invoice!['invoiceNumber']}'
        : '#${sale.id.substring(0, 8).toUpperCase()}';

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
                _buildDetailHeader(orderId, dateStr, sale),
                const SizedBox(height: AppTheme.spaceMd),
                _buildDetailItemsCard(sale),
                const SizedBox(height: AppTheme.spaceMd),
                _buildDetailPaymentCard(sale),
                const SizedBox(height: AppTheme.spaceMd),
                _buildDetailActions(sale, shopName),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailHeader(String orderId, String dateStr, Sale sale) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00B894), Color(0xFF55EFC4)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.receipt_long, color: Colors.white, size: 22),
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
                      orderId,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppTheme.primary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(sale.status),
                ],
              ),
              const SizedBox(height: 2),
              Text(dateStr, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailIcon(Icons.print, AppTheme.primary,
                () => ReceiptService.printReceipt(sale, shopName: null)),
            const SizedBox(width: 2),
            _buildDetailIcon(Icons.share, AppTheme.info,
                () => ReceiptService.shareReceipt(sale, shopName: null)),
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

  Widget _buildDetailItemsCard(Sale sale) {
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

  Widget _buildDetailPaymentCard(Sale sale) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.darkBorder.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          DetailRow(
            label: 'Date',
            value: DateFormat('MMM dd, yyyy  hh:mm a').format(sale.createdAt),
          ),
          const SizedBox(height: 6),
          DetailRow(label: 'Payment', value: sale.paymentMethod),
          if (sale.user != null) ...[
            const SizedBox(height: 6),
            DetailRow(label: 'Cashier', value: '${sale.user?['name'] ?? ''}'),
          ],
          if (sale.notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            DetailRow(label: 'Notes', value: sale.notes),
          ],
          const SizedBox(height: 8),
          const Divider(color: AppTheme.darkBorder, height: 1),
          const SizedBox(height: 8),
          if (sale.subtotal > 0)
            DetailRow(label: 'Subtotal', value: CurrencyFormatter.formatWithDecimals(sale.subtotal)),
          if (sale.tax > 0) ...[
            const SizedBox(height: 6),
            DetailRow(label: 'Tax', value: CurrencyFormatter.formatWithDecimals(sale.tax)),
          ],
          if (sale.discount > 0) ...[
            const SizedBox(height: 6),
            DetailRow(
              label: 'Discount',
              value: '-${CurrencyFormatter.formatWithDecimals(sale.discount)}',
              valueColor: AppTheme.warning,
            ),
          ],
          const SizedBox(height: 6),
          DetailRow(
            label: 'Total',
            value: CurrencyFormatter.formatWithDecimals(sale.total),
            isBold: true,
            valueColor: AppTheme.success,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailActions(Sale sale, String? shopName) {
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
        const SizedBox(height: 8),
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
              onTap: () => ReceiptService.shareReceipt(sale, shopName: shopName),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.share, size: 18, color: Colors.grey[400]),
                    const SizedBox(width: 8),
                    const Text('Share Receipt', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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
