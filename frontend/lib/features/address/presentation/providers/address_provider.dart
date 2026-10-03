import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/view_state.dart';
import '../../data/address_api_service.dart';
import '../../data/address_model.dart';

/// Quản lý danh sách địa chỉ giao hàng.
///
/// Ưu tiên API (`/api/v1/addresses`). Nếu API lỗi (chưa đăng nhập, mạng lỗi,
/// backend chưa có dữ liệu) thì fallback về danh sách cũ trong
/// SharedPreferences để trang địa chỉ và trang thanh toán không bị trống.
class AddressProvider extends ChangeNotifier {
  /// Key cache của phiên bản cũ (chưa gắn theo tài khoản) — chỉ đọc để migrate.
  static const _kListKey = 'shippingAddresses';
  static const _kDefaultKey = 'defaultAddressIndex';

  final AddressApiService _apiService;

  AddressProvider({AddressApiService? apiService})
      : _apiService = apiService ?? AddressApiService();

  ViewState<List<ShippingAddress>> _state = ViewState.initial();
  ViewState<List<ShippingAddress>> get state => _state;

  List<ShippingAddress> get items => _state.data ?? const [];

  bool get isLoading => _state.isLoading;

  /// Địa chỉ đang được server đánh dấu mặc định
  ShippingAddress? get defaultAddress {
    final list = items;
    if (list.isEmpty) return null;
    for (final a in list) {
      if (a.isDefault) return a;
    }
    return list.first;
  }

  /// Đang lấy dữ liệu từ API (không phải dữ liệu fallback cục bộ)
  bool get isFromApi => _fromApi;
  bool _fromApi = false;

  /// Tải danh sách địa chỉ
  Future<void> fetchAddresses({bool forceRefresh = false}) async {
    if (!forceRefresh && _state.isSuccess && _fromApi) return;

    if (_state.isInitial) {
      _state = ViewState.loading();
      notifyListeners();
    }

    try {
      final list = await _apiService.getAddresses();
      _fromApi = true;
      _state = ViewState.success(list);
      await _saveLocal(list);
    } catch (_) {
      // Fallback về danh sách cũ trên máy
      final cached = await _loadLocal();
      _fromApi = false;
      if (cached.isNotEmpty) {
        _state = ViewState.success(cached);
      } else if (_state.data == null) {
        _state = ViewState.error(
          'Không thể tải danh sách địa chỉ. Vui lòng kiểm tra kết nối.',
        );
      }
    } finally {
      notifyListeners();
    }
  }

  /// Thêm địa chỉ mới, trả về địa chỉ vừa tạo (null nếu lưu thất bại)
  Future<ShippingAddress?> addAddress(ShippingAddress address) async {
    try {
      final created = await _apiService.createAddress(address);
      _fromApi = true;
      _replaceAll([...items, created]);
      _applyDefault(created.id);
      return created;
    } catch (_) {
      return _addLocal(address);
    }
  }

  /// Cập nhật địa chỉ
  Future<bool> updateAddress(String id, ShippingAddress address) async {
    try {
      final updated = await _apiService.updateAddress(id, address);
      _fromApi = true;
      final list = items
          .map((a) => a.id == id ? updated : a)
          .toList(growable: true);
      _replaceAll(list);
      return true;
    } catch (_) {
      return _updateLocal(id, address);
    }
  }

  /// Đặt địa chỉ làm mặc định
  Future<bool> setDefault(String id) async {
    try {
      final updated = await _apiService.setDefaultAddress(id);
      _fromApi = true;
      _applyDefault(updated.id);
      return true;
    } catch (_) {
      return _setDefaultLocal(id);
    }
  }

  /// Xoá địa chỉ
  Future<bool> deleteAddress(String id) async {
    try {
      await _apiService.deleteAddress(id);
      _fromApi = true;
      final list = items.where((a) => a.id != id).toList();

      // Nếu vừa xoá địa chỉ mặc định thì tự động chọn địa chỉ đầu tiên
      final hadDefault = items.any((a) => a.id == id && a.isDefault);
      _replaceAll(list);
      if (hadDefault && list.isNotEmpty) {
        await setDefault(list.first.id);
      }
      return true;
    } catch (_) {
      return _deleteLocal(id);
    }
  }

  // ------------------------------------------------------------------
  // Optimistic helpers
  // ------------------------------------------------------------------

  void _replaceAll(List<ShippingAddress> list) {
    _state = ViewState.success(list);
    _saveLocal(list);
    notifyListeners();
  }

  /// Đánh dấu đúng một địa chỉ là mặc định
  void _applyDefault(String? id) {
    if (id == null) return;
    _replaceAll(
      items.map((a) => a.copyWith(isDefault: a.id == id)).toList(growable: true),
    );
  }

  // ------------------------------------------------------------------
  // Fallback cục bộ (SharedPreferences)
  // ------------------------------------------------------------------

