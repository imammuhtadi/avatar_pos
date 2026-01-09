// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProductImpl _$$ProductImplFromJson(Map<String, dynamic> json) =>
    _$ProductImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      stock: (json['stock'] as num).toInt(),
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      categoryId: json['category_id'] as String?,
      cost: (json['cost'] as num?)?.toDouble(),
      minStock: (json['min_stock'] as num?)?.toInt() ?? 0,
      unit: json['unit'] as String? ?? 'pcs',
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$ProductImplToJson(_$ProductImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'price': instance.price,
      'stock': instance.stock,
      'sku': instance.sku,
      'barcode': instance.barcode,
      'category_id': instance.categoryId,
      'cost': instance.cost,
      'min_stock': instance.minStock,
      'unit': instance.unit,
      'image_url': instance.imageUrl,
      'is_active': instance.isActive,
      'created_by': instance.createdBy,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
