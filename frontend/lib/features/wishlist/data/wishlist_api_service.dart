import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../product/data/models/product_model.dart';

class WishlistApiService {
  final Dio _dio;

  WishlistApiService({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  /// Lấy danh sách sản phẩm yêu thích của người dùng hiện tại
  Future<List<Product>> getWishlist() async {
    try {
      final response = await _dio.get('/wishlist');
      final data = response.data;
      final List list = data is List ? data : (data['data'] ?? data['items'] ?? []);
      return list.map((e) => Product.fromJson(e)).toList();
    } on DioException catch (e) {
      throw e.message ?? 'Không thể tải danh sách yêu thích';
    } catch (e) {
      throw 'Lỗi không xác định: $e';
    }
  }

  /// Thêm một sản phẩm vào danh sách yêu thích
  Future<bool> addToWishlist(String productId) async {
    try {
      final response = await _dio.post('/wishlist/$productId');
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      throw e.message ?? 'Không thể thêm vào yêu thích';
    } catch (e) {
      throw 'Lỗi không xác định: $e';
    }
  }

  /// Xóa một sản phẩm khỏi danh sách yêu thích
  Future<bool> removeFromWishlist(String productId) async {
    try {
      final response = await _dio.delete('/wishlist/$productId');
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw e.message ?? 'Không thể xóa khỏi yêu thích';
    } catch (e) {
      throw 'Lỗi không xác định: $e';
    }
  }

  /// Kiểm tra xem sản phẩm đã có trong danh sách yêu thích chưa
  Future<bool> checkIsFavorite(String productId) async {
    try {
      final response = await _dio.get('/wishlist/check/$productId');
      return response.data?['isFavorite'] == true;
    } catch (_) {
      return false;
    }
  }
}
