import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants.dart';
import 'printer_service.dart';

class PrinterSettingsService {
  static const _key = 'printer_config';

  static Future<PrinterConfig> loadConfig() async {
    try {
      final box = Hive.box(AppConstants.settingsBox);
      final data = box.get(_key);
      if (data != null) {
        return PrinterConfig.fromJson(Map<String, dynamic>.from(data));
      }
    } catch (_) {}
    return const PrinterConfig();
  }

  static Future<void> saveConfig(PrinterConfig config) async {
    final box = Hive.box(AppConstants.settingsBox);
    await box.put(_key, config.toJson());
  }

  static Future<List<Map<String, String>>> discoverBluetoothPrinters() async {
    // TODO: Implement with esc_pos_bluetooth package.
    // Requires the device to have Bluetooth enabled.
    // Returns a list of {name, macAddress} for discovered printers.
    debugPrint('[PrinterSettings] Bluetooth discovery not yet implemented');
    return [];
  }
}

void debugPrint(String message) {
  // ignore: avoid_print
  print(message);
}
