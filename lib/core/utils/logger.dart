import 'package:flutter/foundation.dart';

/// Simple logger utility for debugging
class Logger {
  static void log(String message, {String? tag}) {
    if (kDebugMode) {
      final tagPrefix = tag != null ? '[$tag] ' : '';
      debugPrint('${tagPrefix}$message');
    }
  }

  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      final tagPrefix = tag != null ? '[$tag] ' : '';
      debugPrint('❌ ${tagPrefix}ERROR: $message');
      if (error != null) debugPrint('Error: $error');
      if (stackTrace != null) debugPrint('StackTrace: $stackTrace');
    }
  }

  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      final tagPrefix = tag != null ? '[$tag] ' : '';
      debugPrint('ℹ️ ${tagPrefix}$message');
    }
  }

  static void success(String message, {String? tag}) {
    if (kDebugMode) {
      final tagPrefix = tag != null ? '[$tag] ' : '';
      debugPrint('✅ ${tagPrefix}$message');
    }
  }
}
