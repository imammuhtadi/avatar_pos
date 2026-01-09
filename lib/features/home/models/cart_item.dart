import 'package:freezed_annotation/freezed_annotation.dart';
import 'product.dart';

part 'cart_item.freezed.dart';
part 'cart_item.g.dart';

/// Cart item model
@freezed
class CartItem with _$CartItem {
  const factory CartItem({required Product product, required int quantity}) =
      _CartItem;

  const CartItem._();

  factory CartItem.fromJson(Map<String, dynamic> json) =>
      _$CartItemFromJson(json);

  /// Calculate total price for this cart item
  double get totalPrice => product.price * quantity;
}
