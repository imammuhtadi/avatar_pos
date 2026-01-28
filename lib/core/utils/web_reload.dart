/// Utility for web-specific reload functionality
/// Uses conditional exports to support all platforms
/// - On web: uses web_reload_web.dart with actual implementation
/// - On other platforms: uses web_reload_stub.dart with no-op implementation
library;

export 'web_reload_stub.dart' if (dart.library.html) 'web_reload_web.dart';
