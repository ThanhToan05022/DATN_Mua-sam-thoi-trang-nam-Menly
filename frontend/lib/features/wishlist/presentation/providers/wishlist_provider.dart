import 'package:flutter/foundation.dart';
import '../../../../core/network/view_state.dart';
import '../../../product/data/models/product_model.dart';
import '../../data/wishlist_api_service.dart';

class WishlistProvider extends ChangeNotifier {
  final WishlistApiService _apiService;

  WishlistProvider({WishlistApiService? apiService})
      : _apiService = apiService ?? WishlistApiService();

  ViewState<List<Product>> _state = ViewState.initial();
  ViewState<List<Product>> get state => _state;

  List<Product> get items => _state.data ?? [];
  int get count => items.length;
  int get favoriteCount => _favoriteIds.length;

  // Set các productId đã yêu thích để tra cứu O(1)
  final Set<String> _favoriteIds = {};

  bool isFavorite(String productId) => _favoriteIds.contains(productId);

  /// Tải danh sách yêu thích từ máy chủ
  Future<void> fetchWishlist({bool forceRefresh = false}) async {
    if (!forceRefresh && _state.isSuccess) {
      return;
    }

    _state = ViewState.loading(_state.data);
    notifyListeners();

    try {
      final list = await _apiService.getWishlist();
      _favoriteIds.clear();
      for (final p in list) {
        _favoriteIds.add(p.id);
      }
      _state = ViewState.success(list);
    } catch (e) {
      _state = ViewState.error(e.toString(), _state.data);
    } finally {
      notifyListeners();
    }
  }

  /// Bật/Tắt yêu thích một sản phẩm (Optimistic Update)
  Future<bool> toggleWishlist(Product product) async {
    final isFav = isFavorite(product.id);
    final previousItems = List<Product>.from(items);

    if (isFav) {
      // Đang thích -> Bỏ thích
      _favoriteIds.remove(product.id);
      final updatedList = items.where((p) => p.id != product.id).toList();
      _state = ViewState.success(updatedList);
      notifyListeners();

      try {
        await _apiService.removeFromWishlist(product.id);
        return false;
      } catch (e) {
        // Rollback nếu API lỗi
        _favoriteIds.add(product.id);
        _state = ViewState.success(previousItems);
        notifyListeners();
        rethrow;
      }
    } else {
      // Chưa thích -> Thêm vào yêu thích
      _favoriteIds.add(product.id);
      final updatedList = [product, ...items];
      _state = ViewState.success(updatedList);
      notifyListeners();

      try {
        await _apiService.addToWishlist(product.id);
        return true;
      } catch (e) {
        // Rollback nếu API lỗi
        _favoriteIds.remove(product.id);
        _state = ViewState.success(previousItems);
        notifyListeners();
        rethrow;
      }
    }
  }

  /// Xóa một sản phẩm khỏi danh sách yêu thích
  Future<void> removeFromWishlist(String productId) async {
    if (!_favoriteIds.contains(productId)) return;

    final previousItems = List<Product>.from(items);
    _favoriteIds.remove(productId);
    final updatedList = items.where((p) => p.id != productId).toList();
    _state = ViewState.success(updatedList);
    notifyListeners();

    try {
      await _apiService.removeFromWishlist(productId);
    } catch (e) {
      // Rollback
      _favoriteIds.add(productId);
      _state = ViewState.success(previousItems);
      notifyListeners();
      rethrow;
    }
  }
}
