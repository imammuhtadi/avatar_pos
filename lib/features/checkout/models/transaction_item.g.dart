// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TransactionItemImpl _$$TransactionItemImplFromJson(
  Map<String, dynamic> json,
) => _$TransactionItemImpl(
  id: json['id'] as String,
  transactionId: json['transaction_id'] as String,
  productId: json['product_id'] as String,
  productName: json['product_name'] as String,
  quantity: (json['quantity'] as num).toInt(),
  unitPrice: (json['unit_price'] as num).toDouble(),
  subtotal: (json['subtotal'] as num).toDouble(),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$$TransactionItemImplToJson(
  _$TransactionItemImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'transaction_id': instance.transactionId,
  'product_id': instance.productId,
  'product_name': instance.productName,
  'quantity': instance.quantity,
  'unit_price': instance.unitPrice,
  'subtotal': instance.subtotal,
  'created_at': instance.createdAt?.toIso8601String(),
};
