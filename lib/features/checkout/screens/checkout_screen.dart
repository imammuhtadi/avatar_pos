import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../cart/providers/cart_provider.dart';
import '../../home/providers/products_provider.dart';
import '../repositories/checkout_repository.dart';
import '../models/transaction.dart';

/// Checkout screen for processing payments
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _paidAmountController = TextEditingController();

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Add listener to rebuild UI when paid amount changes
    _paidAmountController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _paidAmountController.dispose();
    super.dispose();
  }

  Future<void> _processCheckout() async {
    if (!_formKey.currentState!.validate()) return;

    final cartItems = ref.read(cartProvider);
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cart is empty')));
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final repository = CheckoutRepository();
      final total = ref.read(cartTotalProvider);

      // Cash payment only
      final paidAmount = double.tryParse(_paidAmountController.text);
      if (paidAmount == null || paidAmount < total) {
        throw Exception('Invalid payment amount');
      }

      final transaction = await repository.processCheckout(
        cartItems: cartItems,
        paymentMethod: 'cash',
        customerName: _customerNameController.text.isEmpty ? null : _customerNameController.text,
        customerPhone: _customerPhoneController.text.isEmpty ? null : _customerPhoneController.text,
        paidAmount: paidAmount,
      );

      // Clear cart
      ref.read(cartProvider.notifier).clear();

      // Invalidate products provider to refresh stock
      ref.invalidate(productsProvider);
      ref.invalidate(lowStockProductsProvider);

      // Show success and navigate to receipt
      if (mounted) {
        Navigator.of(context).pop(); // Close checkout screen
        _showSuccessDialog(transaction);
      }
    } catch (e, stackTrace) {
      // Log error to console for debugging
      debugPrint('❌ Checkout Error: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checkout failed: $e'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showSuccessDialog(Transaction transaction) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.successColor, size: 32),
            SizedBox(width: 12),
            Text('Payment Successful'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transaction: ${transaction.transactionNumber}'),
            const SizedBox(height: 8),
            Text('Total: \$${transaction.total.toStringAsFixed(2)}'),
            if (transaction.changeAmount > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Change: \$${transaction.changeAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentColor,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to home
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final subtotal = ref.watch(cartTotalProvider);
    final tax = subtotal * 0.10; // 10% tax
    final total = subtotal + tax;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: cartItems.isEmpty
          ? const Center(child: Text('Cart is empty'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.black.withOpacity(0.05),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Order Summary',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 16),
                          ...cartItems.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item.product.name} × ${item.quantity}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  Text(
                                    '\$${item.totalPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Subtotal'),
                              Text('\$${subtotal.toStringAsFixed(2)}'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Tax (10%)'),
                              Text('\$${tax.toStringAsFixed(2)}'),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                '\$${total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.accentColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Cash Payment
                    const Text(
                      'Cash Payment',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _paidAmountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount Paid',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter amount paid';
                        }
                        final amount = double.tryParse(value);
                        if (amount == null || amount < total) {
                          return 'Amount must be at least \$${total.toStringAsFixed(2)}';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Reactive change display
                    Builder(
                      builder: (context) {
                        final paid = double.tryParse(_paidAmountController.text) ?? 0;
                        final change = paid - total;

                        // Determine color and message based on amount
                        Color bgColor;
                        Color textColor;
                        String label;

                        if (_paidAmountController.text.isEmpty || paid == 0) {
                          bgColor = Colors.grey.withOpacity(0.1);
                          textColor = Colors.grey;
                          label = 'Change';
                        } else if (change < 0) {
                          bgColor = AppTheme.errorColor.withOpacity(0.1);
                          textColor = AppTheme.errorColor;
                          label = 'Insufficient (Need \$${(-change).toStringAsFixed(2)} more)';
                        } else if (change == 0) {
                          bgColor = Colors.blue.withOpacity(0.1);
                          textColor = Colors.blue;
                          label = 'Exact Amount';
                        } else {
                          bgColor = AppTheme.successColor.withOpacity(0.1);
                          textColor = AppTheme.successColor;
                          label = 'Change';
                        }

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: textColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              if (change >= 0 && _paidAmountController.text.isNotEmpty)
                                Text(
                                  '\$${change.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Customer Info (Optional)
                    const Text(
                      'Customer Information (Optional)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _customerNameController,
                      decoration: const InputDecoration(
                        labelText: 'Customer Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _customerPhoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 32),

                    // Process Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _processCheckout,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: _isProcessing
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Complete Payment', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
