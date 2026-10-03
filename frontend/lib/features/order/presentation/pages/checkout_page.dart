import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/auth_guard.dart';
import '../../../address/data/address_model.dart';
import '../../../address/presentation/providers/address_provider.dart';
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

  List<ShippingAddress> _savedAddresses = [];
  String? _selectedAddressId;
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
    final provider = context.read<AddressProvider>();
    await provider.fetchAddresses();
    if (!mounted) return;

    setState(() {
      _savedAddresses = provider.items;
    });

    if (_savedAddresses.isEmpty) return;

    // Ưu tiên địa chỉ mặc định, nếu không thì lấy địa chỉ đầu tiên
    final current = _selectedAddressId;
    if (current != null && _savedAddresses.any((a) => a.id == current)) {
      _selectAddressById(current);
    } else {
      final def = provider.defaultAddress;
      _selectAddressById(def?.id ?? _savedAddresses.first.id);
    }
  }

  void _selectAddressById(String id) {
    final matches = _savedAddresses.where((a) => a.id == id).toList();
    if (matches.isEmpty) return;
    final addr = matches.first;
    setState(() {
      _selectedAddressId = addr.id;
      _useManualAddress = false;
      _nameCtrl.text = addr.recipientName;
      _phoneCtrl.text = addr.phone;
      _addressCtrl.text = addr.fullAddress;
    });
  }

  /// Địa chỉ đang được chọn (null nếu đang nhập tay)
  ShippingAddress? get _selectedAddress {
    if (_useManualAddress || _selectedAddressId == null) return null;
    final matches = _savedAddresses.where((a) => a.id == _selectedAddressId).toList();
    return matches.isEmpty ? null : matches.first;
  }

  bool get _isDefaultSelected => _selectedAddress?.isDefault ?? false;

  void _useDefaultAddress() {
    final def = context.read<AddressProvider>().defaultAddress;
    if (def == null) return;
    setState(() => _savedAddresses = context.read<AddressProvider>().items);
    _selectAddressById(def.id);
  }

  void _showAddressPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
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
                      color: AppTheme.surface2,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Chọn địa chỉ nhận hàng',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await context.push('/shipping-address');
                        if (!mounted) return;
                        await _loadSavedAddresses();
                      },
                      icon: const Icon(Icons.settings_outlined, size: 16, color: AppTheme.primary),
                      label: const Text('Quản lý', style: TextStyle(color: AppTheme.primary, fontSize: 13)),
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
                      final isSelected =
                          !_useManualAddress && _selectedAddressId == addr.id;
                      return InkWell(
                        onTap: () {
                          _selectAddressById(addr.id);
                          Navigator.pop(ctx);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primary.withOpacity(0.1) : AppTheme.surface2,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppTheme.primary : AppTheme.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                color: isSelected ? AppTheme.primary : AppTheme.textMuted,
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
                                          addr.recipientName.isEmpty
                                              ? 'Chưa đặt tên'
                                              : addr.recipientName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (addr.phone.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          Text(
                                            '(${addr.phone})',
                                            style: const TextStyle(
                                              color: AppTheme.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                        if (addr.isDefault) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primary.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'Mặc định',
                                              style: TextStyle(
                                                color: AppTheme.primary,
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
                                      addr.fullAddress,
                                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
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
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: AppTheme.border),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
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
                          color: AppTheme.surface2,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Mã giảm giá MenShop',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_loadingVouchers)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                      )
                    else if (_availableVouchers.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'Hiện chưa có mã giảm giá nào',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
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
                            final isEligible = cart.totalPrice >= v.minOrderValue;
                            final isSelected = _appliedVoucher?.code == v.code;
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primary.withOpacity(0.12)
                                    : AppTheme.surface2,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : isEligible
                                          ? AppTheme.border
                                          : AppTheme.border.withOpacity(0.4),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: isEligible
                                          ? AppTheme.primary.withOpacity(0.2)
                                          : AppTheme.surface,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.local_offer_rounded,
                                      color: isEligible ? AppTheme.primary : AppTheme.textMuted,
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
                                                color: isEligible ? Colors.white : AppTheme.textMuted,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isEligible
                                                    ? AppTheme.primary.withOpacity(0.2)
                                                    : AppTheme.surface,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                v.discountDescription,
                                                style: TextStyle(
                                                  color: isEligible ? AppTheme.primary : AppTheme.textMuted,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          v.title,
                                          style: const TextStyle(
                                            color: AppTheme.textSecondary,
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
                                            color: isEligible ? AppTheme.textMuted : Colors.red.shade400,
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
                                        _applyVoucher(v.code, cart.totalPrice);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primary,
                                        foregroundColor: Colors.black,
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
                                        color: AppTheme.surface,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Thiếu ${_fmt(v.minOrderValue - cart.totalPrice)}đ',
                                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
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

    // Nếu người dùng nhập tay và chưa có địa chỉ nào thì lưu địa chỉ đó,
    // đồng thời đặt làm mặc định để lần sau checkout không phải nhập lại.
    final addressProvider = context.read<AddressProvider>();
    var addressId = _useManualAddress ? null : _selectedAddressId;
    if (_useManualAddress && (_savedAddresses.isEmpty || _saveAsDefault)) {
      try {
        final created = await addressProvider.addAddress(
          ShippingAddress(
            id: '',
            recipientName: name,
            phone: phone,
            province: '',
            district: '',
            ward: '',
            detailAddress: address,
            isDefault: _saveAsDefault || _savedAddresses.isEmpty,
          ),
        );
        // Phải dùng địa chỉ vừa tạo, không phải items.first (API có thể append).
        addressId = created?.id;
        if (created != null) {
          _savedAddresses = addressProvider.items;
        }
      } catch (_) {
        // Không lưu được vẫn đặt hàng được bằng khối ship bên dưới
      }
    }

    try {
      final payload = <String, dynamic>{
        'items': items,
        'paymentMethod': _paymentMethod,
        'note': _noteCtrl.text.trim(),
        'voucherCode': _appliedVoucher?.code,
        'discountAmount': _discountAmount,
      };

      if (addressId != null) {
        // Backend tự dựng lại thông tin giao hàng từ địa chỉ đã lưu
        payload['addressId'] = addressId;
      } else {
        payload['ship'] = {
          'name': name,
          'phone': phone,
          'address': address,
        };
      }

      final res = await DioClient.instance.dio.post('/orders', data: payload);

      if (res.statusCode == 201 || res.statusCode == 200) {
        await cart.clear();
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
            if (_savedAddresses.isNotEmpty && !_useManualAddress)
              _section('Địa chỉ giao hàng', [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surface2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _isDefaultSelected
                          ? AppTheme.primary.withOpacity(0.6)
                          : AppTheme.border,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            color: _isDefaultSelected
                                ? AppTheme.primary
                                : AppTheme.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  _nameCtrl.text,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '(${_phoneCtrl.text})',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                if (_isDefaultSelected) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Mặc định',
                                      style: TextStyle(
                                        color: AppTheme.primary,
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
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              child: Row(
                                children: [
                                  Text(
                                    'Đổi',
                                    style: TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, size: 16, color: AppTheme.primary),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _addressCtrl.text,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.3),
                      ),
                      if (!_isDefaultSelected) ...[
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: _useDefaultAddress,
                          child: const Text(
                            '← Chọn lại địa chỉ mặc định',
                            style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600),
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
                        const Text(
                          'Nhập địa chỉ mới',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        GestureDetector(
                          onTap: _useDefaultAddress,
                          child: const Text(
                            'Dùng địa chỉ mặc định',
                            style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
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
                        activeColor: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Đặt địa chỉ này làm mặc định cho lần mua sau',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
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
                    color: AppTheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.confirmation_number_rounded, color: AppTheme.primary, size: 20),
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
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '-${_fmt(_discountAmount)} đ',
                                    style: const TextStyle(
                                      color: Colors.black,
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
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _removeVoucher,
                        icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted, size: 18),
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
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: 'Nhập mã giảm giá (VD: MENLY10)',
                          hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.normal),
                          prefixIcon: const Icon(Icons.confirmation_number_outlined, size: 18, color: AppTheme.textMuted),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          filled: true,
                          fillColor: AppTheme.surface2,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppTheme.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppTheme.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppTheme.primary),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _applyingVoucher
                          ? null
                          : () => _applyVoucher(_voucherCtrl.text, cart.totalPrice),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _applyingVoucher
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
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
                            const Icon(Icons.local_offer_outlined, size: 14, color: AppTheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              _availableVouchers.isNotEmpty
                                  ? 'Xem danh sách (${_availableVouchers.length} mã khả dụng)'
                                  : 'Xem tất cả mã giảm giá',
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const Icon(Icons.chevron_right, size: 16, color: AppTheme.primary),
                      ],
                    ),
                  ),
                ),
              ],
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
                  const Text('Tạm tính', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  Text('${_fmt(cart.totalPrice)} đ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
              if (_discountAmount > 0) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.confirmation_number_outlined, size: 14, color: AppTheme.primary),
                        const SizedBox(width: 4),
                        Text('Mã giảm giá (${_appliedVoucher?.code ?? ""})',
                            style: const TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Text('-${_fmt(_discountAmount)} đ',
                        style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ],
              const SizedBox(height: 6),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Phí vận chuyển', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  Text('Miễn phí', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
              const Divider(color: AppTheme.border),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tổng thanh toán', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(
                    '${_fmt((cart.totalPrice - _discountAmount) > 0 ? (cart.totalPrice - _discountAmount) : 0)} đ',
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
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
