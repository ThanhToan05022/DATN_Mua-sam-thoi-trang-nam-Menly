import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/auth_guard.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../cart/data/cart_model.dart';
import '../../data/order_model.dart';
import '../providers/order_provider.dart';

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!AuthGuard.check(
        context,
        actionTitle: 'Đăng nhập để đặt hàng',
        actionMessage:
            'Bạn đang duyệt ẩn danh. Vui lòng đăng nhập tài khoản để tiến hành đặt hàng.',
        redirectPath: '/checkout',
      )) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/cart');
        }
        return;
      }

      final auth = context.read<AuthProvider>();
      if (auth.user != null && _nameCtrl.text.isEmpty) {
        setState(() {
          _nameCtrl.text = auth.user!.fullName;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!AuthGuard.check(
      context,
      actionTitle: 'Đăng nhập để đặt hàng',
      actionMessage:
          'Bạn đang duyệt ẩn danh. Vui lòng đăng nhập để hoàn tất đơn hàng.',
      redirectPath: '/checkout',
    )) {
      return;
    }

    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final address = _addressCtrl.text.trim();

    if (name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập họ và tên (tối thiểu 2 ký tự)')),
      );
      return;
    }
    if (phone.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số điện thoại hợp lệ (tối thiểu 9 số)')),
      );
      return;
    }
    if (address.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập địa chỉ giao hàng cụ thể (tối thiểu 5 ký tự)')),
      );
      return;
    }

    final cart = context.read<CartProvider>();
    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giỏ hàng đang trống, không thể thanh toán')),
      );
      return;
    }

    setState(() => _loading = true);
    final items = cart.items
        .map((i) => {
              'variantId': i.variant.id,
              'quantity': i.quantity,
              'unitPrice': i.product.price,
              'productName': i.product.name,
              'size': i.variant.size,
              'color': i.variant.color,
            })
        .toList();

    try {
      final res = await DioClient.instance.dio.post('/orders', data: {
        'items': items,
        'paymentMethod': _paymentMethod,
        'ship': {
          'name': name,
          'phone': phone,
          'address': address,
        },
        'note': _noteCtrl.text.trim(),
      });

      if (res.statusCode == 201 || res.statusCode == 200) {
        cart.clear();
        final orderData = res.data is Map ? (res.data as Map<String, dynamic>) : null;
        if (orderData != null && mounted) {
          final createdOrder = Order.fromJson(orderData);
          await context.read<OrderProvider>().addPlacedOrder(createdOrder);
          if (mounted) {
            context.go('/order-success?code=${Uri.encodeComponent(createdOrder.code)}&total=${createdOrder.total}');
          }
        } else if (mounted) {
          context.go('/order-success');
        }
      } else {
        throw Exception('Đặt hàng thất bại');
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (e is DioException) {
          msg = e.message ?? e.error?.toString() ?? 'Đã có lỗi xảy ra khi tạo đơn hàng';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppTheme.error, duration: const Duration(seconds: 4)),
        );
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
