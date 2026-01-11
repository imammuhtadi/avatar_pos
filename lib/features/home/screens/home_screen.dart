import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:avatar_pos/core/index.dart';
import 'package:avatar_pos/shared/index.dart';
import 'package:avatar_pos/features/cart/index.dart';
import 'package:avatar_pos/features/home/index.dart';

/// Home screen - main dashboard for POS
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> _filterProducts(List<Product> products) {
    if (_searchQuery.isEmpty) {
      return products;
    }

    final query = _searchQuery.toLowerCase();
    return products.where((product) {
      final matchesName = product.name.toLowerCase().contains(query);
      final description = product.description;
      final matchesDescription = description.toLowerCase().contains(query);
      final sku = product.sku;
      final matchesSku = sku != null && sku.toLowerCase().contains(query);
      return matchesName || matchesDescription || matchesSku;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final cartItemCount = ref.watch(cartItemCountProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Check if cart panel will be shown (768px = iPad Mini and larger)
        final showCartPanel = constraints.maxWidth >= 768;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search products...',
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.5)
                      : Colors.black.withOpacity(0.5),
                ),
              ),
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
            actions: [
              // Clear search button
              if (_searchQuery.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                  tooltip: 'Clear search',
                ),
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
                        final filteredProducts = _filterProducts(products);

                        if (filteredProducts.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _searchQuery.isEmpty
                                      ? Icons.inventory_2_outlined
                                      : Icons.search_off,
                                  size: 64,
                                  color: AppTheme.neutralDark,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'No products available'
                                      : 'No products found',
                                  style: TextStyle(fontSize: 16, color: AppTheme.neutralDark),
                                ),
                                if (_searchQuery.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Try searching with different keywords',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.neutralDark.withOpacity(0.7),
                                    ),
                                  ),
                                ],
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
                              itemCount: filteredProducts.length,
                              itemBuilder: (context, index) {
                                return ProductCard(product: filteredProducts[index]);
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
