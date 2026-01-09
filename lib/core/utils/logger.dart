import 'package:flutter/foundation.dart';

/// Simple logger utility for debugging
class Logger {
  static void log(String message, {String? tag}) {
    if (kDebugMode) {
      final tagPrefix = tag != null ? '[$tag] ' : '';
      print('${tagPrefix}$message');
    }
  }

  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      final tagPrefix = tag != null ? '[$tag] ' : '';
      print('❌ ${tagPrefix}ERROR: $message');
      if (error != null) print('Error: $error');
      if (stackTrace != null) print('StackTrace: $stackTrace');
    }
  }

  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      final tagPrefix = tag != null ? '[$tag] ' : '';
      print('ℹ️ ${tagPrefix}$message');
    }
  }

  static void success(String message, {String? tag}) {
    if (kDebugMode) {
      final tagPrefix = tag != null ? '[$tag] ' : '';
      print('✅ ${tagPrefix}$message');
    }
  }
}
