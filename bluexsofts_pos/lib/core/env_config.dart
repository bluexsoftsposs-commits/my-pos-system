import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class EnvConfig {
  static String get apiBaseUrl {
    if (kIsWeb) return 'https://my-pos-system-yxm9.onrender.com/api';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:3000/api';
    } catch (_) {}
    return 'http://localhost:3000/api';
  }
}
