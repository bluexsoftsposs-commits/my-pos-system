class AppConstants {
  static const String appName = 'BluexSofts POS';
  static const String version = '1.0.0';

  // API
  static const String apiBaseUrl = 'http://localhost:3000/api';

  // Hive boxes
  static const String productsBox = 'products_cache';
  static const String offlineQueueBox = 'offline_queue';
  static const String settingsBox = 'settings';

  // Tax rate (can be configured per shop)
  static const double defaultTaxRate = 0.0; // 0% - set via settings

  // Sync interval
  static const Duration syncInterval = Duration(seconds: 30);
}
