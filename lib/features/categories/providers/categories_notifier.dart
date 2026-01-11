import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:avatar_pos/features/categories/index.dart';

/// State for categories list
class CategoriesState {
  final List<Category> categories;
  final bool isLoading;
  final String? error;
  final String? togglingId; // ID of category being toggled

  CategoriesState({required this.categories, this.isLoading = false, this.error, this.togglingId});

  CategoriesState copyWith({
    List<Category>? categories,
    bool? isLoading,
    String? error,
    String? togglingId,
  }) {
    return CategoriesState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      togglingId: togglingId,
    );
  }
}

/// Notifier for managing categories state
class CategoriesNotifier extends StateNotifier<CategoriesState> {
  final CategoryRepository _repository;

  CategoriesNotifier(this._repository) : super(CategoriesState(categories: [], isLoading: true)) {
    loadCategories();
  }

  Future<void> loadCategories() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final categories = await _repository.getCategories();
      state = CategoriesState(categories: categories, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> toggleActive(String id, bool isActive) async {
    // Set toggling state to show loading indicator
    state = state.copyWith(togglingId: id);

    try {
      // Update backend and wait for confirmation
      await _repository.toggleActive(id, isActive);

      // Update local state with confirmed data
      final updatedCategories = state.categories.map((cat) {
        if (cat.id == id) {
          return cat.copyWith(isActive: isActive);
        }
        return cat;
      }).toList();

      state = state.copyWith(categories: updatedCategories, togglingId: null);
    } catch (e) {
      // Clear toggling state on error
      state = state.copyWith(togglingId: null);
      rethrow;
    }
  }

  Future<void> createCategory(Category category) async {
    await _repository.createCategory(category);
    await loadCategories();
  }

  Future<void> updateCategory(Category category) async {
    await _repository.updateCategory(category);
    await loadCategories();
  }

  Future<void> deleteCategory(String id) async {
    await _repository.deleteCategory(id);
    await loadCategories();
  }
}

/// Provider for categories notifier
final categoriesNotifierProvider = StateNotifierProvider<CategoriesNotifier, CategoriesState>((
  ref,
) {
  final repository = ref.read(categoryRepositoryProvider);
  return CategoriesNotifier(repository);
});
