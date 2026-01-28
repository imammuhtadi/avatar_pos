import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;
import 'dart:js_interop';

/// Web implementation for reload functionality
/// This file is only used when building for web platform
class WebReload {
  static bool get isWeb => kIsWeb;

  static void hardReload() {
    if (kIsWeb) {
      web.window.location.reload();
    }
  }

  static Future<void> clearCacheAndReload() async {
    if (kIsWeb) {
      try {
        // Unregister service workers
        final serviceWorker = web.window.navigator.serviceWorker;
        final registrations = await serviceWorker.getRegistrations().toDart;
        for (var i = 0; i < registrations.length; i++) {
          await registrations[i].unregister().toDart;
        }

        // Clear cache storage
        final caches = web.window.caches;
        final cacheNames = await caches.keys().toDart;
        for (var i = 0; i < cacheNames.length; i++) {
          await caches.delete(cacheNames[i].toDart).toDart;
        }
      } catch (e) {
        // Ignore errors, just reload anyway
      }

      // Hard reload
      web.window.location.reload();
    }
  }
}
