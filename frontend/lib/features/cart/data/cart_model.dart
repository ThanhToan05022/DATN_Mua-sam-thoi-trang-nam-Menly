import 'package:flutter/foundation.dart';
import '../../../../core/network/dio_client.dart';
import '../../product/data/models/product_model.dart';

class CartItem {
  final Product product;
  final ProductVariant variant;
  int quantity;

  CartItem({
    required this.product,
    required this.variant,
    required this.quantity,
  });

  int get subtotal => product.price * quantity;

  factory CartItem.fromServerJson(Map<String, dynamic> json) {
    final variantId = json['variantId'] as String? ?? '';
    final productName = json['productName'] as String? ?? 'Sản phẩm Menly';
    final size = json['size'] as String? ?? '';
    final color = json['color'] as String? ?? '';
    final price = (json['price'] as num?)?.toInt() ?? 0;
    final stock = (json['stock'] as num?)?.toInt() ?? 50;
    final thumbnailUrl = json['thumbnailUrl'] as String?;
    final quantity = (json['quantity'] as num?)?.toInt() ?? 1;

    final variant = ProductVariant(
      id: variantId,
      size: size,
      color: color,
      sku: 'SKU-${variantId.length > 8 ? variantId.substring(variantId.length - 8) : variantId}',
      stock: stock,
    );

    final product = Product(
      id: json['productId'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? '',
      name: productName,
      slug: json['slug'] as String? ?? '',
      price: price,
      thumbnailUrl: thumbnailUrl,
      isActive: true,
      createdAt: json['updatedAt'] as String? ?? '',
      variants: [variant],
    );

    return CartItem(
      product: product,
      variant: variant,
      quantity: quantity,
    );
  }
}

class CartProvider extends ChangeNotifier {
  final DioClient _dioClient;
  List<CartItem> _items = [];
  bool _isLoading = false;
  String? _errorMessage;

  CartProvider({DioClient? dioClient})
      : _dioClient = dioClient ?? DioClient.instance {
    fetchCart();
  }

  List<CartItem> get items => List.unmodifiable(_items);
  int get totalItems => _items.fold(0, (s, i) => s + i.quantity);
  int get totalPrice => _items.fold(0, (s, i) => s + i.subtotal);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Tải dữ liệu giỏ hàng từ API /api/v1/cart
  Future<void> fetchCart({bool showLoading = false}) async {
    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final res = await _dioClient.dio.get('/cart');
      if (res.statusCode == 200 && res.data is Map) {
        final data = res.data as Map<String, dynamic>;
        final rawItems = data['items'] as List<dynamic>? ?? [];
        _items = rawItems
            .map((item) => CartItem.fromServerJson(item as Map<String, dynamic>))
            .toList();
        _errorMessage = null;
      }
    } catch (e) {
      debugPrint('[CartProvider] fetchCart error: $e');
      _errorMessage = 'Không thể đồng bộ giỏ hàng';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Thêm sản phẩm vào giỏ và đồng bộ với API: PUT /api/v1/cart/items
  Future<void> addItem(Product product, ProductVariant variant, int qty) async {
    final idx = _items.indexWhere((i) => i.variant.id == variant.id);
    final targetQty = idx >= 0 ? (_items[idx].quantity + qty) : qty;

    // Cập nhật optimistic
    if (idx >= 0) {
      _items[idx].quantity = targetQty;
    } else {
      _items.add(CartItem(product: product, variant: variant, quantity: qty));
    }
    notifyListeners();

    try {
      final res = await _dioClient.dio.put('/cart/items', data: {
        'variantId': variant.id,
        'quantity': targetQty,
      });

      if (res.statusCode == 200 && res.data is Map) {
        final data = res.data as Map<String, dynamic>;
        final rawItems = data['items'] as List<dynamic>? ?? [];
        _items = rawItems
            .map((item) => CartItem.fromServerJson(item as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[CartProvider] addItem API error: $e');
      await fetchCart();
    }
  }

  /// Cập nhật số lượng sản phẩm: PUT /api/v1/cart/items
  Future<void> updateQty(String variantId, int qty) async {
    if (qty <= 0) {
      await removeItem(variantId);
      return;
    }

    final idx = _items.indexWhere((i) => i.variant.id == variantId);
    if (idx >= 0) {
      _items[idx].quantity = qty;
      notifyListeners();
    }

    try {
      final res = await _dioClient.dio.put('/cart/items', data: {
        'variantId': variantId,
        'quantity': qty,
      });

      if (res.statusCode == 200 && res.data is Map) {
        final data = res.data as Map<String, dynamic>;
        final rawItems = data['items'] as List<dynamic>? ?? [];
        _items = rawItems
            .map((item) => CartItem.fromServerJson(item as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[CartProvider] updateQty API error: $e');
      await fetchCart();
    }
  }

  /// Xoá một mặt hàng khỏi giỏ: DELETE /api/v1/cart/items/:variantId
  Future<void> removeItem(String variantId) async {
    _items.removeWhere((i) => i.variant.id == variantId);
    notifyListeners();

    try {
      final res = await _dioClient.dio.delete('/cart/items/$variantId');
      if (res.statusCode == 200 && res.data is Map) {
        final data = res.data as Map<String, dynamic>;
        final rawItems = data['items'] as List<dynamic>? ?? [];
        _items = rawItems
            .map((item) => CartItem.fromServerJson(item as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[CartProvider] removeItem API error: $e');
      await fetchCart();
    }
  }

  /// Xoá toàn bộ giỏ hàng: DELETE /api/v1/cart
  Future<void> clear() async {
    _items.clear();
    notifyListeners();

    try {
      await _dioClient.dio.delete('/cart');
    } catch (e) {
      debugPrint('[CartProvider] clear API error: $e');
      await fetchCart();
    }
  }

  /// Đặt lại giỏ hàng trong RAM (dùng khi đăng xuất, không gọi API xóa giỏ hàng trên server)
  void resetLocal() {
    _items.clear();
    _errorMessage = null;
    notifyListeners();
  }
}
