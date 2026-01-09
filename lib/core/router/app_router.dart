import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/products/screens/products_screen.dart';
import '../../features/cart/screens/cart_screen.dart';
import '../../features/settings/screens/settings_screen.dart';

/// Application router configuration using go_router
class AppRouter {
  static const String home = '/';
  static const String products = '/products';
  static const String cart = '/cart';
  static const String settings = '/settings';

  static final GoRouter router = GoRouter(
    initialLocation: home,
    routes: [
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
        path: cart,
        name: 'cart',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const CartScreen()),
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
