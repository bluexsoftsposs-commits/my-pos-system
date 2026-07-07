import 'package:flutter/foundation.dart';
import '../services/report_service.dart';

class SalesReportData {
  final double totalSales;
  final int transactionCount;
  final List<Map<String, dynamic>> breakdown;
  final List<Map<String, dynamic>> topByQuantity;
  final List<Map<String, dynamic>> topByRevenue;
  final String period;

  SalesReportData({
    required this.totalSales,
    required this.transactionCount,
    required this.breakdown,
    required this.topByQuantity,
    required this.topByRevenue,
    required this.period,
  });

  factory SalesReportData.fromJson(Map<String, dynamic> json) {
    return SalesReportData(
      totalSales: (json['totalSales'] as num).toDouble(),
      transactionCount: (json['transactionCount'] as num).toInt(),
      breakdown: (json['breakdown'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      topByQuantity: (json['topByQuantity'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      topByRevenue: (json['topByRevenue'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      period: json['period'] as String? ?? 'daily',
    );
  }
}

class ReportProvider with ChangeNotifier {
  SalesReportData? _report;
  bool _isLoading = false;
  String? _error;
  String _selectedPeriod = 'daily';

  final _reportService = ReportService();

  SalesReportData? get report => _report;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedPeriod => _selectedPeriod;

  void setPeriod(String period) {
    _selectedPeriod = period;
    loadReport();
  }

  Future<void> loadReport({String? startDate, String? endDate}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _reportService.getSalesReport(
        period: _selectedPeriod,
        startDate: startDate,
        endDate: endDate,
      );
      if (data != null) {
        _report = SalesReportData.fromJson(data);
      } else {
        _error = 'Failed to load report';
      }
    } catch (e) {
      _error = 'Failed to load report';
    }

    _isLoading = false;
    notifyListeners();
  }
}
