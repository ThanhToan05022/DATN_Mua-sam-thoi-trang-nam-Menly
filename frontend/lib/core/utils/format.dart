import 'package:flutter/material.dart';

/// Formats an integer VND amount as "1.200.000đ".
String formatVnd(int amount) {
  final s = amount.abs().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  final sign = amount < 0 ? '-' : '';
  return '$sign${buf.toString()}đ';
}

/// Picks a representative icon for a men's-fashion category based on its
/// slug/name keywords (outlined style to match the design language).
IconData categoryIcon(String slugOrName) {
  final key = slugOrName.toLowerCase();
  if (key.contains('so-mi') || key.contains('sơ mi')) {
    return Icons.checkroom_outlined;
  }
  if (key.contains('polo') || key.contains('t-shirt') || key.contains('thun')) {
    return Icons.dry_cleaning_outlined;
  }
  if (key.contains('jean')) return Icons.account_balance_wallet_outlined;
  if (key.contains('quan') || key.contains('quần') || key.contains('kaki')) {
    return Icons.straighten_outlined;
  }
  if (key.contains('khoac') || key.contains('khoác') || key.contains('blazer')) {
    return Icons.ac_unit_outlined;
  }
  if (key.contains('giay') || key.contains('giày') || key.contains('shoe')) {
    return Icons.ice_skating_outlined;
  }
  return Icons.local_mall_outlined;
}
