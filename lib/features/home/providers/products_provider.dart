import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';

part 'products_provider.g.dart';

/// Products provider - manages product list
@riverpod
class Products extends _$Products {
  @override
  List<Product> build() {
    // Initialize with sample products
    return _getSampleProducts();
  }

  /// Get sample products for demonstration
  List<Product> _getSampleProducts() {
    const uuid = Uuid();
    final now = DateTime.now();

    return [
      Product(
        id: uuid.v4(),
        name: 'Coffee',
        description: 'Premium coffee blend',
        price: 4.99,
        stock: 50,
        category: 'Beverages',
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: uuid.v4(),
        name: 'Sandwich',
        description: 'Fresh sandwich with vegetables',
        price: 7.99,
        stock: 30,
        category: 'Food',
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: uuid.v4(),
        name: 'Juice',
        description: 'Fresh orange juice',
        price: 3.99,
        stock: 40,
        category: 'Beverages',
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: uuid.v4(),
        name: 'Salad',
        description: 'Healthy green salad',
        price: 6.99,
        stock: 25,
        category: 'Food',
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  /// Add a new product
  void addProduct(Product product) {
    state = [...state, product];
  }

  /// Update an existing product
  void updateProduct(Product product) {
    final index = state.indexWhere((p) => p.id == product.id);
    if (index >= 0) {
      state = [
        ...state.sublist(0, index),
        product,
        ...state.sublist(index + 1),
      ];
    }
  }

  /// Delete a product
  void deleteProduct(String productId) {
    state = state.where((p) => p.id != productId).toList();
  }

  /// Search products by name
  List<Product> searchProducts(String query) {
    if (query.isEmpty) return state;

    final lowerQuery = query.toLowerCase();
    return state.where((product) {
      return product.name.toLowerCase().contains(lowerQuery) ||
          product.description.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Filter products by category
  List<Product> filterByCategory(String category) {
    return state.where((product) => product.category == category).toList();
  }
}
