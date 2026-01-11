import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:avatar_pos/core/index.dart';

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
      Logger.info('Attempting sign in for: $email', tag: 'AuthRepository');

      final response = await _supabase.auth.signInWithPassword(email: email, password: password);

      if (response.user != null) {
        Logger.success('Sign in successful: ${response.user!.email}', tag: 'AuthRepository');
      }

      return response;
    } catch (e) {
      Logger.error('Sign in error', tag: 'AuthRepository', error: e);
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
      Logger.info('Attempting sign up for: $email', tag: 'AuthRepository');

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: fullName != null ? {'full_name': fullName} : null,
      );

      if (response.user != null) {
        Logger.success('Sign up successful: ${response.user!.email}', tag: 'AuthRepository');
      }

      return response;
    } catch (e) {
      Logger.error('Sign up error', tag: 'AuthRepository', error: e);
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      Logger.info('Signing out user: ${currentUser?.email}', tag: 'AuthRepository');
      await _supabase.auth.signOut();
      Logger.success('Sign out successful', tag: 'AuthRepository');
    } catch (e) {
      Logger.error('Sign out error', tag: 'AuthRepository', error: e);
      rethrow;
    }
  }

  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      Logger.info('Sending password reset email to: $email', tag: 'AuthRepository');
      await _supabase.auth.resetPasswordForEmail(email);
      Logger.success('Password reset email sent', tag: 'AuthRepository');
    } catch (e) {
      Logger.error('Password reset error', tag: 'AuthRepository', error: e);
      rethrow;
    }
  }
}
