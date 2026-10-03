/// Mô hình địa chỉ giao hàng đã lưu trên tài khoản khách hàng.
///
/// Khớp với bảng `user_addresses` ở backend:
/// recipient_name / phone / province / district / ward / detail_address / is_default
class ShippingAddress {
  final String id;
  final String recipientName;
  final String phone;
  final String province;
  final String district;
  final String ward;
  final String detailAddress;
  final bool isDefault;
  final String createdAt;

  ShippingAddress({
    required this.id,
    required this.recipientName,
    required this.phone,
    required this.province,
    required this.district,
    required this.ward,
    required this.detailAddress,
    this.isDefault = false,
    this.createdAt = '',
  });

  /// Địa chỉ gộp 1 dòng để hiển thị và gửi kèm đơn hàng
  String get fullAddress {
    final parts = <String>[
      detailAddress,
      ward,
      district,
      province,
    ].where((p) => p.trim().isNotEmpty).toList();
    return parts.join(', ');
  }

  /// Tên + số điện thoại người nhận
  String get receiverLabel =>
      '$recipientName${phone.isNotEmpty ? ' · $phone' : ''}';

  ShippingAddress copyWith({
    String? id,
    String? recipientName,
    String? phone,
    String? province,
    String? district,
    String? ward,
    String? detailAddress,
    bool? isDefault,
    String? createdAt,
  }) {
    return ShippingAddress(
      id: id ?? this.id,
      recipientName: recipientName ?? this.recipientName,
      phone: phone ?? this.phone,
      province: province ?? this.province,
      district: district ?? this.district,
      ward: ward ?? this.ward,
      detailAddress: detailAddress ?? this.detailAddress,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ShippingAddress.fromJson(Map<String, dynamic> j) => ShippingAddress(
        id: j['id']?.toString() ?? '',
        recipientName: j['recipientName']?.toString() ??
            j['recipient_name']?.toString() ??
            j['name']?.toString() ??
            '',
        phone: j['phone']?.toString() ?? '',
        province: j['province']?.toString() ?? '',
        district: j['district']?.toString() ?? '',
        ward: j['ward']?.toString() ?? '',
        detailAddress: j['detailAddress']?.toString() ??
            j['detail_address']?.toString() ??
            j['address']?.toString() ??
            '',
        isDefault: j['isDefault'] == true || j['is_default'] == true,
        createdAt: j['createdAt']?.toString() ?? j['created_at']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'recipientName': recipientName,
        'phone': phone,
        'province': province,
        'district': district,
        'ward': ward,
        'detailAddress': detailAddress,
        'isDefault': isDefault,
        'createdAt': createdAt,
      };

  /// Chuyển từ địa chỉ cũ đã lưu trong SharedPreferences (name/phone/address).
  ///
  /// Địa chỉ cũ chỉ có 3 trường nên toàn bộ địa chỉ chi tiết dồn vào
  /// `detailAddress` để không mất dữ liệu người dùng đã nhập.
  factory ShippingAddress.fromLegacy(Map<String, dynamic> j) {
    final address = (j['address'] ?? j['detailAddress'] ?? '').toString();
    return ShippingAddress(
      id: j['id']?.toString() ?? '',
      recipientName: (j['name'] ?? j['recipientName'] ?? '').toString(),
      phone: (j['phone'] ?? '').toString(),
      province: (j['province'] ?? '').toString(),
      district: (j['district'] ?? '').toString(),
      ward: (j['ward'] ?? '').toString(),
      detailAddress: address,
    );
  }
}

/// Danh sách tỉnh/thành, quận/huyện, phường/xã dùng để chọn nhanh khi thêm địa chỉ.
class VietnamRegions {
  const VietnamRegions._();

  static const List<String> provinces = [
    'Hà Nội',
    'Hồ Chí Minh',
    'Hải Phòng',
    'Đà Nẵng',
    'Cần Thơ',
    'Biên Hoà',
    'Nha Trang',
    'Huế',
    'Quy Nhơn',
    'Buôn Ma Thuột',
    'Vũng Tàu',
    'Hạ Long',
    'Nam Định',
    'Thái Nguyên',
    'Vinh',
    'Bắc Ninh',
  ];

  static const List<String> districts = [
    'Quận trung tâm',
    'Quận 1',
    'Quận 3',
    'Quận Hoàn Kiếm',
    'Quận Ba Đình',
    'Quận Đống Đa',
    'Quận Cầu Giấy',
    'Quận Hà Đông',
    'Quận Bình Thạnh',
    'Quận Gò Vấp',
    'Quận Thanh Xuân',
    'Huyện Thanh Trì',
    'Huyện Hoàng Mai',
    'Huyện Long Biên',
    'Huyện Củ Chi',
    'Huyện Gò Vấp',
  ];

  static const List<String> wards = [
    'Phường 1',
    'Phường 2',
    'Phường 3',
    'Phường 4',
    'Phường 5',
    'Phường 6',
    'Phường 7',
    'Phường 8',
    'Phường 9',
    'Phường 10',
    'Phường 11',
    'Phường 12',
    'Phường 13',
    'Phường 14',
    'Phường 15',
  ];
}