  /// Gán cache cục bộ theo tài khoản để không lộ địa chỉ của người dùng trước
  /// khi đăng nhập lại tài khoản khác trên cùng máy.
  String _scoped(String base, String ownerId) =>
      ownerId.isEmpty ? base : '$base::$ownerId';

  Future<String> _currentOwnerId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_id') ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<void> _saveLocal(List<ShippingAddress> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final owner = await _currentOwnerId();
      await prefs.setString(
        _scoped(_kListKey, owner),
        jsonEncode(list.map((a) => a.toJson()).toList()),
      );
      final defIdx = list.indexWhere((a) => a.isDefault);
      await prefs.setInt(_scoped(_kDefaultKey, owner), defIdx >= 0 ? defIdx : 0);
    } catch (_) {}
  }

  /// Đọc danh sách cũ. Tự động chuyển đổi mảng {name, phone, address} cũ
  /// sang định dạng đầy đủ để không mất dữ liệu người dùng đã nhập.
  Future<List<ShippingAddress>> _loadLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final owner = await _currentOwnerId();
      final scopedListKey = _scoped(_kListKey, owner);
      final scopedDefaultKey = _scoped(_kDefaultKey, owner);

      // Ưu tiên cache của tài khoản hiện tại; nếu chưa có thì đọc cache cũ
      // (chưa gắn theo tài khoản) để migrate, tránh mất dữ liệu đã nhập.
      final scopedRaw = prefs.getString(scopedListKey);
      final legacyRaw = scopedRaw == null ? prefs.getString(_kListKey) : null;
      final raw = scopedRaw ?? legacyRaw;
      if (raw == null || raw.isEmpty) return const [];

      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      final defIdx = prefs.getInt(scopedDefaultKey) ??
          prefs.getInt(_kDefaultKey) ??
          0;
      final list = <ShippingAddress>[];
      for (var i = 0; i < decoded.length; i++) {
        if (decoded[i] is! Map) continue;
        final map = Map<String, dynamic>.from(decoded[i] as Map);
        final isLegacy = !map.containsKey('detailAddress') &&
            !map.containsKey('detail_address');
        final address = isLegacy
            ? ShippingAddress.fromLegacy(map)
            : ShippingAddress.fromJson(map);
        list.add(
          address.copyWith(
            id: address.id.isEmpty ? 'local-$i' : address.id,
            isDefault: i == defIdx,
          ),
        );
      }

      // Đã migrate sang key theo tài khoản: lưu lại rồi xoá key cũ.
      // Chỉ xoá khi key theo tài khoản khác key cũ (tức đã đăng nhập).
      if (legacyRaw != null && scopedListKey != _kListKey) {
        await _saveLocal(list);
        await prefs.remove(_kListKey);
        await prefs.remove(_kDefaultKey);
      }
      return list;
    } catch (_) {
      return const [];
    }
  }

  Future<ShippingAddress?> _addLocal(ShippingAddress address) async {
    final list = [...items];
    final isFirst = list.isEmpty;
    final local = address.copyWith(
      id: address.id.isEmpty ? 'local-${DateTime.now()}' : address.id,
      isDefault: address.isDefault || isFirst,
    );
    if (local.isDefault) {
      for (var i = 0; i < list.length; i++) {
        list[i] = list[i].copyWith(isDefault: false);
      }
    }
    list.insert(0, local);
    _replaceAll(list);
    return local;
  }

  Future<bool> _updateLocal(String id, ShippingAddress address) async {
    final idx = items.indexWhere((a) => a.id == id);
    if (idx == -1) return false;
    final list = [...items];
    list[idx] = address.copyWith(id: id, isDefault: list[idx].isDefault);
    _replaceAll(list);
    return true;
  }

  Future<bool> _setDefaultLocal(String id) async {
    if (!items.any((a) => a.id == id)) return false;
    _applyDefault(id);
    return true;
  }

  Future<bool> _deleteLocal(String id) async {
    final list = items.where((a) => a.id != id).toList();
    final target = items.where((a) => a.id == id).toList();
    if (target.isEmpty) return false;
    _replaceAll(list);
    if (target.first.isDefault && list.isNotEmpty) {
      _applyDefault(list.first.id);
    }
    return true;
  }

  /// Xoá sạch cache khi đăng xuất
  void resetLocal() {
    _state = ViewState.initial();
    _fromApi = false;
    notifyListeners();
    _purgeCache();
  }

  /// Xoá sạch cache địa chỉ của mọi tài khoản (gọi khi đăng xuất) để người
  /// dùng tiếp theo không thấy địa chỉ của người trước khi API lỗi.
  Future<void> _purgeCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where(
            (k) =>
                k == _kListKey ||
                k == _kDefaultKey ||
                k.startsWith('$_kListKey::') ||
                k.startsWith('$_kDefaultKey::'),
          );
      for (final k in keys.toList()) {
        await prefs.remove(k);
      }
    } catch (_) {}
  }
}
