import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../home/providers/cart_provider.dart';
import '../../../core/theme/app_theme.dart';

/// Modern cart screen with clean design
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final cart = ref.read(cartProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
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
                  ),
                );
              },
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Clear'),
            ),
        ],
      ),
      body: cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 80,
                    color: AppTheme.neutralDark.withOpacity(0.3),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.neutralDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add some products to get started',
                    style: TextStyle(fontSize: 14, color: AppTheme.neutralDark.withOpacity(0.7)),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Cart items list
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartItems.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(14),
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
                            // Title row - dedicated space for product name
                            Text(
                              item.product.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),

                            // Main content row - image, price, and controls
                            Row(
                              children: [
                                // Product image placeholder
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.03)
                                        : AppTheme.neutralLight,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.shopping_bag_outlined,
                                    size: 24,
                                    color: AppTheme.neutralDark.withOpacity(0.3),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Price info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            '\$${item.product.price.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: AppTheme.neutralDark,
                                            ),
                                          ),
                                          Text(
                                            ' × ${item.quantity}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: AppTheme.neutralDark,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '\$${item.totalPrice.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.accentColor,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Quantity controls
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Quantity adjuster
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
                                            icon: const Icon(Icons.remove, size: 16),
                                            onPressed: () {
                                              cart.updateQuantity(
                                                item.product.id,
                                                item.quantity - 1,
                                              );
                                            },
                                            constraints: const BoxConstraints(
                                              minWidth: 32,
                                              minHeight: 32,
                                            ),
                                            padding: EdgeInsets.zero,
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            child: Text(
                                              '${item.quantity}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add, size: 16),
                                            onPressed: () {
                                              cart.updateQuantity(
                                                item.product.id,
                                                item.quantity + 1,
                                              );
                                            },
                                            constraints: const BoxConstraints(
                                              minWidth: 32,
                                              minHeight: 32,
                                            ),
                                            padding: EdgeInsets.zero,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    // Delete button
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18),
                                      onPressed: () {
                                        cart.removeProduct(item.product.id);
                                      },
                                      color: AppTheme.errorColor,
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ],
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
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.05),
                      ),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      children: [
                        // Summary row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total',
                                  style: TextStyle(fontSize: 14, color: AppTheme.neutralDark),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '\$${cart.totalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -1,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${cart.itemCount} ${cart.itemCount == 1 ? 'item' : 'items'}',
                              style: TextStyle(fontSize: 14, color: AppTheme.neutralDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Checkout button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Row(
                                    children: [
                                      Icon(Icons.info_outline, color: Colors.white, size: 20),
                                      SizedBox(width: 12),
                                      Text('Checkout - Coming Soon'),
                                    ],
                                  ),
                                  backgroundColor: AppTheme.accentColor,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Text('Proceed to Checkout', style: TextStyle(fontSize: 16)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
