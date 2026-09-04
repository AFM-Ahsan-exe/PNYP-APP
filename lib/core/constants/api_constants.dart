import 'package:flutter/foundation.dart';

class ApiConstants {
  static const String _defaultEmulatorUrl = 'http://10.0.2.2:3000';

  static String get baseUrl {
    final envUrl = const String.fromEnvironment('BACKEND_URL');
    if (envUrl.isNotEmpty) return envUrl;

    if (kIsWeb) return 'http://localhost:3000';

    return _defaultEmulatorUrl;
  }

  static bool get isUsingEmulatorDefault {
    final envUrl = const String.fromEnvironment('BACKEND_URL');
    return envUrl.isEmpty && !kIsWeb;
  }
}
