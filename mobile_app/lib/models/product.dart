class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
  });

  final int id;
  final String name;
  final String slug;
  final String? icon;

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: int.tryParse('${json['category_id'] ?? json['id'] ?? 0}') ?? 0,
        name: '${json['name'] ?? ''}',
        slug: '${json['slug'] ?? ''}',
        icon: json['icon']?.toString(),
      );
}

class ProductModel {
  const ProductModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    required this.stockQty,
    required this.imageUrl,
    this.categoryName,
    this.categorySlug,
  });

  final int id;
  final int categoryId;
  final String name;
  final String description;
  final double price;
  final int stockQty;
  final String imageUrl;
  final String? categoryName;
  final String? categorySlug;

  bool get inStock => stockQty > 0;

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
        id: int.tryParse('${json['product_id'] ?? json['id'] ?? 0}') ?? 0,
        categoryId: int.tryParse('${json['category_id'] ?? 0}') ?? 0,
        name: '${json['name'] ?? ''}',
        description: '${json['description'] ?? ''}',
        price: double.tryParse('${json['price'] ?? 0}') ?? 0,
        stockQty:
            int.tryParse('${json['stock_qty'] ?? json['stock'] ?? 0}') ?? 0,
        imageUrl: '${json['image_url'] ?? json['image'] ?? ''}',
        categoryName: json['category_name']?.toString(),
        categorySlug: json['category_slug']?.toString(),
      );
}
