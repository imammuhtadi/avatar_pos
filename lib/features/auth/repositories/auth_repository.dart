import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';

/// Repository for authentication operations
class AuthRepository {
  final SupabaseClient _supabase = supabase;

  /// Get current user
  User? get currentUser => _supabase.auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Sign in with email and password
  Future<AuthResponse> signIn({required String email, required String password}) async {
    try {
      debugPrint('🔐 Attempting sign in for: $email');

      final response = await _supabase.auth.signInWithPassword(email: email, password: password);

      if (response.user != null) {
        debugPrint('✅ Sign in successful: ${response.user!.email}');
      }

      return response;
    } catch (e) {
      debugPrint('❌ Sign in error: $e');
      rethrow;
    }
  }

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      debugPrint('📝 Attempting sign up for: $email');

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: fullName != null ? {'full_name': fullName} : null,
      );

      if (response.user != null) {
        debugPrint('✅ Sign up successful: ${response.user!.email}');
      }

      return response;
    } catch (e) {
      debugPrint('❌ Sign up error: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      debugPrint('🚪 Signing out user: ${currentUser?.email}');
      await _supabase.auth.signOut();
      debugPrint('✅ Sign out successful');
    } catch (e) {
      debugPrint('❌ Sign out error: $e');
      rethrow;
    }
  }

  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      debugPrint('📧 Sending password reset email to: $email');
      await _supabase.auth.resetPasswordForEmail(email);
      debugPrint('✅ Password reset email sent');
    } catch (e) {
      debugPrint('❌ Password reset error: $e');
      rethrow;
    }
  }
}
