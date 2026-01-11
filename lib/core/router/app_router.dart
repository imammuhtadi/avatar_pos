import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:avatar_pos/core/index.dart';
import 'package:avatar_pos/features/auth/index.dart';
import 'package:avatar_pos/features/cart/index.dart';
import 'package:avatar_pos/features/categories/index.dart';
import 'package:avatar_pos/features/home/index.dart';
import 'package:avatar_pos/features/products/index.dart';
import 'package:avatar_pos/features/settings/index.dart';
import 'package:avatar_pos/features/transactions/index.dart';

/// Notifier to refresh GoRouter when auth state changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream() {
    // Listen to Supabase auth state changes
    supabase.auth.onAuthStateChange.listen((data) {
      notifyListeners(); // Tell GoRouter to re-evaluate routes
    });
  }
}

/// Application router configuration using go_router
class AppRouter {
  static const String login = '/login';
  static const String home = '/';
  static const String products = '/products';
  static const String categories = '/categories';
  static const String cart = '/cart';
  static const String transactions = '/transactions';
  static const String settings = '/settings';

  static final _refreshStream = GoRouterRefreshStream();

  static final GoRouter router = GoRouter(
    initialLocation: home,
    refreshListenable: _refreshStream, // Listen to auth changes
    redirect: (context, state) {
      final isLoggedIn = supabase.auth.currentUser != null;
      final isLoginRoute = state.matchedLocation == login;

      // If not logged in and not on login page, redirect to login
      if (!isLoggedIn && !isLoginRoute) {
        return login;
      }

      // If logged in and on login page, redirect to home
      if (isLoggedIn && isLoginRoute) {
        return home;
      }

      // No redirect needed
      return null;
    },
    routes: [
      GoRoute(
        path: login,
        name: 'login',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const LoginScreen()),
      ),
      GoRoute(
        path: home,
        name: 'home',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const HomeScreen()),
      ),
      GoRoute(
        path: products,
        name: 'products',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const ProductsScreen()),
      ),
      GoRoute(
        path: categories,
        name: 'categories',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const CategoriesScreen()),
      ),
      GoRoute(
        path: cart,
        name: 'cart',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const CartScreen()),
      ),
      GoRoute(
        path: transactions,
        name: 'transactions',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const TransactionsScreen()),
      ),
      GoRoute(
        path: settings,
        name: 'settings',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const SettingsScreen()),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.uri}'))),
  );
}
