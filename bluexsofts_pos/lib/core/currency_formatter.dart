import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _pkrFormat = NumberFormat.currency(
    symbol: '₨ ',
    decimalDigits: 0,
    locale: 'en_PK',
  );

  static final NumberFormat _pkrWithDecimals = NumberFormat.currency(
    symbol: '₨ ',
    decimalDigits: 2,
    locale: 'en_PK',
  );

  /// Formats price in PKR, e.g. ₨ 1,000
  static String format(num amount) => _pkrFormat.format(amount);

  /// Formats price with decimals, e.g. ₨ 1,000.50
  static String formatWithDecimals(num amount) =>
      _pkrWithDecimals.format(amount);

  /// Formats to compact form for large numbers, e.g. ₨ 1.2K
  static String formatCompact(num amount) {
    if (amount >= 10000000) {
      return '₨ ${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      return '₨ ${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₨ ${(amount / 1000).toStringAsFixed(1)}K';
    }
    return format(amount);
  }
}
