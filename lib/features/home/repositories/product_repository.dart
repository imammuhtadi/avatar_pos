import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../models/product.dart';

/// Repository for product data operations with Supabase
class ProductRepository {
  final SupabaseClient _supabase = supabase;

  /// Fetch all active products
  Future<List<Product>> getProducts() async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('is_active', true)
          .order('name');

      return (response as List)
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  /// Fetch single product by ID
  Future<Product?> getProduct(String id) async {
    try {
      final response = await _supabase.from('products').select().eq('id', id).single();

      return Product.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Create new product
  Future<Product> createProduct(Product product) async {
    try {
      final response = await _supabase.from('products').insert(product.toJson()).select().single();

      return Product.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  /// Update existing product
  Future<Product> updateProduct(String id, Product product) async {
    try {
      final response = await _supabase
          .from('products')
          .update(product.toJson())
          .eq('id', id)
          .select()
          .single();

      return Product.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  /// Soft delete product (set is_active to false)
  Future<void> deleteProduct(String id) async {
    try {
      await _supabase.from('products').update({'is_active': false}).eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  /// Search products by name, SKU, or barcode
  Future<List<Product>> searchProducts(String query) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .or('name.ilike.%$query%,sku.ilike.%$query%,barcode.ilike.%$query%')
          .eq('is_active', true)
          .order('name');

      return (response as List)
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  /// Get products with low stock
  Future<List<Product>> getLowStockProducts() async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .filter('stock', 'lte', 'min_stock')
          .eq('is_active', true)
          .order('stock');

      return (response as List)
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch low stock products: $e');
    }
  }

  /// Get products by category
  Future<List<Product>> getProductsByCategory(String categoryId) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('category_id', categoryId)
          .eq('is_active', true)
          .order('name');

      return (response as List)
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch products by category: $e');
    }
  }

  /// Update product stock
  Future<void> updateStock(String id, int newStock) async {
    try {
      await _supabase
          .from('products')
          .update({'stock': newStock, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to update stock: $e');
    }
  }

  /// Listen to product changes in realtime
  Stream<List<Product>> watchProducts() {
    return _supabase
        .from('products')
        .stream(primaryKey: ['id'])
        .eq('is_active', true)
        .order('name')
        .map((data) => data.map((json) => Product.fromJson(json)).toList());
  }
}
