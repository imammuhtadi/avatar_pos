// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_item.freezed.dart';
part 'transaction_item.g.dart';

/// Transaction item model for individual products in a transaction
@freezed
class TransactionItem with _$TransactionItem {
  const factory TransactionItem({
    required String id,
    @JsonKey(name: 'transaction_id') required String transactionId,
    @JsonKey(name: 'product_id') required String productId,
    @JsonKey(name: 'product_name') required String productName,
    required int quantity,
    @JsonKey(name: 'unit_price') required double unitPrice,
    required double subtotal,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _TransactionItem;

  factory TransactionItem.fromJson(Map<String, dynamic> json) => _$TransactionItemFromJson(json);
}
