import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../core/widgets/state_views.dart';

class ShippingAddressPage extends StatefulWidget {
  const ShippingAddressPage({super.key});
  @override
  State<ShippingAddressPage> createState() => _ShippingAddressPageState();
}

class _ShippingAddressPageState extends State<ShippingAddressPage> {
  List<Map<String, dynamic>> _addresses = [];
  int _defaultIndex = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('shippingAddresses');
    _defaultIndex = prefs.getInt('defaultAddressIndex') ?? 0;
    if (raw != null) {
      _addresses = List<Map<String, dynamic>>.from(jsonDecode(raw));
    }
    setState(() => _loading = false);
  }

  Future<void> _saveAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('shippingAddresses', jsonEncode(_addresses));
    await prefs.setInt('defaultAddressIndex', _defaultIndex);
  }

  void _addOrEditAddress({int? editIndex}) {
    final c = AppColors.of(context);
    final isEdit = editIndex != null;
    final nameCtrl = TextEditingController(text: isEdit ? _addresses[editIndex]['name'] : '');
    final phoneCtrl = TextEditingController(text: isEdit ? _addresses[editIndex]['phone'] : '');
    final addressCtrl = TextEditingController(text: isEdit ? _addresses[editIndex]['address'] : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusXl)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: c.surfaceVariant, borderRadius: BorderRadius.circular(AppTheme.radiusPill))),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(isEdit ? 'Sửa địa chỉ' : 'Thêm địa chỉ mới',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.textPrimary)),
              const SizedBox(height: AppSpacing.xl),
              _buildField(nameCtrl, 'Họ và tên', Icons.person_rounded),
              const SizedBox(height: AppSpacing.md),
              _buildField(phoneCtrl, 'Số điện thoại', Icons.phone_rounded, type: TextInputType.phone),
              const SizedBox(height: AppSpacing.md),
              _buildField(addressCtrl, 'Địa chỉ chi tiết', Icons.location_on_rounded, lines: 2),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: isEdit ? 'Cập nhật' : 'Thêm địa chỉ',
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty || addressCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: const Text('Vui lòng điền đầy đủ thông tin'), backgroundColor: c.danger),
                    );
                    return;
                  }
                  final addr = {
                    'name': nameCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim(),
                    'address': addressCtrl.text.trim(),
                  };
                  setState(() {
                    if (isEdit) {
                      _addresses[editIndex] = addr;
                    } else {
                      _addresses.add(addr);
                      if (_addresses.length == 1) _defaultIndex = 0;
                    }
                  });
                  _saveAddresses();
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteAddress(int index) {
    final c = AppColors.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        title: Text('Xoá địa chỉ', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w700)),
        content: Text('Bạn có chắc muốn xoá địa chỉ này?', style: TextStyle(color: c.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Huỷ', style: TextStyle(color: c.textMuted))),
          TextButton(
            onPressed: () {
              setState(() {
                _addresses.removeAt(index);
                if (_defaultIndex >= _addresses.length) _defaultIndex = _addresses.isEmpty ? 0 : _addresses.length - 1;
              });
              _saveAddresses();
              Navigator.pop(ctx);
            },
            child: Text('Xoá', style: TextStyle(color: c.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint, IconData icon, {TextInputType type = TextInputType.text, int lines = 1}) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: c.border),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        maxLines: lines,
        style: TextStyle(color: c.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: c.textMuted, fontSize: 14),
          prefixIcon: Icon(icon, color: c.textMuted, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: const Text('Địa chỉ giao hàng'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => context.pop()),
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: c.secondary),
            onPressed: () => _addOrEditAddress(),
          ),
        ],
      ),
      body: _loading
          ? const LoadingView()
          : _addresses.isEmpty
              ? StatusView(
                  icon: Icons.location_off_rounded,
                  title: 'Chưa có địa chỉ nào',
                  message: 'Thêm địa chỉ giao hàng để mua sắm nhanh hơn',
                  actionLabel: 'Thêm địa chỉ',
                  onAction: () => _addOrEditAddress(),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: _addresses.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (_, i) => _addressCard(i),
                ),
    );
  }

  Widget _addressCard(int index) {
    final c = AppColors.of(context);
    final addr = _addresses[index];
    final isDefault = index == _defaultIndex;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
            color: isDefault
                ? c.secondary.withValues(alpha: 0.5)
                : c.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
              color: c.shadow, blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_rounded, color: isDefault ? c.secondary : c.textMuted, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(addr['name'] ?? '', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
              ),
              if (isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
                  decoration: BoxDecoration(
                    color: c.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Text('Mặc định', style: TextStyle(color: c.secondary, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(addr['phone'] ?? '', style: TextStyle(color: c.textSecondary, fontSize: 13)),
          const SizedBox(height: AppSpacing.xs),
          Text(addr['address'] ?? '', style: TextStyle(color: c.textMuted, fontSize: 12)),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              if (!isDefault)
                Pressable(
                  onTap: () {
                    setState(() => _defaultIndex = index);
                    _saveAddresses();
                  },
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      border: Border.all(color: c.secondary),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Text('Đặt mặc định', style: TextStyle(color: c.secondary, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ),
              const Spacer(),
              CircleIconButton(
                icon: Icons.edit_rounded,
                onTap: () => _addOrEditAddress(editIndex: index),
                size: 38,
                bordered: false,
                background: c.surfaceVariant,
                foreground: c.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              CircleIconButton(
                icon: Icons.delete_outline_rounded,
                onTap: () => _deleteAddress(index),
                size: 38,
                bordered: false,
                background: c.danger.withValues(alpha: 0.12),
                foreground: c.danger,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
