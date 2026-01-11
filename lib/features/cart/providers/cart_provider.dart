import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../home/models/cart_item.dart';
import '../../home/models/product.dart';

/// Cart state notifier - manages shopping cart
class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  /// Add product to cart
  void addProduct(Product product) {
    final existingIndex = state.indexWhere((item) => item.product.id == product.id);

    if (existingIndex >= 0) {
      // Product already in cart, increase quantity
      final updatedItem = state[existingIndex].copyWith(
        quantity: state[existingIndex].quantity + 1,
      );
      state = [
        ...state.sublist(0, existingIndex),
        updatedItem,
        ...state.sublist(existingIndex + 1),
      ];
    } else {
      // Add new product to cart
      state = [...state, CartItem(product: product, quantity: 1)];
    }
  }

  /// Remove product from cart
  void removeProduct(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  /// Update quantity of a product in cart
  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeProduct(productId);
      return;
    }

    final index = state.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      final updatedItem = state[index].copyWith(quantity: quantity);
      state = [...state.sublist(0, index), updatedItem, ...state.sublist(index + 1)];
    }
  }

  /// Clear all items from cart
  void clear() {
    state = [];
  }

  /// Get total price of all items in cart
  double get totalPrice {
    return state.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  /// Get total number of items in cart
  int get itemCount {
    return state.fold(0, (sum, item) => sum + item.quantity);
  }
}

/// Cart provider
final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

/// Cart total price provider
final cartTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0.0, (sum, item) => sum + item.totalPrice);
});

/// Cart item count provider
final cartItemCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (sum, item) => sum + item.quantity);
});
