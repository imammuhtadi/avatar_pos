import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:avatar_pos/core/index.dart';
import 'package:avatar_pos/features/categories/index.dart';

/// Category form screen for creating and editing categories
class CategoryFormScreen extends ConsumerStatefulWidget {
  final Category? category;

  const CategoryFormScreen({super.key, this.category});

  @override
  ConsumerState<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends ConsumerState<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  String? _selectedIcon;
  String? _selectedColor;
  bool _isActive = true;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _availableIcons = [
    {'name': 'category', 'icon': Icons.category},
    {'name': 'fastfood', 'icon': Icons.fastfood},
    {'name': 'local_drink', 'icon': Icons.local_drink},
    {'name': 'restaurant', 'icon': Icons.restaurant},
    {'name': 'coffee', 'icon': Icons.coffee},
    {'name': 'cake', 'icon': Icons.cake},
    {'name': 'icecream', 'icon': Icons.icecream},
    {'name': 'local_pizza', 'icon': Icons.local_pizza},
    {'name': 'lunch_dining', 'icon': Icons.lunch_dining},
    {'name': 'breakfast_dining', 'icon': Icons.breakfast_dining},
    {'name': 'dinner_dining', 'icon': Icons.dinner_dining},
    {'name': 'shopping_bag', 'icon': Icons.shopping_bag},
    {'name': 'local_grocery_store', 'icon': Icons.local_grocery_store},
  ];

  final List<String> _availableColors = [
    'FF6366F1', // Indigo
    'FFEF4444', // Red
    'FFF59E0B', // Amber
    'FF10B981', // Green
    'FF3B82F6', // Blue
    'FF8B5CF6', // Purple
    'FFEC4899', // Pink
    'FF06B6D4', // Cyan
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _descriptionController = TextEditingController(text: widget.category?.description ?? '');
    _selectedIcon = widget.category?.icon ?? 'category';
    _selectedColor = widget.category?.color ?? 'FF6366F1';
    _isActive = widget.category?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(categoriesNotifierProvider.notifier);
      final category = Category(
        id: widget.category?.id ?? '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        icon: _selectedIcon,
        color: _selectedColor,
        isActive: _isActive,
      );

      if (widget.category == null) {
        await notifier.createCategory(category);
      } else {
        await notifier.updateCategory(category);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.category == null
                  ? 'Category created successfully'
                  : 'Category updated successfully',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteCategory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: const Text(
          'Are you sure you want to delete this category? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(categoriesNotifierProvider.notifier);
      await notifier.deleteCategory(widget.category!.id);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category deleted successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category == null ? 'New Category' : 'Edit Category'),
        actions: [
          if (widget.category != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isLoading ? null : _deleteCategory,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                hintText: 'e.g., Beverages, Snacks',
                prefixIcon: Icon(Icons.label),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter category name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Brief description',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Icon selection
            const Text('Select Icon', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _availableIcons.map((iconData) {
                final isSelected = _selectedIcon == iconData['name'];
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedIcon = iconData['name']);
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.accentColor.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppTheme.accentColor : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      iconData['icon'],
                      color: isSelected ? AppTheme.accentColor : Colors.grey[600],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Color selection
            const Text('Select Color', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _availableColors.map((colorHex) {
                final color = Color(int.parse('0x$colorHex'));
                final isSelected = _selectedColor == colorHex;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedColor = colorHex);
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Active status
            SwitchListTile(
              title: const Text('Active'),
              subtitle: const Text('Category is visible and can be used'),
              value: _isActive,
              onChanged: (value) {
                setState(() => _isActive = value);
              },
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveCategory,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.category == null ? 'Create Category' : 'Update Category'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
