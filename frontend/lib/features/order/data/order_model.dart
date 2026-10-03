import 'package:flutter/material.dart';

int _toInt(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? fallback;
}

const Map<String, String> _kStatusLabels = {
  'pending_payment': 'Đã đặt hàng',
  'paid': 'Đã thanh toán',
  'processing': 'Đã xác nhận',
  'shipping': 'Đang giao hàng',
  'completed': 'Hoàn tất',
  'delivered': 'Hoàn tất',
  'cancelled': 'Đã huỷ',
};

const Map<String, String> _kStatusDescriptions = {
  'pending_payment': 'Đơn hàng đã được ghi nhận, đang chờ thanh toán',
  'paid': 'Thanh toán thành công, cửa hàng sẽ xử lý',
  'processing': 'Cửa hàng đã xác nhận và đang chuẩn bị hàng',
  'shipping': 'Đơn hàng đang trên đường giao đến bạn',
  'completed': 'Đơn hàng đã giao thành công. Cảm ơn bạn!',
  'delivered': 'Đơn hàng đã giao thành công. Cảm ơn bạn!',
  'cancelled': 'Đơn hàng đã bị huỷ',
};

const List<String> _kHappyPath = [
  'pending_payment',
  'processing',
  'shipping',
  'completed',
];

/// Dựng timeline ngay trên máy khi backend không trả về `timeline`.
///
/// Ưu tiên mốc thời gian thật trong [history]; phần còn thiếu dựng theo
/// quy tắc vòng đời chuẩn nên timeline vẫn hiển thị đầy đủ.
List<OrderTimelineStep> buildOrderTimeline(
  String status,
  String createdAt,
  List<OrderStatusHistoryEntry> history,
) {
  final byStatus = <String, OrderStatusHistoryEntry>{};
  for (final entry in history) {
    if (entry.status.isNotEmpty && !byStatus.containsKey(entry.status)) {
      byStatus[entry.status] = entry;
    }
  }

  String? at(String key) => byStatus[key]?.createdAt;

  if (status == 'cancelled') {
    return [
      OrderTimelineStep(
        status: 'pending_payment',
        label: _kStatusLabels['pending_payment']!,
        description: _kStatusDescriptions['pending_payment']!,
        createdAt: at('pending_payment') ?? createdAt,
        note: byStatus['pending_payment']?.note,
        completed: true,
      ),
      OrderTimelineStep(
        status: 'cancelled',
        label: _kStatusLabels['cancelled']!,
        description: _kStatusDescriptions['cancelled']!,
        createdAt: at('cancelled') ?? createdAt,
        note: byStatus['cancelled']?.note,
        completed: true,
        current: true,
      ),
    ];
  }

  final normalized = status == 'delivered' ? 'completed' : status;

  // Luôn hiện đủ vòng đời (giống backend): 'paid' chèn một lần ngay sau
  // 'pending_payment' khi đơn đã qua bước thanh toán, các bước chưa tới để
  // completed = false.
  final paidReached = normalized == 'paid' || byStatus.containsKey('paid');
  final flow = <String>[
    'pending_payment',
    if (paidReached) 'paid',
    ..._kHappyPath.sublist(1),
  ];

  final currentIndex = (flow.contains(normalized) ? flow.indexOf(normalized) : 0);

  return [
    for (var i = 0; i < flow.length; i++)
      OrderTimelineStep(
        status: flow[i],
        label: _kStatusLabels[flow[i]] ?? flow[i],
        description: _kStatusDescriptions[flow[i]] ?? '',
        createdAt: byStatus[flow[i]]?.createdAt ?? (i == 0 ? createdAt : null),
        note: byStatus[flow[i]]?.note,
        completed: i <= currentIndex,
        current: i == currentIndex,
      ),
  ];
}

class OrderItem {
  final String id;
  final String variantId;
  final String productName;
  final String size;
  final String color;
  final int unitPrice;
  final int quantity;
  final String? thumbnailUrl;

  OrderItem({
    required this.id,
    required this.variantId,
    required this.productName,
    required this.size,
    required this.color,
    required this.unitPrice,
    required this.quantity,
    this.thumbnailUrl,
  });

