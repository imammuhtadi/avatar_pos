// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'transaction_item.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

/// Transaction model for completed sales
@freezed
class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    @JsonKey(name: 'transaction_number') required String transactionNumber,
    @JsonKey(name: 'cashier_id') String? cashierId,
    @JsonKey(name: 'customer_name') String? customerName,
    @JsonKey(name: 'customer_phone') String? customerPhone,
    @JsonKey(name: 'customer_email') String? customerEmail,
    required double subtotal,
    @Default(0) double tax,
    @Default(0) double discount,
    required double total,
    @JsonKey(name: 'payment_method') required String paymentMethod,
    @JsonKey(name: 'payment_status') @Default('completed') String paymentStatus,
    @JsonKey(name: 'paid_amount') double? paidAmount,
    @JsonKey(name: 'change_amount') @Default(0) double changeAmount,
    String? notes,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    // Items are loaded separately
    List<TransactionItem>? items,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) => _$TransactionFromJson(json);
}

/// Payment method enum
enum PaymentMethod {
  cash,
  card,
  @JsonValue('digital_wallet')
  digitalWallet,
  @JsonValue('bank_transfer')
  bankTransfer;

  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.digitalWallet:
        return 'Digital Wallet';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
    }
  }
}
