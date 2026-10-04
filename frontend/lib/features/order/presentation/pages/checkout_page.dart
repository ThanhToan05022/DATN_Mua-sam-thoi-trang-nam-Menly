import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/utils/auth_guard.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../cart/data/cart_model.dart';
import '../../data/order_model.dart';
import '../../data/voucher_model.dart';
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
  final _voucherCtrl = TextEditingController();
  String _paymentMethod = 'cod';
  bool _loading = false;

  List<Map<String, dynamic>> _savedAddresses = [];
  int _defaultAddressIndex = 0;
  int? _selectedAddressIndex;
  bool _useManualAddress = false;
  bool _saveAsDefault = false;

  Voucher? _appliedVoucher;
  int _discountAmount = 0;
  bool _applyingVoucher = false;
  List<Voucher> _availableVouchers = [];
  bool _loadingVouchers = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
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

      await _loadSavedAddresses();
      await _loadAvailableVouchers();
      if (!mounted) return;

      final auth = context.read<AuthProvider>();
      if (auth.user != null && _nameCtrl.text.isEmpty) {
        setState(() {
          _nameCtrl.text = auth.user!.fullName;
        });
      }
    });
  }

  Future<void> _loadSavedAddresses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('shippingAddresses');
      final defIdx = prefs.getInt('defaultAddressIndex') ?? 0;
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _savedAddresses = List<Map<String, dynamic>>.from(decoded);
        }
      }
      _defaultAddressIndex = defIdx;
      if (_savedAddresses.isNotEmpty) {
        final targetIdx =
            (_defaultAddressIndex >= 0 && _defaultAddressIndex < _savedAddresses.length)
                ? _defaultAddressIndex
                : 0;
        _selectAddress(targetIdx);
      }
    } catch (_) {}
  }

  void _selectAddress(int index) {
    if (index >= 0 && index < _savedAddresses.length) {
      final addr = _savedAddresses[index];
      setState(() {
        _selectedAddressIndex = index;
        _useManualAddress = false;
        _nameCtrl.text = addr['name']?.toString() ?? '';
        _phoneCtrl.text = addr['phone']?.toString() ?? '';
        _addressCtrl.text = addr['address']?.toString() ?? '';
      });
    }
  }

  void _showAddressPicker() {
    final c = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: c.surfaceVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Chọn địa chỉ nhận hàng',
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await context.push('/shipping-address');
                        await _loadSavedAddresses();
                      },
                      icon: Icon(Icons.settings_outlined, size: 16, color: c.secondary),
                      label: Text('Quản lý', style: TextStyle(color: c.secondary, fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _savedAddresses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final addr = _savedAddresses[i];
                      final isSelected = !_useManualAddress && _selectedAddressIndex == i;
                      final isDefault = i == _defaultAddressIndex;
                      return InkWell(
                        onTap: () {
                          _selectAddress(i);
                          Navigator.pop(ctx);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? c.primarySoft : c.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? c.secondary : c.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                color: isSelected ? c.secondary : c.textMuted,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          addr['name'] ?? '',
                                          style: TextStyle(
                                            color: c.textPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '(${addr['phone'] ?? ''})',
                                          style: TextStyle(
                                            color: c.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (isDefault) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: c.primarySoft,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Mặc định',
                                              style: TextStyle(
                                                color: c.secondary,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      addr['address'] ?? '',
                                      style: TextStyle(color: c.textMuted, fontSize: 12),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _useManualAddress = true;
                      _nameCtrl.clear();
                      _phoneCtrl.clear();
                      _addressCtrl.clear();
                      final auth = context.read<AuthProvider>();
                      if (auth.user != null) {
                        _nameCtrl.text = auth.user!.fullName;
                      }
                    });
                    Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.edit_location_alt_outlined, size: 18),
                  label: const Text('Nhập địa chỉ nhận hàng khác'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.textPrimary,
                    side: BorderSide(color: c.border),
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadAvailableVouchers() async {
    setState(() => _loadingVouchers = true);
    try {
      final res = await DioClient.instance.dio.get('/vouchers');
      if (res.data is List) {
        final list = (res.data as List).map((j) => Voucher.fromJson(j)).toList();
        if (mounted) {
          setState(() {
            _availableVouchers = list.where((v) => v.isActive).toList();
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _availableVouchers = [
            Voucher(
              id: 'vch-1',
              code: 'MENLY10',
              title: 'Giảm 10% tối đa 50k cho đơn từ 200k',
              discountType: 'percentage',
              discountValue: 10,
              minOrderValue: 200000,
              maxDiscount: 50000,
              usageLimit: 100,
              usedCount: 0,
              startDate: '2026-01-01',
              endDate: '2026-12-31',
              isActive: true,
            ),
            Voucher(
              id: 'vch-2',
              code: 'MENLY50K',
              title: 'Giảm ngay 50.000đ cho đơn từ 300k',
              discountType: 'fixed_amount',
              discountValue: 50000,
              minOrderValue: 300000,
              maxDiscount: 50000,
              usageLimit: 50,
              usedCount: 0,
              startDate: '2026-01-01',
              endDate: '2026-12-31',
              isActive: true,
            ),
            Voucher(
              id: 'vch-3',
              code: 'FREESHIP',
              title: 'Miễn phí vận chuyển (giảm 30.000đ)',
              discountType: 'fixed_amount',
              discountValue: 30000,
              minOrderValue: 250000,
              maxDiscount: 30000,
              usageLimit: 200,
              usedCount: 0,
              startDate: '2026-01-01',
              endDate: '2026-12-31',
              isActive: true,
            ),
            Voucher(
              id: 'vch-4',
              code: 'VIP100K',
              title: 'Giảm 100k cho khách VIP đơn từ 800k',
              discountType: 'fixed_amount',
              discountValue: 100000,
              minOrderValue: 800000,
              maxDiscount: 100000,
              usageLimit: 30,
              usedCount: 0,
              startDate: '2026-01-01',
              endDate: '2026-12-31',
              isActive: true,
            ),
          ];
        });
      }
    } finally {
      if (mounted) setState(() => _loadingVouchers = false);
    }
  }

  Future<void> _applyVoucher(String rawCode, int subtotal) async {
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mã giảm giá')),
      );
      return;
    }

    setState(() => _applyingVoucher = true);
    try {
      final res = await DioClient.instance.dio.post('/vouchers/apply', data: {
        'code': code,
        'subtotal': subtotal,
      });

      if (res.data != null && res.data['valid'] == true) {
        final disc = (res.data['discountAmount'] as num?)?.toInt() ?? 0;
        final vData = res.data['voucher'];
        final v = vData != null ? Voucher.fromJson(vData) : null;
        setState(() {
          _appliedVoucher = v ??
              Voucher(
                id: 'custom',
                code: code,
                title: 'Mã giảm giá $code',
                discountType: 'fixed_amount',
                discountValue: disc,
                minOrderValue: 0,
                usageLimit: 100,
                usedCount: 0,
                startDate: '',
                endDate: '',
                isActive: true,
              );
          _discountAmount = disc;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Áp dụng thành công mã "$code"! Giảm ${_fmt(disc)} đ'),
              backgroundColor: Colors.green.shade800,
            ),
          );
        }
        return;
      }
    } catch (e) {
      final found = _availableVouchers.firstWhere(
        (v) => v.code.toUpperCase() == code,
        orElse: () => Voucher(
          id: '',
          code: '',
          title: '',
          discountType: '',
          discountValue: 0,
          minOrderValue: 0,
          usageLimit: 0,
          usedCount: 0,
          startDate: '',
          endDate: '',
          isActive: false,
        ),
      );

      if (found.code.isNotEmpty) {
        if (subtotal < found.minOrderValue) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Mã này chỉ áp dụng cho đơn hàng từ ${_fmt(found.minOrderValue)}đ',
                ),
                backgroundColor: Colors.red.shade800,
              ),
            );
          }
          return;
        }
        final disc = found.calculateDiscount(subtotal);
        setState(() {
          _appliedVoucher = found;
          _discountAmount = disc;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Áp dụng thành công mã "$code"! Giảm ${_fmt(disc)} đ'),
              backgroundColor: Colors.green.shade800,
            ),
          );
        }
        return;
      }

      String errMsg = 'Mã giảm giá "$code" không hợp lệ';
      if (e is DioException && e.response?.data != null) {
        final d = e.response!.data;
        errMsg = d['error']?['message'] ?? d['message'] ?? errMsg;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errMsg),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _applyingVoucher = false);
    }
  }

  void _removeVoucher() {
    setState(() {
      _appliedVoucher = null;
      _discountAmount = 0;
      _voucherCtrl.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã gỡ bỏ mã giảm giá')),
    );
  }

  void _showVoucherPicker(CartProvider cart) {
    final c = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: c.surfaceVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Mã giảm giá MenShop',
                          style: TextStyle(
                            color: c.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: Icon(Icons.close, color: c.textMuted, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_loadingVouchers)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator(color: c.secondary)),
                      )
                    else if (_availableVouchers.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'Hiện chưa có mã giảm giá nào',
                            style: TextStyle(color: c.textMuted, fontSize: 13),
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: _availableVouchers.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final v = _availableVouchers[i];
                            final isEligible = cart.selectedTotalPrice >= v.minOrderValue;
                            final isSelected = _appliedVoucher?.code == v.code;
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? c.primarySoft
                                    : c.surfaceVariant,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? c.secondary
                                      : isEligible
                                          ? c.border
                                          : c.border.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: isEligible
                                          ? c.primarySoft
                                          : c.surface,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.local_offer_rounded,
                                      color: isEligible ? c.secondary : c.textMuted,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              v.code,
                                              style: TextStyle(
                                                color: isEligible ? c.textPrimary : c.textMuted,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isEligible
                                                      ? c.primarySoft
                                                      : c.surface,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  v.discountDescription,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: isEligible ? c.secondary : c.textMuted,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          v.title,
                                          style: TextStyle(
                                            color: c.textSecondary,
                                            fontSize: 12,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          v.minOrderValue > 0
                                              ? 'Đơn tối thiểu ${_fmt(v.minOrderValue)}đ'
                                              : 'Áp dụng cho mọi đơn hàng',
                                          style: TextStyle(
                                            color: isEligible ? c.textMuted : Colors.red.shade400,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (isSelected)
                                    TextButton(
                                      onPressed: () {
                                        _removeVoucher();
                                        Navigator.pop(ctx);
                                      },
                                      child: const Text('Bỏ chọn', style: TextStyle(color: Colors.red, fontSize: 12)),
                                    )
                                  else if (isEligible)
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        _applyVoucher(v.code, cart.selectedTotalPrice);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: c.primary,
                                        foregroundColor: c.onPrimary,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: const Text('Dùng', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: c.surface,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Thiếu ${_fmt(v.minOrderValue - cart.selectedTotalPrice)}đ',
                                        style: TextStyle(color: c.textMuted, fontSize: 10),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _noteCtrl.dispose();
    _voucherCtrl.dispose();
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
    if (cart.selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất 1 sản phẩm để thanh toán')),
      );
      return;
    }

    setState(() => _loading = true);
    // Giữ lại id các món đã đặt để chỉ xoá đúng chúng khỏi giỏ sau khi thành công.
    final orderedVariantIds =
        cart.selectedItems.map((i) => i.variant.id).toList();
    final items = cart.selectedItems
        .map((i) => {
              'variantId': i.variant.id,
              'quantity': i.quantity,
              'unitPrice': i.product.price,
              'productName': i.product.name,
              'size': i.variant.size,
              'color': i.variant.color,
            })
        .toList();

    // Lưu địa chỉ mặc định nếu người dùng chọn hoặc chưa có địa chỉ nào
    if (_saveAsDefault || _savedAddresses.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final newAddr = {'name': name, 'phone': phone, 'address': address};
        final exists = _savedAddresses.any((a) => a['address'] == address && a['phone'] == phone);
        if (!exists) {
          _savedAddresses.insert(0, newAddr);
          await prefs.setString('shippingAddresses', jsonEncode(_savedAddresses));
          await prefs.setInt('defaultAddressIndex', 0);
        }
      } catch (_) {}
    }

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
        'voucherCode': _appliedVoucher?.code,
        'discountAmount': _discountAmount,
      });

      if (res.statusCode == 201 || res.statusCode == 200) {
        await cart.removeMany(orderedVariantIds);
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
          final resData = e.response?.data;
          if (resData is Map && resData['message'] != null) {
            msg = resData['message'].toString();
          } else if (resData is Map && resData['error'] != null) {
            msg = resData['error'].toString();
          } else {
            msg = e.message ?? e.error?.toString() ?? 'Đã có lỗi xảy ra khi tạo đơn hàng';
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.of(context).danger, duration: const Duration(seconds: 4)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
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
            if (_savedAddresses.isNotEmpty && !_useManualAddress)
              _section('Địa chỉ giao hàng', [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: c.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: (_selectedAddressIndex == _defaultAddressIndex)
                          ? c.secondary.withValues(alpha: 0.6)
                          : c.border,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            color: (_selectedAddressIndex == _defaultAddressIndex)
                                ? c.secondary
                                : c.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  _nameCtrl.text,
                                  style: TextStyle(
                                    color: c.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '(${_phoneCtrl.text})',
                                  style: TextStyle(
                                    color: c.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                if (_selectedAddressIndex == _defaultAddressIndex) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: c.primarySoft,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Mặc định',
                                      style: TextStyle(
                                        color: c.secondary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: _showAddressPicker,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              child: Row(
                                children: [
                                  Text(
                                    'Đổi',
                                    style: TextStyle(
                                      color: c.secondary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, size: 16, color: c.secondary),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _addressCtrl.text,
                        style: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.3),
                      ),
                      if (_selectedAddressIndex != _defaultAddressIndex) ...[
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => _selectAddress(_defaultAddressIndex),
                          child: Text(
                            '← Chọn lại địa chỉ mặc định',
                            style: TextStyle(color: c.secondary, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _field(_noteCtrl, 'Ghi chú cho shipper (tùy chọn)', Icons.note_rounded),
              ])
            else
              _section('Thông tin giao hàng', [
                if (_savedAddresses.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Nhập địa chỉ mới',
                          style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        GestureDetector(
                          onTap: () => _selectAddress(_defaultAddressIndex),
                          child: Text(
                            'Dùng địa chỉ mặc định',
                            style: TextStyle(color: c.secondary, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                _field(_nameCtrl, 'Họ và tên', Icons.person_rounded),
                _field(_phoneCtrl, 'Số điện thoại', Icons.phone_rounded, type: TextInputType.phone),
                _field(_addressCtrl, 'Địa chỉ giao hàng', Icons.location_on_rounded, lines: 2),
                _field(_noteCtrl, 'Ghi chú (tùy chọn)', Icons.note_rounded),
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _saveAsDefault,
                        onChanged: (v) => setState(() => _saveAsDefault = v ?? false),
                        activeColor: c.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Đặt địa chỉ này làm mặc định cho lần mua sau',
                        style: TextStyle(color: c.textSecondary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
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
            _section('Mã khuyến mãi / Voucher', [
              if (_appliedVoucher != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.secondary.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: c.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.confirmation_number_rounded, color: c.secondary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _appliedVoucher!.code,
                                  style: TextStyle(
                                    color: c.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: c.secondary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '-${_fmt(_discountAmount)} đ',
                                    style: TextStyle(
                                      color: c.onPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _appliedVoucher!.title,
                              style: TextStyle(color: c.textSecondary, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _removeVoucher,
                        icon: Icon(Icons.close_rounded, color: c.textMuted, size: 18),
                        tooltip: 'Gỡ mã',
                      ),
                    ],
                  ),
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _voucherCtrl,
                        textCapitalization: TextCapitalization.characters,
                        style: TextStyle(color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: 'Nhập mã giảm giá (VD: MENLY10)',
                          hintStyle: TextStyle(color: c.textMuted, fontSize: 12, fontWeight: FontWeight.normal),
                          prefixIcon: Icon(Icons.confirmation_number_outlined, size: 18, color: c.textMuted),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          filled: true,
                          fillColor: c.surfaceVariant,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: c.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: c.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: c.secondary),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _applyingVoucher
                          ? null
                          : () => _applyVoucher(_voucherCtrl.text, cart.selectedTotalPrice),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.primary,
                        foregroundColor: c.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _applyingVoucher
                          ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: c.onPrimary))
                          : const Text('Áp dụng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _showVoucherPicker(cart),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.local_offer_outlined, size: 14, color: c.secondary),
                            const SizedBox(width: 6),
                            Text(
                              _availableVouchers.isNotEmpty
                                  ? 'Xem danh sách (${_availableVouchers.length} mã khả dụng)'
                                  : 'Xem tất cả mã giảm giá',
                              style: TextStyle(
                                color: c.secondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Icon(Icons.chevron_right, size: 16, color: c.secondary),
                      ],
                    ),
                  ),
                ),
              ],
            ]),
            const SizedBox(height: 16),
            _section('Đơn hàng', [
              ...cart.selectedItems.map((i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(child: Text('${i.product.name} (${i.variant.size}) x${i.quantity}',
                        style: TextStyle(color: c.textSecondary, fontSize: 13))),
                    Text('${_fmt(i.subtotal)} đ', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              )),
              Divider(color: c.border),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tạm tính', style: TextStyle(color: c.textSecondary, fontSize: 13)),
                  Text('${_fmt(cart.selectedTotalPrice)} đ', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
              if (_discountAmount > 0) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.confirmation_number_outlined, size: 14, color: c.secondary),
                        const SizedBox(width: 4),
                        Text('Mã giảm giá (${_appliedVoucher?.code ?? ""})',
                            style: TextStyle(color: c.secondary, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Text('-${_fmt(_discountAmount)} đ',
                        style: TextStyle(color: c.secondary, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ],
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Phí vận chuyển', style: TextStyle(color: c.textSecondary, fontSize: 13)),
                  Text('Miễn phí', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
              Divider(color: c.border),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tổng thanh toán', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(
                    '${_fmt((cart.selectedTotalPrice - _discountAmount) > 0 ? (cart.selectedTotalPrice - _discountAmount) : 0)} đ',
                    style: TextStyle(color: c.secondary, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
            ]),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Đặt hàng ngay',
              loading: _loading,
              onPressed: _loading ? null : _placeOrder,
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon, {TextInputType type = TextInputType.text, int lines = 1}) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        maxLines: lines,
        style: TextStyle(color: c.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, size: 18, color: c.textMuted),
          isDense: true,
        ),
      ),
    );
  }
}

class _PayOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;
  const _PayOption({required this.label, required this.icon, required this.value, required this.groupValue, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: groupValue == value ? c.primarySoft : c.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: groupValue == value ? c.secondary : c.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: groupValue == value ? c.secondary : c.textMuted, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(
              color: groupValue == value ? c.textPrimary : c.textSecondary,
              fontWeight: FontWeight.w600, fontSize: 13,
            ))),
            Radio<String>(value: value, groupValue: groupValue, onChanged: onChanged, activeColor: c.secondary),
          ],
        ),
      ),
    );
  }
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