  int get subtotal => unitPrice * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
        id: j['id']?.toString() ?? '',
        variantId: j['variantId']?.toString() ?? j['variant_id']?.toString() ?? '',
        productName: j['productName'] ?? j['product_name'] ?? j['name'] ?? 'Sản phẩm',
        size: j['size']?.toString() ?? '',
        color: j['color']?.toString() ?? '',
        unitPrice: _toInt(j['unitPrice'] ?? j['unit_price'] ?? j['price']),
        quantity: _toInt(j['quantity'], 1),
        thumbnailUrl:
            j['thumbnailUrl']?.toString() ?? j['thumbnail_url']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'variantId': variantId,
        'productName': productName,
        'size': size,
        'color': color,
        'unitPrice': unitPrice,
        'quantity': quantity,
        'thumbnailUrl': thumbnailUrl,
      };
}

/// Một mốc lịch sử trạng thái đơn hàng (nguồn: bảng order_status_history)
class OrderStatusHistoryEntry {
  final String status;
  final String? note;
  final String createdAt;

  const OrderStatusHistoryEntry({
    required this.status,
    this.note,
    required this.createdAt,
  });

  factory OrderStatusHistoryEntry.fromJson(Map<String, dynamic> j) =>
      OrderStatusHistoryEntry(
        status: j['status']?.toString() ??
            j['to_status']?.toString() ??
            j['toStatus']?.toString() ??
            '',
        note: j['note']?.toString(),
        createdAt: j['createdAt']?.toString() ??
            j['created_at']?.toString() ??
            '',
      );

  Map<String, dynamic> toJson() => {
        'status': status,
        'note': note,
        'createdAt': createdAt,
      };
}

/// Một bước trên timeline trạng thái đơn hàng
class OrderTimelineStep {
  final String status;
  final String label;
  final String description;
  final String? createdAt;
  final String? note;
  final bool completed;
  final bool current;

  const OrderTimelineStep({
    required this.status,
    required this.label,
    required this.description,
    this.createdAt,
    this.note,
    this.completed = false,
    this.current = false,
  });

  factory OrderTimelineStep.fromJson(Map<String, dynamic> j) =>
      OrderTimelineStep(
        status: j['status']?.toString() ?? '',
        label: j['label']?.toString() ?? '',
        description: j['description']?.toString() ?? '',
        createdAt: j['createdAt']?.toString() ?? j['created_at']?.toString(),
        note: j['note']?.toString(),
        completed: j['completed'] == true,
        current: j['current'] == true,
      );

  Map<String, dynamic> toJson() => {
        'status': status,
        'label': label,
        'description': description,
        'createdAt': createdAt,
        'note': note,
        'completed': completed,
        'current': current,
      };
}

class Order {
  final String id;
  final String code;
  final String userId;
  final String status;
  final String paymentMethod;
  final int subtotal;
  final int shippingFee;
  final String? voucherCode;
  final int discountAmount;
  final int total;
  final String shipName;
  final String shipPhone;
  final String shipAddress;
  final String? note;
  final String createdAt;
  final List<OrderItem> items;
  final List<OrderStatusHistoryEntry> statusHistory;
  final List<OrderTimelineStep> timeline;

  Order({
    required this.id,
    required this.code,
    required this.userId,
    required this.status,
    required this.paymentMethod,
    required this.subtotal,
    required this.shippingFee,
    this.voucherCode,
    this.discountAmount = 0,
    required this.total,
    required this.shipName,
    required this.shipPhone,
    required this.shipAddress,
    this.note,
    required this.createdAt,
    this.items = const [],
    this.statusHistory = const [],
    List<OrderTimelineStep>? timeline,
  }) : timeline = timeline ?? buildOrderTimeline(status, createdAt, statusHistory);

