import 'product.dart';

class CartItemModel {
  const CartItemModel({
    required this.id,
    required this.product,
    required this.quantity,
  });

  final int id;
  final ProductModel product;
  final int quantity;

  double get lineTotal => product.price * quantity;

  CartItemModel copyWith({int? quantity}) => CartItemModel(
        id: id,
        product: product,
        quantity: quantity ?? this.quantity,
      );

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final product = ProductModel(
      id: int.tryParse('${json['product_id'] ?? 0}') ?? 0,
      categoryId: int.tryParse('${json['category_id'] ?? 0}') ?? 0,
      name: '${json['name'] ?? ''}',
      description: '${json['description'] ?? ''}',
      price: double.tryParse('${json['price'] ?? 0}') ?? 0,
      stockQty: int.tryParse('${json['stock_qty'] ?? 0}') ?? 0,
      imageUrl: '${json['image_url'] ?? ''}',
      categoryName: json['category_name']?.toString(),
      categorySlug: json['category_slug']?.toString(),
    );
    return CartItemModel(
      id: int.tryParse('${json['cart_item_id'] ?? json['id'] ?? 0}') ?? 0,
      product: product,
      quantity: int.tryParse('${json['quantity'] ?? 1}') ?? 1,
    );
  }
}
