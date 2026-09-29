import 'package:flutter/foundation.dart';
import '../../product/data/models/product_model.dart';

class CartItem {
  final Product product;
  final ProductVariant variant;
  int quantity;

  CartItem({required this.product, required this.variant, required this.quantity});

  int get subtotal => product.price * quantity;
}

class CartProvider extends ChangeNotifier {
  /// Trung cao nhat cho 1 bien the, khop voi validate
  /// `createOrderSchema` cua backend (items[].quantity: int min 1 max 20).
  static const int maxQtyPerItem = 20;

  final List<CartItem> _items = [];
  List<CartItem> get items => List.unmodifiable(_items);
  int get totalItems => _items.fold(0, (s, i) => s + i.quantity);
  int get totalPrice => _items.fold(0, (s, i) => s + i.subtotal);

  /// So luong toi da gom chua vuot [maxQtyPerItem] va con ton kho.
  int effectiveMax(ProductVariant variant) {
    final stock = variant.stock;
    if (stock <= 0) return 0;
    return stock < maxQtyPerItem ? stock : maxQtyPerItem;
  }

  void addItem(Product product, ProductVariant variant, int qty) {
    final max = effectiveMax(variant);
    if (max <= 0) return;
    final idx = _items.indexWhere((i) => i.variant.id == variant.id);
    if (idx >= 0) {
      _items[idx].quantity += qty;
      if (_items[idx].quantity > max) _items[idx].quantity = max;
    } else {
      _items.add(
        CartItem(product: product, variant: variant, quantity: qty > max ? max : qty),
      );
    }
    notifyListeners();
  }

  void removeItem(String variantId) {
    _items.removeWhere((i) => i.variant.id == variantId);
    notifyListeners();
  }

  void updateQty(String variantId, int qty) {
    final idx = _items.indexWhere((i) => i.variant.id == variantId);
    if (idx >= 0) {
      if (qty <= 0) {
        _items.removeAt(idx);
      } else {
        final max = effectiveMax(_items[idx].variant);
        _items[idx].quantity = qty > max ? max : qty;
      }
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
