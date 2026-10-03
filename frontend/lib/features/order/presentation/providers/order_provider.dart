import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/view_state.dart';
import '../../data/order_model.dart';

class OrderProvider extends ChangeNotifier {
  final DioClient _dioClient;

  OrderProvider({DioClient? dioClient})
      : _dioClient = dioClient ?? DioClient.instance;

  ViewState<List<Order>> _myOrdersState = ViewState.initial();
  ViewState<List<Order>> get myOrdersState => _myOrdersState;

  ViewState<List<Order>> _adminOrdersState = ViewState.initial();
  ViewState<List<Order>> get adminOrdersState => _adminOrdersState;

  bool _isUpdating = false;
  bool get isUpdating => _isUpdating;

  Future<String> _getCacheKey() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    if (email != null && email.isNotEmpty) {
      return 'user_orders_cache_${email.toLowerCase().trim()}';
    }
    final uid = prefs.getString('user_id');
    if (uid != null && uid.isNotEmpty) {
      return 'user_orders_cache_$uid';
    }
    return 'user_orders_cache_default';
  }

  Future<void> _saveToLocal(List<Order> orders) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = await _getCacheKey();
      final jsonList = orders.map((o) => o.toJson()).toList();
      final str = jsonEncode(jsonList);
      await prefs.setString(key, str);
      await prefs.setString('user_orders_cache_latest', str);
    } catch (_) {}
  }

  Future<List<Order>> _loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = await _getCacheKey();
      String? str = prefs.getString(key);
      if (str == null || str.isEmpty) {
        str = prefs.getString('user_orders_cache_latest');
      }
      if (str != null && str.isNotEmpty) {
        final decoded = jsonDecode(str);
        if (decoded is List) {
          return decoded.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  /// Thêm đơn hàng vừa đặt thành công vào danh sách và lưu ngay vào bộ nhớ máy
  Future<void> addPlacedOrder(Order order) async {
    final currentList = _myOrdersState.data != null
        ? List<Order>.from(_myOrdersState.data!)
        : await _loadFromLocal();

    final exists = currentList.any((o) => o.id == order.id || (o.code.isNotEmpty && o.code == order.code));
    if (!exists) {
      currentList.insert(0, order);
    }

    _myOrdersState = ViewState.success(currentList);
    await _saveToLocal(currentList);
    notifyListeners();
  }

  /// Lấy chi tiết một đơn hàng (kèm timeline trạng thái).
  ///
  /// Ưu tiên gọi API; nếu lỗi thì lấy bản đã có trong danh sách/cache để
  /// người dùng vẫn xem được đơn cũ khi mất mạng.
  Future<Order?> getOrderDetail(String orderId) async {
    if (orderId.isEmpty) return null;

    try {
      final res = await _dioClient.dio.get('/orders/$orderId');
      final data = res.data;
      final map = data is Map && data['data'] is Map
          ? data['data'] as Map<String, dynamic>
          : (data as Map<String, dynamic>);
      final order = Order.fromJson(map);

      // Đồng bộ vào danh sách để các màn khác không bị cũ
      if (order.id.isNotEmpty) {
        final list = _myOrdersState.data != null
            ? List<Order>.from(_myOrdersState.data!)
            : await _loadFromLocal();
        final idx = list.indexWhere((o) => o.id == order.id || o.code == order.code);
        if (idx != -1) {
          list[idx] = order;
        } else {
          list.insert(0, order);
        }
        _myOrdersState = ViewState.success(list);
        await _saveToLocal(list);
        notifyListeners();
      }
      return order;
    } catch (_) {
      final list = _myOrdersState.data ?? await _loadFromLocal();
      for (final o in list) {
        if (o.id == orderId || o.code == orderId) return o;
      }
      return null;
    }
  }

  /// Lấy danh sách đơn hàng của người dùng hiện tại
  Future<void> fetchMyOrders({bool forceRefresh = false}) async {
    // 1. Tải trước từ cache cục bộ để hiển thị ngay lập tức (không bị trống khi vừa đăng nhập lại)
    final cached = await _loadFromLocal();
    if (cached.isNotEmpty) {
      _myOrdersState = ViewState.success(cached);
      notifyListeners();
    } else if (_myOrdersState.isInitial || forceRefresh) {
      _myOrdersState = ViewState.loading();
      notifyListeners();
    }

    try {
      final res = await _dioClient.dio.get('/orders', queryParameters: {'limit': 50});
      final data = res.data;
      final rawList = data is Map && data['items'] != null
          ? (data['items'] as List<dynamic>)
          : (data is List ? data : []);

      final apiOrders = rawList
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList();

      final existingLocal = await _loadFromLocal();
      final combined = [...apiOrders, ...existingLocal];
      final uniqueMap = <String, Order>{};
      for (final o in combined) {
        final key = o.id.isNotEmpty ? o.id : o.code;
        if (key.isEmpty) continue;

        // Tránh trùng lặp giữa id và code
        final codeDuplicate = o.code.isNotEmpty &&
            uniqueMap.values.any((item) => item.code == o.code && item.id != o.id);
        if (codeDuplicate) continue;

        if (!uniqueMap.containsKey(key)) {
          uniqueMap[key] = o;
        }
      }
      final merged = uniqueMap.values.toList();
      merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _myOrdersState = ViewState.success(merged);
      await _saveToLocal(merged);
    } catch (e) {
      if (cached.isEmpty) {
        _myOrdersState = ViewState.error(e.toString());
      }
    } finally {
      notifyListeners();
    }
  }

  /// Khách hàng huỷ đơn hàng
  Future<bool> cancelOrder(String orderId, {String? reason}) async {
    _isUpdating = true;
    notifyListeners();

    try {
      await _dioClient.dio.put(
        '/orders/$orderId/cancel',
        data: {
          if (reason != null && reason.trim().isNotEmpty) 'note': reason.trim(),
        },
      );

      // Cập nhật myOrdersState
      if (_myOrdersState.isSuccess && _myOrdersState.data != null) {
        final list = List<Order>.from(_myOrdersState.data!);
        final idx = list.indexWhere((o) => o.id == orderId || o.code == orderId);
        if (idx != -1) {
          final old = list[idx];
          list[idx] = old.copyWith(
            status: 'cancelled',
            note: (reason != null && reason.trim().isNotEmpty) ? reason.trim() : (old.note ?? 'Huỷ bởi khách hàng'),
          );
          _myOrdersState = ViewState.success(list);
          await _saveToLocal(list);
        }
      }

      // Cập nhật cả adminOrdersState nếu đang mở
      if (_adminOrdersState.isSuccess && _adminOrdersState.data != null) {
        final list = List<Order>.from(_adminOrdersState.data!);
        final idx = list.indexWhere((o) => o.id == orderId || o.code == orderId);
        if (idx != -1) {
          final old = list[idx];
          list[idx] = old.copyWith(
            status: 'cancelled',
            note: (reason != null && reason.trim().isNotEmpty) ? reason.trim() : (old.note ?? 'Huỷ bởi khách hàng'),
          );
          _adminOrdersState = ViewState.success(list);
        }
      }

      return true;
    } catch (_) {
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  /// Quản trị viên / Nhân viên lấy danh sách toàn bộ đơn hàng
  Future<void> fetchAdminOrders({String? status, bool forceRefresh = false}) async {
    if (!forceRefresh && _adminOrdersState.isSuccess && _adminOrdersState.data != null) {
      return;
    }

    _adminOrdersState = ViewState.loading();
    notifyListeners();

    try {
      final q = <String, dynamic>{'limit': 50};
      if (status != null && status != 'all') {
        q['status'] = status;
      }

      final res = await _dioClient.dio.get('/admin/orders', queryParameters: q);
      final data = res.data;
      final rawList = data is Map && data['items'] != null
          ? (data['items'] as List<dynamic>)
          : (data is List ? data : []);

      final orders = rawList
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList();

      _adminOrdersState = ViewState.success(orders);
    } catch (e) {
      _adminOrdersState = ViewState.error(e.toString());
    } finally {
      notifyListeners();
    }
  }

  /// Cập nhật trạng thái đơn hàng (Dành cho Admin & Nhân viên)
  Future<bool> updateOrderStatus(
    String orderId,
    String newStatus, {
    String? note,
  }) async {
    _isUpdating = true;
    notifyListeners();

    try {
      await _dioClient.dio.put(
        '/admin/orders/$orderId/status',
        data: {
          'status': newStatus,
          'note': note ?? 'Cập nhật trạng thái bởi quản trị viên',
        },
      );

      // Cập nhật local state trong adminOrdersState
      if (_adminOrdersState.isSuccess && _adminOrdersState.data != null) {
        final list = List<Order>.from(_adminOrdersState.data!);
        final idx = list.indexWhere((o) => o.id == orderId);
        if (idx != -1) {
          final old = list[idx];
          list[idx] = old.copyWith(status: newStatus, note: note ?? old.note);
          _adminOrdersState = ViewState.success(list);
        }
      }

      // Cập nhật cả myOrdersState nếu có
      if (_myOrdersState.isSuccess && _myOrdersState.data != null) {
        final list = List<Order>.from(_myOrdersState.data!);
        final idx = list.indexWhere((o) => o.id == orderId);
        if (idx != -1) {
          final old = list[idx];
          list[idx] = old.copyWith(status: newStatus, note: note ?? old.note);
          _myOrdersState = ViewState.success(list);
          await _saveToLocal(list);
        }
      }

      return true;
    } catch (_) {
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }
}
