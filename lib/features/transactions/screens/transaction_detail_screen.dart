import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/transactions_provider.dart';

/// Transaction detail screen
class TransactionDetailScreen extends ConsumerWidget {
  final String transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionAsync = ref.watch(transactionDetailProvider(transactionId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share/export receipt
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Share feature - Coming soon')));
            },
          ),
        ],
      ),
      body: transactionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
              const SizedBox(height: 16),
              const Text('Error loading transaction'),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        data: (transaction) {
          final dateFormat = DateFormat('EEEE, MMM dd, yyyy • HH:mm:ss');
          final date = transaction.createdAt != null
              ? dateFormat.format(transaction.createdAt!)
              : 'Unknown date';

          return SingleChildScrollView(
            child: Column(
              children: [
                // Header card with transaction number
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.accentColor, AppTheme.accentColor.withOpacity(0.8)],
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.receipt_long, color: Colors.white, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        transaction.transactionNumber,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          transaction.paymentStatus.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Transaction info card
                      _buildInfoCard(
                        isDark: isDark,
                        title: 'Transaction Information',
                        children: [
                          _buildInfoRow('Date', date),
                          _buildInfoRow('Payment Method', transaction.paymentMethod.toUpperCase()),
                          if (transaction.customerName != null)
                            _buildInfoRow('Customer', transaction.customerName!),
                          if (transaction.customerPhone != null)
                            _buildInfoRow('Phone', transaction.customerPhone!),
                          if (transaction.notes != null && transaction.notes!.isNotEmpty)
                            _buildInfoRow('Notes', transaction.notes!),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Items card
                      _buildInfoCard(
                        isDark: isDark,
                        title: 'Items (${transaction.items?.length ?? 0})',
                        children: [
                          if (transaction.items != null && transaction.items!.isNotEmpty)
                            ...transaction.items!.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.productName,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '\$${item.unitPrice.toStringAsFixed(2)} × ${item.quantity}',
                                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '\$${item.subtotal.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            const Text('No items'),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Payment summary card
                      _buildInfoCard(
                        isDark: isDark,
                        title: 'Payment Summary',
                        children: [
                          _buildSummaryRow('Subtotal', transaction.subtotal),
                          _buildSummaryRow('Tax', transaction.tax),
                          if (transaction.discount > 0)
                            _buildSummaryRow('Discount', -transaction.discount, isDiscount: true),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                '\$${transaction.total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.accentColor,
                                ),
                              ),
                            ],
                          ),
                          if (transaction.paidAmount != null) ...[
                            const SizedBox(height: 12),
                            _buildSummaryRow('Paid', transaction.paidAmount!),
                            if (transaction.changeAmount > 0)
                              _buildSummaryRow('Change', transaction.changeAmount, isChange: true),
                          ],
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({
    required bool isDark,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount, {
    bool isDiscount = false,
    bool isChange = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDiscount
                  ? AppTheme.errorColor
                  : isChange
                  ? AppTheme.successColor
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
