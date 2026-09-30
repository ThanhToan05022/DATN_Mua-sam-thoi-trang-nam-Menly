class Voucher {
  final String id;
  final String code;
  final String title;
  final String discountType; // 'percentage' | 'fixed_amount'
  final int discountValue;
  final int minOrderValue;
  final int? maxDiscount;
  final int usageLimit;
  final int usedCount;
  final String startDate;
  final String endDate;
  final bool isActive;

  Voucher({
    required this.id,
    required this.code,
    required this.title,
    required this.discountType,
    required this.discountValue,
    required this.minOrderValue,
    this.maxDiscount,
    required this.usageLimit,
    required this.usedCount,
    required this.startDate,
    required this.endDate,
    required this.isActive,
  });

  factory Voucher.fromJson(Map<String, dynamic> j) {
    int toInt(dynamic v, [int fallback = 0]) {
      if (v == null) return fallback;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? fallback;
    }

    return Voucher(
      id: j['id']?.toString() ?? '',
      code: j['code']?.toString() ?? '',
      title: j['title']?.toString() ?? '',
      discountType: j['discountType']?.toString() ?? j['discount_type']?.toString() ?? 'fixed_amount',
      discountValue: toInt(j['discountValue'] ?? j['discount_value']),
      minOrderValue: toInt(j['minOrderValue'] ?? j['min_order_value']),
      maxDiscount: (j['maxDiscount'] != null || j['max_discount'] != null)
          ? toInt(j['maxDiscount'] ?? j['max_discount'])
          : null,
      usageLimit: toInt(j['usageLimit'] ?? j['usage_limit'], 100),
      usedCount: toInt(j['usedCount'] ?? j['used_count'], 0),
      startDate: j['startDate']?.toString() ?? j['start_date']?.toString() ?? '',
      endDate: j['endDate']?.toString() ?? j['end_date']?.toString() ?? '',
      isActive: j['isActive'] == true || j['is_active'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'title': title,
        'discountType': discountType,
        'discountValue': discountValue,
        'minOrderValue': minOrderValue,
        'maxDiscount': maxDiscount,
        'usageLimit': usageLimit,
        'usedCount': usedCount,
        'startDate': startDate,
        'endDate': endDate,
        'isActive': isActive,
      };

  int calculateDiscount(int subtotal) {
    if (subtotal < minOrderValue) return 0;
    int discount = 0;
    if (discountType == 'percentage') {
      discount = (subtotal * discountValue ~/ 100);
      if (maxDiscount != null && discount > maxDiscount!) {
        discount = maxDiscount!;
      }
    } else {
      discount = discountValue;
    }
    return discount > subtotal ? subtotal : discount;
  }

  String get discountDescription {
    if (discountType == 'percentage') {
      if (maxDiscount != null && maxDiscount! > 0) {
        return 'Giảm $discountValue% (Tối đa ${_fmt(maxDiscount!)}đ)';
      }
      return 'Giảm $discountValue%';
    } else {
      return 'Giảm ${_fmt(discountValue)}đ';
    }
  }

  static String _fmt(int price) {
    final s = price.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
