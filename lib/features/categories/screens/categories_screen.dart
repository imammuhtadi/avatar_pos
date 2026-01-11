import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:avatar_pos/core/index.dart';
import 'package:avatar_pos/features/categories/index.dart';

/// Categories list screen
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesState = ref.watch(categoriesNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(categoriesNotifierProvider.notifier).loadCategories(),
          ),
        ],
      ),
      body: categoriesState.isLoading && categoriesState.categories.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : categoriesState.error != null && categoriesState.categories.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
                  const SizedBox(height: 16),
                  const Text('Error loading categories'),
                  const SizedBox(height: 8),
                  Text(
                    categoriesState.error!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => ref.read(categoriesNotifierProvider.notifier).loadCategories(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            )
          : categoriesState.categories.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No categories yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your first category',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: categoriesState.categories.length,
              itemBuilder: (context, index) {
                final category = categoriesState.categories[index];
                final isToggling = categoriesState.togglingId == category.id;
                return _buildCategoryCard(context, ref, category, isDark, isToggling);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => const CategoryFormScreen()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    WidgetRef ref,
    Category category,
    bool isDark,
    bool isToggling,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => CategoryFormScreen(category: category)));
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _parseColor(category.color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIconData(category.icon),
                  color: _parseColor(category.color),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Name and description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    if (category.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        category.description!,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Status toggle
              isToggling
                  ? const SizedBox(
                      width: 48,
                      height: 24,
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : Switch(
                      value: category.isActive,
                      onChanged: (value) async {
                        try {
                          await ref
                              .read(categoriesNotifierProvider.notifier)
                              .toggleActive(category.id, value);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  value ? 'Category activated' : 'Category deactivated',
                                ),
                                backgroundColor: AppTheme.successColor,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: AppTheme.errorColor,
                              ),
                            );
                          }
                        }
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Color _parseColor(String? colorHex) {
    if (colorHex == null) return AppTheme.accentColor;

    try {
      return Color(int.parse('0x$colorHex'));
    } catch (e) {
      // If parsing fails, return default accent color
      return AppTheme.accentColor;
    }
  }

  IconData _getIconData(String? iconName) {
    if (iconName == null) return Icons.category;

    final iconMap = {
      'fastfood': Icons.fastfood,
      'local_drink': Icons.local_drink,
      'restaurant': Icons.restaurant,
      'coffee': Icons.coffee,
      'cake': Icons.cake,
      'icecream': Icons.icecream,
      'local_pizza': Icons.local_pizza,
      'lunch_dining': Icons.lunch_dining,
      'breakfast_dining': Icons.breakfast_dining,
      'dinner_dining': Icons.dinner_dining,
      'category': Icons.category,
      'shopping_bag': Icons.shopping_bag,
      'local_grocery_store': Icons.local_grocery_store,
    };

    return iconMap[iconName] ?? Icons.category;
  }
}
