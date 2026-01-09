// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.freezed.dart';
part 'product.g.dart';

/// Product model for POS system
@freezed
class Product with _$Product {
  const factory Product({
    required String id,
    required String name,
    required String description,
    required double price,
    required int stock,
    String? sku,
    String? barcode,
    @JsonKey(name: 'category_id') String? categoryId,
    double? cost,
    @JsonKey(name: 'min_stock') @Default(0) int minStock,
    @Default('pcs') String unit,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'created_by') String? createdBy,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
}
