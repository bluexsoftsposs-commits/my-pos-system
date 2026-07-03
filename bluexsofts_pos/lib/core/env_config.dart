import 'package:flutter/foundation.dart';

class EnvConfig {
  /// Returns the API base URL.
  ///
  /// In debug mode → http://localhost:3000/api  (local backend)
  /// In release mode → https://my-pos-system-2-api.onrender.com/api  (production)
  ///
  /// ⚠ DO NOT remove or hardcode the release URL to localhost before pushing.
  ///    Release builds MUST point to the production Render URL.
  static String get apiBaseUrl {
    if (kDebugMode) {
      return 'http://localhost:3000/api';
    }
    return 'https://my-pos-system-2-api.onrender.com/api';
  }
}
