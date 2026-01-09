import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/product.dart';
import '../repositories/product_repository.dart';

part 'products_provider.g.dart';

/// Products provider - manages product list state with Supabase
@riverpod
class Products extends _$Products {
  ProductRepository get _repository => ProductRepository();

  @override
  Future<List<Product>> build() async {
    return await _repository.getProducts();
  }

  /// Refresh products from database
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getProducts());
  }

  /// Search products
  Future<void> searchProducts(String query) async {
    if (query.isEmpty) {
      await refresh();
      return;
    }
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.searchProducts(query));
  }

  /// Add a new product
  Future<void> addProduct(Product product) async {
    try {
      final newProduct = await _repository.createProduct(product);
      state.whenData((products) {
        state = AsyncValue.data([...products, newProduct]);
      });
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Update an existing product
  Future<void> updateProduct(String id, Product product) async {
    try {
      final updatedProduct = await _repository.updateProduct(id, product);
      state.whenData((products) {
        state = AsyncValue.data([
          for (final p in products)
            if (p.id == id) updatedProduct else p,
        ]);
      });
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Remove a product (soft delete)
  Future<void> removeProduct(String id) async {
    try {
      await _repository.deleteProduct(id);
      state.whenData((products) {
        state = AsyncValue.data(products.where((p) => p.id != id).toList());
      });
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Get low stock products
  Future<List<Product>> getLowStockProducts() async {
    return await _repository.getLowStockProducts();
  }
}

/// Provider for realtime product updates
@riverpod
Stream<List<Product>> productsStream(ProductsStreamRef ref) {
  final repository = ProductRepository();
  return repository.watchProducts();
}
