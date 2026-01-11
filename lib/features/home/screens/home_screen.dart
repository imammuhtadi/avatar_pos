import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../providers/products_provider.dart';
import '../../cart/providers/cart_provider.dart';
import '../widgets/product_card.dart';
import '../../cart/widgets/cart_panel.dart';

/// Home screen - main dashboard for POS
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    final cartItemCount = ref.watch(cartItemCountProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Check if cart panel will be shown (768px = iPad Mini and larger)
        final showCartPanel = constraints.maxWidth >= 768;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text('Products'),
            actions: [
              // Only show cart button on smaller screens
              if (!showCartPanel)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shopping_bag_outlined),
                        onPressed: () => context.push(AppRouter.cart),
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.surface,
                        ),
                      ),
                      if (cartItemCount > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).scaffoldBackgroundColor,
                                width: 2,
                              ),
                            ),
                            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                            child: Text(
                              '$cartItemCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
          drawer: const AppDrawer(),
          body: LayoutBuilder(
            builder: (context, constraints) {
              // Show cart panel on the right for screens 768px and wider (iPad Mini+)
              final showCartPanel = constraints.maxWidth >= 768;
              // Use narrower cart on smaller tablets (768-1024px)
              final cartPanelWidth = constraints.maxWidth < 1024 ? 320.0 : 380.0;

              return Row(
                children: [
                  // Products grid
                  Expanded(
                    child: productsAsync.when(
                      data: (products) {
                        if (products.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 64,
                                  color: AppTheme.neutralDark,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No products available',
                                  style: TextStyle(fontSize: 16, color: AppTheme.neutralDark),
                                ),
                              ],
                            ),
                          );
                        }

                        return LayoutBuilder(
                          builder: (context, productConstraints) {
                            // Responsive grid columns with better breakpoints
                            int crossAxisCount = 2;
                            double childAspectRatio = 0.75;

                            final availableWidth = productConstraints.maxWidth;

                            if (availableWidth > 1400) {
                              crossAxisCount = 5;
                              childAspectRatio = 0.8;
                            } else if (availableWidth > 1100) {
                              crossAxisCount = 4;
                              childAspectRatio = 0.78;
                            } else if (availableWidth > 800) {
                              crossAxisCount = 3;
                              childAspectRatio = 0.76;
                            } else if (availableWidth > 350) {
                              // iPad Mini with cart panel: 768-320=448px available
                              crossAxisCount = 2;
                              childAspectRatio = 0.75;
                            } else {
                              // Very narrow screens
                              crossAxisCount = 1;
                              childAspectRatio = 1.2;
                            }

                            return GridView.builder(
                              padding: const EdgeInsets.all(20),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                childAspectRatio: childAspectRatio,
                                crossAxisSpacing: 20,
                                mainAxisSpacing: 20,
                              ),
                              itemCount: products.length,
                              itemBuilder: (context, index) {
                                return ProductCard(product: products[index]);
                              },
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
                            const SizedBox(height: 16),
                            Text(
                              'Failed to load products',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.errorColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              error.toString(),
                              style: TextStyle(fontSize: 14, color: AppTheme.neutralDark),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () => ref.invalidate(productsProvider),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Cart panel (only on larger screens)
                  if (showCartPanel)
                    Container(
                      width: cartPanelWidth,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        border: Border(
                          left: BorderSide(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.05),
                          ),
                        ),
                      ),
                      child: const CartPanel(showHeader: true),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
