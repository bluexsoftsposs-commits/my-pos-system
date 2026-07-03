import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme.dart';

class SalesChart extends StatelessWidget {
  final Map<String, double> dailySales;
  const SalesChart({super.key, required this.dailySales});

  @override
  Widget build(BuildContext context) {
    if (dailySales.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text('No sales data for chart', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final entries = dailySales.entries.toList();
    final maxVal = dailySales.values.reduce((a, b) => a > b ? a : b);
    final minVal = dailySales.values.reduce((a, b) => a < b ? a : b);
    final range = maxVal - minVal;
    final adjustedMax = maxVal + range * 0.2;
    final adjustedMin = ((minVal - range * 0.1).clamp(0, double.infinity)).toDouble();

    final spots = List.generate(entries.length, (i) {
      return FlSpot(i.toDouble(), entries[i].value);
    });

    return ClipRect(
      child: LineChart(
        LineChartData(
          minY: adjustedMin,
          maxY: adjustedMax,
          clipData: const FlClipData.all(),
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppTheme.darkSurface,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final idx = spot.spotIndex;
                  return LineTooltipItem(
                    '${entries[idx].key}\nRs ${spot.y.toStringAsFixed(2)}',
                    const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                  );
                }).toList();
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: entries.length > 8 ? (entries.length / 4).ceilToDouble() : 1,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < entries.length) {
                    final key = entries[idx].key;
                    final label = key.length == 10 ? key.substring(5) : key;
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        label,
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    'Rs ${value.toInt()}',
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: range > 0 ? range / 4 : adjustedMax / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.white.withValues(alpha: 0.05),
              strokeWidth: 1,
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: const Color(0xFF6C5CE7),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: spots.length <= 14,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 3,
                    color: const Color(0xFF6C5CE7),
                    strokeWidth: 0,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF6C5CE7).withValues(alpha: 0.30),
                    const Color(0xFF6C5CE7).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 300),
      ),
    );
  }
}
