import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:avatar_pos/core/index.dart';
import 'package:avatar_pos/features/home/index.dart';
import 'package:avatar_pos/features/products/index.dart';

/// Products management screen
class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(productsProvider);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => const ProductFormScreen()));
          if (result == true) {
            ref.invalidate(productsProvider);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
        backgroundColor: AppTheme.accentColor,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),

          // Products list
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
                    const SizedBox(height: 16),
                    const Text('Error loading products'),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => ref.invalidate(productsProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (products) {
                // Filter products based on search
                final filteredProducts = products.where((product) {
                  if (_searchQuery.isEmpty) return true;
                  return product.name.toLowerCase().contains(_searchQuery) ||
                      (product.sku?.toLowerCase().contains(_searchQuery) ?? false) ||
                      (product.barcode?.toLowerCase().contains(_searchQuery) ?? false);
                }).toList();

                if (filteredProducts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isEmpty ? Icons.inventory_2_outlined : Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty ? 'No products yet' : 'No products found',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        if (_searchQuery.isEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Tap the + button to add your first product',
                            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return _buildProductCard(context, product, isDark);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product, bool isDark) {
    final isLowStock = product.stock <= product.minStock;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => ProductFormScreen(product: product)));
          if (result == true) {
            ref.invalidate(productsProvider);
          }
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Product icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.inventory_2, color: AppTheme.accentColor),
                  ),
                  const SizedBox(width: 12),
                  // Product name and SKU
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        if (product.sku != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'SKU: ${product.sku}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Actions
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [Icon(Icons.edit, size: 20), SizedBox(width: 12), Text('Edit')],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 12),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) async {
                      if (value == 'edit') {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ProductFormScreen(product: product),
                          ),
                        );
                        if (result == true) {
                          ref.invalidate(productsProvider);
                        }
                      } else if (value == 'delete') {
                        _showDeleteDialog(product);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                product.description,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Price and Stock info
              Row(
                children: [
                  // Price
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[850] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Price', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          const SizedBox(height: 4),
                          Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Stock
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isLowStock
                            ? AppTheme.errorColor.withOpacity(0.1)
                            : isDark
                            ? Colors.grey[850]
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Stock',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                              if (isLowStock) ...[
                                const SizedBox(width: 4),
                                Icon(Icons.warning_amber, size: 14, color: AppTheme.errorColor),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${product.stock} ${product.unit}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isLowStock ? AppTheme.errorColor : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ProductRepository().deleteProduct(product.id);
                ref.invalidate(productsProvider);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Product deleted successfully'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
