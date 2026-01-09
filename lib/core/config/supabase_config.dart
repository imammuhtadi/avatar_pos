import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase configuration and initialization
class SupabaseConfig {
  // Private constructor
  SupabaseConfig._();

  /// Get Supabase URL from environment
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';

  /// Get Supabase Anon Key from environment
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  /// Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
    );
  }
}

/// Global Supabase client accessor
final supabase = Supabase.instance.client;
