/// Stub implementation for non-web platforms
/// This file is used when building for mobile, desktop, etc.
class WebReload {
  static bool get isWeb => false;

  static void hardReload() {
    // No-op on non-web platforms
  }

  static Future<void> clearCacheAndReload() async {
    // No-op on non-web platforms
  }
}
