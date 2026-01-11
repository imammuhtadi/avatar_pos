import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cart_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../checkout/screens/checkout_screen.dart';

/// Reusable cart panel widget that can be used in sidebar or full screen
class CartPanel extends ConsumerWidget {
  final bool showHeader;
  final VoidCallback? onCheckout;

  const CartPanel({super.key, this.showHeader = true, this.onCheckout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final cart = ref.read(cartProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Header
        if (showHeader)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Cart',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.5),
                ),
                if (cartItems.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      cart.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white, size: 20),
                              SizedBox(width: 12),
                              Text('Cart cleared'),
                            ],
                          ),
                          backgroundColor: AppTheme.successColor,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Clear'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
              ],
            ),
          ),

        // Cart content
        Expanded(
          child: cartItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 64,
                        color: AppTheme.neutralDark.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Cart is empty',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.neutralDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add products to get started',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.neutralDark.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: cartItems.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.black.withOpacity(0.05),
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product name
                          Text(
                            item.product.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),

                          // Price and controls
                          Row(
                            children: [
                              // Price info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '\$${item.product.price.toStringAsFixed(2)} × ${item.quantity}',
                                      style: TextStyle(fontSize: 12, color: AppTheme.neutralDark),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '\$${item.totalPrice.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.accentColor,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Quantity controls
                              Container(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : AppTheme.neutralLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, size: 14),
                                      onPressed: () {
                                        cart.updateQuantity(item.product.id, item.quantity - 1);
                                      },
                                      constraints: const BoxConstraints(
                                        minWidth: 28,
                                        minHeight: 28,
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6),
                                      child: Text(
                                        '${item.quantity}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add, size: 14),
                                      onPressed: () {
                                        cart.updateQuantity(item.product.id, item.quantity + 1);
                                      },
                                      constraints: const BoxConstraints(
                                        minWidth: 28,
                                        minHeight: 28,
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              // Delete button
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 16),
                                onPressed: () {
                                  cart.removeProduct(item.product.id);
                                },
                                color: AppTheme.errorColor,
                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),

        // Checkout section
        if (cartItems.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  // Summary
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total',
                            style: TextStyle(fontSize: 13, color: AppTheme.neutralDark),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '\$${cart.totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${cart.itemCount} ${cart.itemCount == 1 ? 'item' : 'items'}',
                        style: TextStyle(fontSize: 13, color: AppTheme.neutralDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Checkout button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          onCheckout ??
                          () {
                            Navigator.of(
                              context,
                            ).push(MaterialPageRoute(builder: (context) => const CheckoutScreen()));
                          },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text('Checkout', style: TextStyle(fontSize: 15)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
