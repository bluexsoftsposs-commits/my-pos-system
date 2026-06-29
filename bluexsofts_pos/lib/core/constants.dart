import 'env_config.dart';

class AppConstants {
  static const String appName = 'BluexSofts POS';
  static const String version = '1.0.0';

  // API
  static String get apiBaseUrl => EnvConfig.apiBaseUrl;

  // Hive boxes
  static const String productsBox = 'products_cache';
  static const String offlineQueueBox = 'offline_queue';
  static const String settingsBox = 'settings';

  // Tax rate (can be configured per shop)
  static const double defaultTaxRate = 0.0; // 0% - set via settings

  // Sync interval
  static const Duration syncInterval = Duration(seconds: 30);
}
