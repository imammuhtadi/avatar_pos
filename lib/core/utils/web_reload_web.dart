import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web implementation for reload functionality
/// This file is only used when building for web platform
class WebReload {
  static bool get isWeb => kIsWeb;

  static void hardReload() {
    if (kIsWeb) {
      html.window.location.reload();
    }
  }

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
