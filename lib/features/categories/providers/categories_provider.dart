import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../models/category.dart';
import '../repositories/category_repository.dart';

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
