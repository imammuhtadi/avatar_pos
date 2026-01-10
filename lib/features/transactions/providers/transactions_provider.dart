import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../checkout/models/transaction.dart';
import '../../checkout/repositories/checkout_repository.dart';

/// Provider for checkout repository
final checkoutRepositoryProvider = Provider<CheckoutRepository>((ref) {
  return CheckoutRepository();
});

/// Provider for all transactions
final transactionsProvider = FutureProvider.autoDispose<List<Transaction>>((ref) async {
  final repository = ref.watch(checkoutRepositoryProvider);
  return repository.getTransactions(limit: 100);
});

/// Provider for today's transactions
final todayTransactionsProvider = FutureProvider.autoDispose<List<Transaction>>((ref) async {
  final repository = ref.watch(checkoutRepositoryProvider);
  return repository.getTodayTransactions();
});

/// Provider for a specific transaction by ID
final transactionDetailProvider = FutureProvider.autoDispose.family<Transaction, String>((
  ref,
  transactionId,
) async {
  final repository = ref.watch(checkoutRepositoryProvider);
  return repository.getTransaction(transactionId);
});

/// Provider for sales summary
final salesSummaryProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(checkoutRepositoryProvider);
  return repository.getSalesSummary();
});
