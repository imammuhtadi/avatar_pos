import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:avatar_pos/features/home/index.dart';

/// Repository provider
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

/// Products provider - fetches all products from Supabase
final productsProvider = FutureProvider<List<Product>>((ref) async {
  final repository = ref.read(productRepositoryProvider);
  return await repository.getProducts();
});

/// Search query provider
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Filtered products based on search query
final filteredProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final query = ref.watch(searchQueryProvider);
  final productsAsync = ref.watch(productsProvider);

  if (query.isEmpty) return productsAsync;

  return productsAsync.whenData((products) {
    return products
        .where(
          (p) =>
              p.name.toLowerCase().contains(query.toLowerCase()) ||
              p.description.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  });
});

/// Provider for realtime product updates
final productsStreamProvider = StreamProvider<List<Product>>((ref) {
  final repository = ref.read(productRepositoryProvider);
  return repository.watchProducts();
});

/// Low stock products provider
final lowStockProductsProvider = FutureProvider<List<Product>>((ref) async {
  final repository = ref.read(productRepositoryProvider);
  return await repository.getLowStockProducts();
});
