import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Utility for web-specific reload functionality
class WebReload {
  /// Check if running on web platform
  static bool get isWeb => kIsWeb;

  /// Hard reload the web page (clears cache and reloads)
  static void hardReload() {
    if (kIsWeb) {
      // Force reload from server, bypassing cache
      html.window.location.reload();
    }
  }

  /// Clear service worker cache and reload
  static Future<void> clearCacheAndReload() async {
    if (kIsWeb) {
      try {
        // Unregister service workers
        final registrations = await html.window.navigator.serviceWorker?.getRegistrations();
        if (registrations != null) {
          for (final registration in registrations) {
            await registration.unregister();
          }
        }

        // Clear cache storage
        final cacheNames = await html.window.caches?.keys();
        if (cacheNames != null) {
          for (final cacheName in cacheNames) {
            await html.window.caches?.delete(cacheName);
          }
        }
      } catch (e) {
        // Ignore errors, just reload anyway
      }

      // Hard reload
      html.window.location.reload();
    }
  }
}