  factory Order.fromJson(Map<String, dynamic> j) {
    final rawItems = (j['items'] as List<dynamic>?) ??
        (j['order_items'] as List<dynamic>?) ??
        [];
    final rawHistory = (j['statusHistory'] as List<dynamic>?) ??
        (j['status_history'] as List<dynamic>?) ??
        [];
    final rawTimeline = (j['timeline'] as List<dynamic>?) ?? [];
    final status = j['status']?.toString() ?? 'pending_payment';
    final createdAt = j['createdAt']?.toString() ??
        j['created_at']?.toString() ??
        DateTime.now().toIso8601String();
    final history = rawHistory
        .where((e) => e is Map)
        .map((e) => OrderStatusHistoryEntry.fromJson(e as Map<String, dynamic>))
        .where((e) => e.status.isNotEmpty)
        .toList();

    return Order(
      id: j['id']?.toString() ?? '',
      code: j['code']?.toString() ?? 'ORD',
      userId: j['userId']?.toString() ?? j['user_id']?.toString() ?? '',
      status: status,
      paymentMethod:
          j['paymentMethod']?.toString() ?? j['payment_method']?.toString() ?? 'cod',
      subtotal: _toInt(j['subtotal']),
      shippingFee: _toInt(j['shippingFee'] ?? j['shipping_fee']),
      voucherCode: j['voucherCode']?.toString() ?? j['voucher_code']?.toString(),
      discountAmount: _toInt(j['discountAmount'] ?? j['discount_amount']),
      total: _toInt(j['total']),
      shipName: j['shipName']?.toString() ??
          j['ship_name']?.toString() ??
          (j['ship'] is Map ? j['ship']['name']?.toString() : null) ??
          '',
      shipPhone: j['shipPhone']?.toString() ??
          j['ship_phone']?.toString() ??
          (j['ship'] is Map ? j['ship']['phone']?.toString() : null) ??
          '',
      shipAddress: j['shipAddress']?.toString() ??
          j['ship_address']?.toString() ??
          (j['ship'] is Map ? j['ship']['address']?.toString() : null) ??
          '',
      note: j['note']?.toString(),
      createdAt: createdAt,
      items: rawItems
          .where((e) => e is Map)
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      statusHistory: history,
      timeline: rawTimeline.isNotEmpty
          ? rawTimeline
              .where((e) => e is Map)
              .map((e) => OrderTimelineStep.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'userId': userId,
        'status': status,
        'paymentMethod': paymentMethod,
        'subtotal': subtotal,
        'shippingFee': shippingFee,
        'voucherCode': voucherCode,
        'discountAmount': discountAmount,
        'total': total,
        'shipName': shipName,
        'shipPhone': shipPhone,
        'shipAddress': shipAddress,
        'note': note,
        'createdAt': createdAt,
        'items': items.map((i) => i.toJson()).toList(),
        'statusHistory': statusHistory.map((h) => h.toJson()).toList(),
      };

  Order copyWith({
    String? id,
    String? code,
    String? userId,
    String? status,
    String? paymentMethod,
    int? subtotal,
    int? shippingFee,
    String? voucherCode,
    int? discountAmount,
    int? total,
    String? shipName,
    String? shipPhone,
    String? shipAddress,
    String? note,
    String? createdAt,
    List<OrderItem>? items,
    List<OrderStatusHistoryEntry>? statusHistory,
    List<OrderTimelineStep>? timeline,
  }) {
    return Order(
      id: id ?? this.id,
      code: code ?? this.code,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      subtotal: subtotal ?? this.subtotal,
      shippingFee: shippingFee ?? this.shippingFee,
      voucherCode: voucherCode ?? this.voucherCode,
      discountAmount: discountAmount ?? this.discountAmount,
      total: total ?? this.total,
      shipName: shipName ?? this.shipName,
      shipPhone: shipPhone ?? this.shipPhone,
      shipAddress: shipAddress ?? this.shipAddress,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
      statusHistory: statusHistory ?? this.statusHistory,
      timeline: timeline ?? this.timeline,
    );
  }

  /// Đơn có thể huỷ hay không
  bool get canCancel =>
      status == 'pending_payment' ||
      status == 'pending' ||
      status == 'paid' ||
      status == 'processing';

  /// Đơn đã hoàn tất vòng đời (không còn hành động chờ)
  bool get isFinished => status == 'completed' || status == 'delivered';

  String get paymentLabel =>
      paymentMethod == 'vnpay' ? 'VNPay' : 'Thanh toán COD';

  String get statusLabel {
    switch (status) {
      case 'pending_payment':
      case 'pending':
        return 'Chờ xác nhận';
      case 'paid':
        return 'Đã thanh toán';
      case 'processing':
        return 'Đang xử lý';
      case 'shipping':
        return 'Đang giao hàng';
      case 'completed':
      case 'delivered':
        return 'Giao thành công';
      case 'cancelled':
        return 'Đã huỷ';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending_payment':
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'paid':
        return const Color(0xFF3B82F6);
      case 'processing':
        return const Color(0xFF8B5CF6);
      case 'shipping':
        return const Color(0xFF06B6D4);
      case 'completed':
      case 'delivered':
        return const Color(0xFF10B981);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return Colors.white70;
    }
  }

  String get formattedTotal {
    final s = total.toStringAsFixed(0);
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return '${b.toString()}đ';
  }

  String get formattedDate {
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year;
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$hour:$minute - $day/$month/$year';
    } catch (_) {
      return createdAt;
    }
  }
}
