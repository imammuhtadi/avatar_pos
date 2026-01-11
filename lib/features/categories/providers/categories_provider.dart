import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:avatar_pos/core/index.dart';
import 'package:avatar_pos/features/categories/index.dart';

/// Category repository provider
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(supabase);
});

/// All categories provider
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repository = ref.read(categoryRepositoryProvider);
  return repository.getCategories();
});

/// Active categories provider
final activeCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repository = ref.read(categoryRepositoryProvider);
  return repository.getActiveCategories();
});

/// Selected category provider (for filtering)
final selectedCategoryProvider = StateProvider<String?>((ref) => null);
