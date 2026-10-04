import 'package:flutter/material.dart';

/// Warm, premium accent colors the user can switch between via the display
/// button. These are the highlight tone (prices, active states, filter button);
/// the primary CTA / nav color stays an ink neutral per [AppColors].
enum AppAccent {
  camel('Camel', Color(0xFFB8824A)),
  gold('Vàng đồng', Color(0xFFC8A560)),
  olive('Xanh rêu', Color(0xFF6B7A4F)),
  rust('Đất nung', Color(0xFFB5603B)),
  burgundy('Rượu vang', Color(0xFF8C4A4A)),
  slate('Xám xanh', Color(0xFF51607A));

  const AppAccent(this.label, this.color);

  final String label;
  final Color color;

  static AppAccent? tryFromName(String? name) {
    for (final a in AppAccent.values) {
      if (a.name == name) return a;
    }
    return null;
  }
}
