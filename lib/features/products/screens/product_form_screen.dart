import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:avatar_pos/core/index.dart';
import 'package:avatar_pos/features/home/index.dart';

/// Product form screen for adding or editing products
class ProductFormScreen extends ConsumerStatefulWidget {
  final Product? product; // null for add, non-null for edit

  const ProductFormScreen({super.key, this.product});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _costController = TextEditingController();
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _unitController = TextEditingController();

  bool _isLoading = false;
  bool get _isEditMode => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _populateForm();
    } else {
      _unitController.text = 'pcs'; // Default unit
    }
  }

  void _populateForm() {
    final product = widget.product!;
    _nameController.text = product.name;
    _descriptionController.text = product.description;
    _priceController.text = product.price.toString();
    _costController.text = product.cost?.toString() ?? '';
    _stockController.text = product.stock.toString();
    _minStockController.text = product.minStock.toString();
    _skuController.text = product.sku ?? '';
    _barcodeController.text = product.barcode ?? '';
    _unitController.text = product.unit;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ Form validation failed');
      return;
    }

    debugPrint('📝 ${_isEditMode ? "Updating" : "Creating"} product...');
    setState(() => _isLoading = true);

    try {
      final repository = ProductRepository();

      final productData = Product(
        id: _isEditMode ? widget.product!.id : '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text),
        cost: _costController.text.isEmpty ? null : double.parse(_costController.text),
        stock: int.parse(_stockController.text),
        minStock: int.parse(_minStockController.text),
        sku: _skuController.text.trim().isEmpty ? null : _skuController.text.trim(),
        barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
        unit: _unitController.text.trim(),
        isActive: true,
      );

      debugPrint('📦 Product data:');
      debugPrint('   Name: ${productData.name}');
      debugPrint('   Price: \$${productData.price}');
      debugPrint('   Stock: ${productData.stock}');
      debugPrint('   SKU: ${productData.sku ?? "N/A"}');

      if (_isEditMode) {
        debugPrint('🔄 Updating product ID: ${widget.product!.id}');
        await repository.updateProduct(widget.product!.id, productData);
        debugPrint('✅ Product updated successfully');
      } else {
        debugPrint('➕ Creating new product');
        final createdProduct = await repository.createProduct(productData);
        debugPrint('✅ Product created with ID: ${createdProduct.id}');
      }

      // Refresh products list
      ref.invalidate(productsProvider);
      debugPrint('🔄 Products list refreshed');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode ? 'Product updated successfully' : 'Product added successfully',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error ${_isEditMode ? "updating" : "creating"} product: $e');
      debugPrint('Stack trace: $stackTrace');

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
      appBar: AppBar(title: Text(_isEditMode ? 'Edit Product' : 'Add Product')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Product Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Product Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter product name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description_outlined),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Price and Cost
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Selling Price *',
                      border: OutlineInputBorder(),
                      prefixText: '\$ ',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _costController,
                    decoration: const InputDecoration(
                      labelText: 'Cost Price',
                      border: OutlineInputBorder(),
                      prefixText: '\$ ',
                      prefixIcon: Icon(Icons.money_off_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (double.tryParse(value) == null) {
                          return 'Invalid';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stock and Min Stock
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _stockController,
                    decoration: const InputDecoration(
                      labelText: 'Stock *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.inventory_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _minStockController,
                    decoration: const InputDecoration(
                      labelText: 'Min Stock *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.warning_amber_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // SKU and Barcode
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _skuController,
                    decoration: const InputDecoration(
                      labelText: 'SKU',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.qr_code_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _barcodeController,
                    decoration: const InputDecoration(
                      labelText: 'Barcode',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.barcode_reader),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Unit
            TextFormField(
              controller: _unitController,
              decoration: const InputDecoration(
                labelText: 'Unit *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.straighten_outlined),
                hintText: 'e.g., pcs, kg, liter',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter unit';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveProduct,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(_isEditMode ? Icons.save : Icons.add),
                label: Text(
                  _isLoading
                      ? 'Saving...'
                      : _isEditMode
                      ? 'Update Product'
                      : 'Add Product',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
