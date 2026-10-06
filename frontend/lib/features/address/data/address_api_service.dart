import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import 'address_model.dart';

/// Lớp giao tiếp với API địa chỉ giao hàng.
///
/// Backend: GET/POST /api/v1/addresses, PUT/DELETE /api/v1/addresses/:id,
/// PUT /api/v1/addresses/:id/default (kèm alias /api/v1/users/addresses).
class AddressApiService {
  final Dio _dio;

  AddressApiService({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  /// API có thể trả về `{ data: [...] }`, `{ items: [...] }` hoặc mảng thuần
  List<dynamic> _extractList(dynamic body) {
    if (body is List) return body;
    if (body is Map) {
      if (body['data'] is List) return body['data'] as List<dynamic>;
      if (body['items'] is List) return body['items'] as List<dynamic>;
    }
    return const [];
  }

  Map<String, dynamic> _extractData(dynamic body) {
    if (body is Map) {
      final data = body['data'];
      if (data is Map) return data as Map<String, dynamic>;
      if (data != null) return {'data': data};
      return body as Map<String, dynamic>;
    }
    return <String, dynamic>{};
  }

  /// Lấy danh sách địa chỉ giao hàng (địa chỉ mặc định đứng đầu)
  Future<List<ShippingAddress>> getAddresses() async {
    try {
      final response = await _dio.get('/addresses');
      return _extractList(response.data)
          .map((e) => ShippingAddress.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw e.message ?? 'Không thể tải danh sách địa chỉ';
    } catch (e) {
      throw 'Lỗi không xác định: $e';
    }
  }

  /// Thêm địa chỉ mới
  Future<ShippingAddress> createAddress(ShippingAddress address) async {
    try {
      final response = await _dio.post('/addresses', data: {
        'recipientName': address.recipientName,
        'phone': address.phone,
        'province': address.province,
        'district': address.district,
        'ward': address.ward,
        'detailAddress': address.detailAddress,
        'isDefault': address.isDefault,
      });
      return ShippingAddress.fromJson(_extractData(response.data));
    } on DioException catch (e) {
      throw e.message ?? 'Không thể thêm địa chỉ';
    } catch (e) {
      throw 'Lỗi không xác định: $e';
    }
  }

  /// Cập nhật địa chỉ (không truyền isDefault)
  Future<ShippingAddress> updateAddress(
    String id,
    ShippingAddress address, {
    bool? isDefault,
  }) async {
    try {
      final response = await _dio.put('/addresses/$id', data: {
        'recipientName': address.recipientName,
        'phone': address.phone,
        'province': address.province,
        'district': address.district,
        'ward': address.ward,
        'detailAddress': address.detailAddress,
        'isDefault': ?isDefault,
      });
      return ShippingAddress.fromJson(_extractData(response.data));
    } on DioException catch (e) {
      throw e.message ?? 'Không thể cập nhật địa chỉ';
    } catch (e) {
      throw 'Lỗi không xác định: $e';
    }
  }

  /// Đặt địa chỉ làm mặc định
  Future<ShippingAddress> setDefaultAddress(String id) async {
    try {
      final response = await _dio.put('/addresses/$id/default');
      return ShippingAddress.fromJson(_extractData(response.data));
    } on DioException catch (e) {
      throw e.message ?? 'Không thể đặt địa chỉ mặc định';
    } catch (e) {
      throw 'Lỗi không xác định: $e';
    }
  }

  /// Xoá địa chỉ
  Future<void> deleteAddress(String id) async {
    try {
      await _dio.delete('/addresses/$id');
    } on DioException catch (e) {
      throw e.message ?? 'Không thể xoá địa chỉ';
    } catch (e) {
      throw 'Lỗi không xác định: $e';
    }
  }
}
