import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class EnvConfig {
  static bool get _isLocalDev => const bool.fromEnvironment('LOCAL_DEV', defaultValue: true);

  static String get apiBaseUrl {
    if (_isLocalDev) {
      if (kIsWeb) return 'http://localhost:3000/api';
      try {
        if (Platform.isAndroid) return 'http://10.0.2.2:3000/api';
      } catch (_) {}
      return 'http://localhost:3000/api';
    }
    return 'https://my-pos-system-yxm9.onrender.com/api';
  }
}
