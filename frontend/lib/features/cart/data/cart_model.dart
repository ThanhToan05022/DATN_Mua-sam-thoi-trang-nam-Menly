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
  final List<CartItem> _items = [];
  List<CartItem> get items => List.unmodifiable(_items);
  int get totalItems => _items.fold(0, (s, i) => s + i.quantity);
  int get totalPrice => _items.fold(0, (s, i) => s + i.subtotal);

  void addItem(Product product, ProductVariant variant, int qty) {
    final idx = _items.indexWhere((i) => i.variant.id == variant.id);
    if (idx >= 0) {
      _items[idx].quantity += qty;
    } else {
      _items.add(CartItem(product: product, variant: variant, quantity: qty));
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
        _items[idx].quantity = qty;
      }
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
