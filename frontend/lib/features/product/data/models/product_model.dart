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

  String get imageUrl => thumbnailUrl ?? '';
  int get stock => variants.fold(0, (sum, v) => sum + v.stock);



  factory Product.fromJson(Map<String, dynamic> j) {
    final parsedVariants = (j['variants'] as List<dynamic>?)
            ?.map((v) => ProductVariant.fromJson(v))
            .toList() ??
        [];
    final pid = j['id'] ?? '';
    final slug = j['slug'] ?? 'item';
    final pidStr = pid.toString();
    final padded = pidStr.length >= 12 ? pidStr.substring(pidStr.length - 12) : '000000000001';
    final variants = parsedVariants.isNotEmpty
        ? parsedVariants
        : [
            ProductVariant(id: 'b0000000-0000-0001-0001-$padded', size: 'M', color: 'Trắng', sku: 'SKU-$slug-W-M', stock: 50),
            ProductVariant(id: 'b0000000-0000-0002-0001-$padded', size: 'M', color: 'Đen', sku: 'SKU-$slug-B-M', stock: 50),
            ProductVariant(id: 'b0000000-0000-0001-0002-$padded', size: 'L', color: 'Trắng', sku: 'SKU-$slug-W-L', stock: 45),
            ProductVariant(id: 'b0000000-0000-0002-0002-$padded', size: 'L', color: 'Đen', sku: 'SKU-$slug-B-L', stock: 45),
            ProductVariant(id: 'b0000000-0000-0001-0003-$padded', size: 'XL', color: 'Trắng', sku: 'SKU-$slug-W-XL', stock: 40),
            ProductVariant(id: 'b0000000-0000-0002-0003-$padded', size: 'XL', color: 'Đen', sku: 'SKU-$slug-B-XL', stock: 40),
          ];

    return Product(
      id: pid,
      categoryId: j['categoryId'] ?? j['category_id'] ?? '',
      name: j['name'] ?? '',
      slug: slug,
      description: j['description'],
      price: (j['price'] is double) ? (j['price'] as double).toInt() : (j['price'] ?? 0),
      thumbnailUrl: j['thumbnailUrl'] ?? j['thumbnail_url'],
      isActive: j['isActive'] ?? j['is_active'] ?? true,
      createdAt: j['createdAt'] ?? j['created_at'] ?? '',
      variants: variants,
    );
  }
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
