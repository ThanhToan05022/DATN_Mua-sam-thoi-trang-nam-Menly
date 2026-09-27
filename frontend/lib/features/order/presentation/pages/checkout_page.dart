import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../cart/data/cart_model.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});
  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _paymentMethod = 'cod';
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose();
    _addressCtrl.dispose(); _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (_nameCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty || _addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin giao hàng')));
      return;
    }
    setState(() => _loading = true);
    final cart = context.read<CartProvider>();
    final items = cart.items.map((i) => {
      'variantId': i.variant.id,
      'quantity': i.quantity,
      'unitPrice': i.product.price,
      'productName': i.product.name,
      'size': i.variant.size,
      'color': i.variant.color,
    }).toList();

    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.apiBase}/orders'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer mock-user-123'},
        body: jsonEncode({
          'items': items,
          'paymentMethod': _paymentMethod,
          'shipName': _nameCtrl.text.trim(),
          'shipPhone': _phoneCtrl.text.trim(),
          'shipAddress': _addressCtrl.text.trim(),
          'note': _noteCtrl.text.trim(),
        }),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        cart.clear();
        if (mounted) context.go('/order-success');
      } else {
        final err = jsonDecode(res.body);
        throw Exception(err['error']?['message'] ?? 'Đặt hàng thất bại');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.error));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section('Thông tin giao hàng', [
              _field(_nameCtrl, 'Họ và tên', Icons.person_rounded),
              _field(_phoneCtrl, 'Số điện thoại', Icons.phone_rounded, type: TextInputType.phone),
              _field(_addressCtrl, 'Địa chỉ giao hàng', Icons.location_on_rounded, lines: 2),
              _field(_noteCtrl, 'Ghi chú (tùy chọn)', Icons.note_rounded),
            ]),
            const SizedBox(height: 16),
            _section('Phương thức thanh toán', [
              _PayOption(
                label: 'Thanh toán khi nhận hàng (COD)',
                icon: Icons.local_shipping_rounded,
                value: 'cod',
                groupValue: _paymentMethod,
                onChanged: (v) => setState(() => _paymentMethod = v!),
              ),
              _PayOption(
                label: 'Thanh toán trực tuyến VNPay',
                icon: Icons.payment_rounded,
                value: 'vnpay',
                groupValue: _paymentMethod,
                onChanged: (v) => setState(() => _paymentMethod = v!),
              ),
            ]),
            const SizedBox(height: 16),
            _section('Đơn hàng', [
              ...cart.items.map((i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(child: Text('${i.product.name} (${i.variant.size}) x${i.quantity}',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
                    Text('${_fmt(i.subtotal)} đ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              )),
              const Divider(color: AppTheme.border),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tổng cộng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text('${_fmt(cart.totalPrice)} đ', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ]),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _placeOrder,
              child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text('Đặt hàng ngay'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 12),
        ...children,
      ],
    ),
  );

  Widget _field(TextEditingController ctrl, String hint, IconData icon, {TextInputType type = TextInputType.text, int lines = 1}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: ctrl,
      keyboardType: type,
      maxLines: lines,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppTheme.textMuted),
        isDense: true,
      ),
    ),
  );
}

class _PayOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;
  const _PayOption({required this.label, required this.icon, required this.value, required this.groupValue, required this.onChanged});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => onChanged(value),
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: groupValue == value ? AppTheme.primary.withOpacity(0.1) : AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: groupValue == value ? AppTheme.primary : AppTheme.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: groupValue == value ? AppTheme.primary : AppTheme.textMuted, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(
            color: groupValue == value ? Colors.white : AppTheme.textSecondary,
            fontWeight: FontWeight.w600, fontSize: 13,
          ))),
          Radio<String>(value: value, groupValue: groupValue, onChanged: onChanged, activeColor: AppTheme.primary),
        ],
      ),
    ),
  );
}

String _fmt(int price) {
  final s = price.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return buf.toString();
}
