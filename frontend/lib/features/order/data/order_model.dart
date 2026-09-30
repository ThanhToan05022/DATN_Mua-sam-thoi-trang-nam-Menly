import 'package:flutter/material.dart';

int _toInt(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? fallback;
}

class OrderItem {
  final String id;
  final String variantId;
  final String productName;
  final String size;
  final String color;
  final int unitPrice;
  final int quantity;

  OrderItem({
    required this.id,
    required this.variantId,
    required this.productName,
    required this.size,
    required this.color,
    required this.unitPrice,
    required this.quantity,
  });

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
        id: j['id']?.toString() ?? '',
        variantId: j['variantId']?.toString() ?? j['variant_id']?.toString() ?? '',
        productName: j['productName'] ?? j['product_name'] ?? j['name'] ?? 'Sản phẩm',
        size: j['size']?.toString() ?? '',
        color: j['color']?.toString() ?? '',
        unitPrice: _toInt(j['unitPrice'] ?? j['unit_price'] ?? j['price']),
        quantity: _toInt(j['quantity'], 1),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'variantId': variantId,
        'productName': productName,
        'size': size,
        'color': color,
        'unitPrice': unitPrice,
        'quantity': quantity,
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
  });

  factory Order.fromJson(Map<String, dynamic> j) {
    final rawItems = (j['items'] as List<dynamic>?) ??
        (j['order_items'] as List<dynamic>?) ??
        [];
    return Order(
      id: j['id']?.toString() ?? '',
      code: j['code']?.toString() ?? 'ORD',
      userId: j['userId']?.toString() ?? j['user_id']?.toString() ?? '',
      status: j['status']?.toString() ?? 'pending_payment',
      paymentMethod: j['paymentMethod']?.toString() ?? j['payment_method']?.toString() ?? 'cod',
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
      createdAt: j['createdAt']?.toString() ?? j['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      items: rawItems.map((e) => OrderItem.fromJson(e as Map<String, dynamic>)).toList(),
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
    );
  }

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
