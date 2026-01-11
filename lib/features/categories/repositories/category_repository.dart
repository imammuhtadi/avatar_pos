import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:avatar_pos/core/index.dart';
import 'package:avatar_pos/features/categories/index.dart';

/// Repository for category operations
class CategoryRepository {
  final SupabaseClient _supabase;

  CategoryRepository(this._supabase);

  /// Get all categories
  Future<List<Category>> getCategories() async {
    try {
      Logger.info('Fetching all categories', tag: 'CategoryRepository');
      final response = await _supabase.from('categories').select().order('name', ascending: true);

      final categories = (response as List)
          .map((json) => Category.fromJson(json as Map<String, dynamic>))
          .toList();
      Logger.info('Fetched ${categories.length} categories', tag: 'CategoryRepository');
      return categories;
    } catch (e) {
      Logger.error('Failed to fetch categories', tag: 'CategoryRepository', error: e);
      throw Exception('Failed to fetch categories: $e');
    }
  }

  /// Get active categories only
  Future<List<Category>> getActiveCategories() async {
    try {
      Logger.info('Fetching active categories', tag: 'CategoryRepository');
      final response = await _supabase
          .from('categories')
          .select()
          .eq('is_active', true)
          .order('name', ascending: true);

      final categories = (response as List)
          .map((json) => Category.fromJson(json as Map<String, dynamic>))
          .toList();
      Logger.info('Fetched ${categories.length} active categories', tag: 'CategoryRepository');
      return categories;
    } catch (e) {
      Logger.error('Failed to fetch active categories', tag: 'CategoryRepository', error: e);
      throw Exception('Failed to fetch active categories: $e');
    }
  }

  /// Get category by ID
  Future<Category> getCategory(String id) async {
    try {
      Logger.info('Fetching category: $id', tag: 'CategoryRepository');
      final response = await _supabase.from('categories').select().eq('id', id).single();

      final category = Category.fromJson(response);
      Logger.info('Fetched category: ${category.name}', tag: 'CategoryRepository');
      return category;
    } catch (e) {
      Logger.error('Failed to fetch category: $id', tag: 'CategoryRepository', error: e);
      throw Exception('Failed to fetch category: $e');
    }
  }

  /// Create new category
  Future<Category> createCategory(Category category) async {
    try {
      Logger.info('Creating category: ${category.name}', tag: 'CategoryRepository');
      final categoryJson = category.toJson();
      categoryJson.remove('id');
      categoryJson.remove('created_at');
      categoryJson.remove('updated_at');

      final response = await _supabase.from('categories').insert(categoryJson).select().single();

      final createdCategory = Category.fromJson(response);
      Logger.info(
        'Created category: ${createdCategory.name} (ID: ${createdCategory.id})',
        tag: 'CategoryRepository',
      );
      return createdCategory;
    } catch (e) {
      Logger.error(
        'Failed to create category: ${category.name}',
        tag: 'CategoryRepository',
        error: e,
      );
      throw Exception('Failed to create category: $e');
    }
  }

  /// Update category
  Future<Category> updateCategory(Category category) async {
    try {
      Logger.info(
        'Updating category: ${category.name} (ID: ${category.id})',
        tag: 'CategoryRepository',
      );
      final categoryJson = category.toJson();
      categoryJson.remove('created_at');
      categoryJson['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('categories')
          .update(categoryJson)
          .eq('id', category.id)
          .select()
          .single();

      final updatedCategory = Category.fromJson(response);
      Logger.info('Updated category: ${updatedCategory.name}', tag: 'CategoryRepository');
      return updatedCategory;
    } catch (e) {
      Logger.error(
        'Failed to update category: ${category.name}',
        tag: 'CategoryRepository',
        error: e,
      );
      throw Exception('Failed to update category: $e');
    }
  }

  /// Delete category
  Future<void> deleteCategory(String id) async {
    try {
      Logger.info('Deleting category: $id', tag: 'CategoryRepository');
      await _supabase.from('categories').delete().eq('id', id);
      Logger.info('Deleted category: $id', tag: 'CategoryRepository');
    } catch (e) {
      Logger.error('Failed to delete category: $id', tag: 'CategoryRepository', error: e);
      throw Exception('Failed to delete category: $e');
    }
  }

  /// Toggle category active status
  Future<Category> toggleActive(String id, bool isActive) async {
    try {
      Logger.info(
        'Toggling category status: $id to ${isActive ? "active" : "inactive"}',
        tag: 'CategoryRepository',
      );
      final response = await _supabase
          .from('categories')
          .update({'is_active': isActive, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', id)
          .select()
          .single();

      final category = Category.fromJson(response);
      Logger.info(
        'Toggled category: ${category.name} to ${isActive ? "active" : "inactive"}',
        tag: 'CategoryRepository',
      );
      return category;
    } catch (e) {
      Logger.error('Failed to toggle category status: $id', tag: 'CategoryRepository', error: e);
      throw Exception('Failed to toggle category status: $e');
    }
  }
}
