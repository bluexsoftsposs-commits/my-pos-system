import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class EnvConfig {
  static String get apiBaseUrl {
    if (kIsWeb) {
      return 'https://my-pos-system-yxm9.onrender.com/api';
    }
    try {
      if (Platform.isAndroid) {
        return 'https://my-pos-system-yxm9.onrender.com/api';
      }
    } catch (_) {}
    return 'https://my-pos-system-yxm9.onrender.com/api';
  }
}
