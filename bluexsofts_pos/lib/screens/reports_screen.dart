import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/report_provider.dart';
import '../core/theme.dart';
import '../core/currency_formatter.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().loadReport();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ReportProvider>();
    final report = prov.report;
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => prov.loadReport(),
          ),
        ],
      ),
      body: prov.isLoading
          ? const Center(child: CircularProgressIndicator())
          : report == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bar_chart, size: 64, color: Colors.grey[600]),
                      const SizedBox(height: 12),
                      Text('No data available', style: TextStyle(color: Colors.grey[400])),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPeriodSelector(prov),
                      const SizedBox(height: 20),
                      _buildSummaryCards(report),
                      const SizedBox(height: 24),
                      _buildChart(report),
                      const SizedBox(height: 24),
                      if (isDesktop)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildTopProducts(report.topByQuantity, 'Top by Quantity', Icons.shopping_cart)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildTopProducts(report.topByRevenue, 'Top by Revenue', Icons.attach_money)),
                          ],
                        )
                      else ...[
                        _buildTopProducts(report.topByQuantity, 'Top by Quantity', Icons.shopping_cart),
                        const SizedBox(height: 16),
                        _buildTopProducts(report.topByRevenue, 'Top by Revenue', Icons.attach_money),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildPeriodSelector(ReportProvider prov) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.darkBorder.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          _periodBtn(prov, 'daily', 'Daily'),
          const SizedBox(width: 4),
          _periodBtn(prov, 'weekly', 'Weekly'),
          const SizedBox(width: 4),
          _periodBtn(prov, 'monthly', 'Monthly'),
        ],
      ),
    );
  }

  Widget _periodBtn(ReportProvider prov, String value, String label) {
    final active = prov.selectedPeriod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => prov.setPeriod(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: active ? Colors.white : Colors.grey[400],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(SalesReportData report) {
    return Row(
      children: [
        Expanded(
          child: _summaryCard('Total Sales', CurrencyFormatter.format(report.totalSales), AppTheme.primary, Icons.trending_up),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard('Transactions', '${report.transactionCount}', AppTheme.info, Icons.receipt_long),
        ),
      ],
    );
  }

  Widget _summaryCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.darkBorder.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(SalesReportData report) {
    final data = report.breakdown;
    if (data.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.darkBorder.withOpacity(0.3)),
        ),
        child: Center(child: Text('No chart data', style: TextStyle(color: Colors.grey[500]))),
      );
    }

    final maxVal = data.fold<double>(0, (max, d) => (d['total'] as num).toDouble() > max ? (d['total'] as num).toDouble() : max);
    final chartHeight = MediaQuery.of(context).size.width > 600 ? 280.0 : 200.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.darkBorder.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 16),
            child: Text('Sales Trend (${_periodLabel(report.period)})',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ),
          SizedBox(
            height: chartHeight,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal * 1.15,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppTheme.darkSurface,
                    getTooltipItem: (group, _, rod, __) {
                      final label = data[group.x.toInt()]['label'] as String;
                      return BarTooltipItem(
                        '$label\n${CurrencyFormatter.format(rod.toY)}',
                        const TextStyle(color: Colors.white, fontSize: 12),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                        final raw = data[idx]['label'] as String;
                        final short = raw.length > 5 ? raw.substring(raw.length - 5) : raw;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(short, style: TextStyle(fontSize: 9, color: Colors.grey[500])),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          CurrencyFormatter.format(value).length > 6
                              ? '${(value / 1000).toStringAsFixed(0)}k'
                              : CurrencyFormatter.format(value),
                          style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxVal / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppTheme.darkBorder.withOpacity(0.3),
                    strokeWidth: 1,
                  ),
                ),
                barGroups: data.asMap().entries.map((entry) {
                  final i = entry.key;
                  final total = (entry.value['total'] as num).toDouble();
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: total,
                        color: AppTheme.primary,
                        width: data.length > 15 ? 6 : 16,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts(List<Map<String, dynamic>> items, String title, IconData icon) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.darkBorder.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(icon, size: 18, color: Colors.grey[500]), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.w600))]),
            const SizedBox(height: 12),
            Text('No data', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.darkBorder.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, size: 18, color: Colors.grey[500]), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.w600))]),
          const SizedBox(height: 12),
          ...items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final isQty = item.containsKey('quantity');
            final value = isQty ? '${item['quantity']}' : CurrencyFormatter.format((item['revenue'] as num).toDouble());
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.darkBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(child: Text('${i + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['name'] as String? ?? 'Unknown', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        if ((item['sku'] as String?)?.isNotEmpty == true)
                          Text('SKU: ${item['sku']}', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                      ],
                    ),
                  ),
                  Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _periodLabel(String period) {
    switch (period) {
      case 'weekly': return 'Weekly';
      case 'monthly': return 'Monthly';
      default: return 'Daily';
    }
  }
}
