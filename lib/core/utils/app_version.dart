import 'package:flutter/foundation.dart';

/// App version information
class AppVersion {
  // Version from pubspec.yaml
  static const String version = '1.1.0';
  static const String buildNumber = '2';

  // Git commit hash (will be injected during build)
  static const String commitHash = String.fromEnvironment('COMMIT_HASH', defaultValue: 'dev');

  // Build timestamp
  static const String buildDate = String.fromEnvironment('BUILD_DATE', defaultValue: 'unknown');

  /// Get full version string
  static String get fullVersion => '$version ($buildNumber)';

  /// Get version with commit hash
  static String get versionWithCommit {
    if (commitHash != 'dev' && commitHash.isNotEmpty) {
      return '$fullVersion ($commitHash)';
    }
    return fullVersion;
  }

  /// Get detailed version info
  static String get detailedVersion {
    final buffer = StringBuffer();
    buffer.write('v$fullVersion');

    if (commitHash != 'dev' && commitHash.isNotEmpty) {
      buffer.write('\nCommit: ${commitHash.substring(0, 7)}');
    }

    if (buildDate != 'unknown') {
      buffer.write('\nBuild: $buildDate');
    }

    if (kDebugMode) {
      buffer.write('\nMode: Debug');
    } else {
      buffer.write('\nMode: Release');
    }

    return buffer.toString();
  }

  /// Get simple display version
  static String get displayVersion => 'v$fullVersion';
}
