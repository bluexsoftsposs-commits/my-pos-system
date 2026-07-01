import 'package:flutter/foundation.dart';

class EnvConfig {
  static String get apiBaseUrl => kIsWeb
      ? 'https://my-pos-system-2-api.onrender.com/api'
      : 'https://my-pos-system-2-api.onrender.com/api';
}
