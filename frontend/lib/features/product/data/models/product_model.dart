class ProductVariant {
  final String id;
  final String size;
  final String color;
  final String sku;
  final int stock;

  ProductVariant({required this.id, required this.size, required this.color, required this.sku, required this.stock});

  factory ProductVariant.fromJson(Map<String, dynamic> j) => ProductVariant(
    id: j['id'] ?? '',
    size: j['size'] ?? '',
    color: j['color'] ?? '',
    sku: j['sku'] ?? '',
    stock: j['stock'] ?? 0,
  );
}

class Product {
  final String id;
  final String categoryId;
  final String name;
  final String slug;
  final String? description;
  final int price;
  final String? thumbnailUrl;
  final bool isActive;
  final String createdAt;
  final List<ProductVariant> variants;

  Product({
    required this.id, required this.categoryId, required this.name,
    required this.slug, this.description, required this.price,
    this.thumbnailUrl, required this.isActive, required this.createdAt,
    this.variants = const [],
  });

  factory Product.fromJson(Map<String, dynamic> j) => Product(
    id: j['id'] ?? '',
    categoryId: j['categoryId'] ?? j['category_id'] ?? '',
    name: j['name'] ?? '',
    slug: j['slug'] ?? '',
    description: j['description'],
    price: (j['price'] is double) ? (j['price'] as double).toInt() : (j['price'] ?? 0),
    thumbnailUrl: j['thumbnailUrl'] ?? j['thumbnail_url'],
    isActive: j['isActive'] ?? j['is_active'] ?? true,
    createdAt: j['createdAt'] ?? j['created_at'] ?? '',
    variants: (j['variants'] as List<dynamic>?)?.map((v) => ProductVariant.fromJson(v)).toList() ?? [],
  );
}

class Category {
  final String id;
  final String name;
  final String slug;
  final String? imageUrl;

  Category({required this.id, required this.name, required this.slug, this.imageUrl});

  factory Category.fromJson(Map<String, dynamic> j) => Category(
    id: j['id'] ?? '',
    name: j['name'] ?? '',
    slug: j['slug'] ?? '',
    imageUrl: j['imageUrl'] ?? j['image_url'],
  );
}
