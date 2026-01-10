import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../models/transaction.dart';
import '../models/transaction_item.dart';
import '../../home/models/cart_item.dart';

/// Repository for checkout and transaction operations
class CheckoutRepository {
  final SupabaseClient _supabase = supabase;

  /// Process checkout - creates transaction and updates stock
  Future<Transaction> processCheckout({
    required List<CartItem> cartItems,
    required String paymentMethod,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    double? paidAmount,
    String? notes,
  }) async {
    try {
      // Get current user ID (cashier)
      // If no user is authenticated, use null (for testing without auth)
      final userId = _supabase.auth.currentUser?.id;
      debugPrint('🔐 User ID: ${userId ?? "NULL (no auth)"}');

      // Prepare items for the function
      final items = cartItems
          .map((item) => {'product_id': item.product.id, 'quantity': item.quantity})
          .toList();
      debugPrint('🛒 Cart items: ${items.length} items');
      debugPrint('📦 Items data: $items');

      // Call the Supabase function
      debugPrint('📞 Calling process_checkout function...');
      final response = await _supabase.rpc(
        'process_checkout',
        params: {
          'p_cashier_id': userId,
          'p_items': items,
          'p_payment_method': paymentMethod,
          'p_customer_name': customerName,
          'p_customer_phone': customerPhone,
          'p_customer_email': customerEmail,
          'p_paid_amount': paidAmount,
          'p_notes': notes,
        },
      );
      debugPrint('✅ Supabase response received');

      // Parse response
      final transactionData = response['transaction'] as Map<String, dynamic>;
      final itemsData = response['items'] as List<dynamic>;

      // Parse transaction
      final transaction = Transaction.fromJson(transactionData);

      // Parse items
      final transactionItems = itemsData
          .map((item) => TransactionItem.fromJson(item as Map<String, dynamic>))
          .toList();

      // Return transaction with items
      debugPrint('🎉 Transaction completed: ${transaction.transactionNumber}');
      return transaction.copyWith(items: transactionItems);
    } catch (e, stackTrace) {
      debugPrint('❌ Checkout Repository Error: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Failed to process checkout: $e');
    }
  }

  /// Get transaction by ID with items
  Future<Transaction> getTransaction(String transactionId) async {
    try {
      final response = await _supabase.rpc(
        'get_transaction_with_items',
        params: {'p_transaction_id': transactionId},
      );

      final transactionData = response['transaction'] as Map<String, dynamic>;
      final itemsData = response['items'] as List<dynamic>;

      final transaction = Transaction.fromJson(transactionData);
      final transactionItems = itemsData
          .map((item) => TransactionItem.fromJson(item as Map<String, dynamic>))
          .toList();

      return transaction.copyWith(items: transactionItems);
    } catch (e) {
      throw Exception('Failed to fetch transaction: $e');
    }
  }

  /// Get today's transactions
  Future<List<Transaction>> getTodayTransactions() async {
    try {
      final response = await _supabase.rpc('get_today_transactions');

      return (response as List)
          .map((json) => Transaction.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch today transactions: $e');
    }
  }

  /// Get all transactions with pagination
  Future<List<Transaction>> getTransactions({int limit = 50, int offset = 0}) async {
    try {
      final response = await _supabase.rpc(
        'get_all_transactions',
        params: {'p_limit': limit, 'p_offset': offset},
      );

      return (response as List)
          .map((json) => Transaction.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch transactions: $e');
    }
  }

  /// Get sales summary
  Future<Map<String, dynamic>> getSalesSummary({DateTime? startDate, DateTime? endDate}) async {
    try {
      final response = await _supabase.rpc(
        'get_sales_summary',
        params: {
          'p_start_date': startDate?.toIso8601String(),
          'p_end_date': endDate?.toIso8601String(),
        },
      );

      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch sales summary: $e');
    }
  }

  /// Search transactions by transaction number or customer
  Future<List<Transaction>> searchTransactions(String query) async {
    try {
      final response = await _supabase
          .from('transactions')
          .select()
          .or(
            'transaction_number.ilike.%$query%,customer_name.ilike.%$query%,customer_phone.ilike.%$query%',
          )
          .order('created_at', ascending: false)
          .limit(50);

      return (response as List)
          .map((json) => Transaction.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to search transactions: $e');
    }
  }
}
