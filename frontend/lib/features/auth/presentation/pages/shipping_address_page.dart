import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../address/data/address_model.dart';
import '../../../address/presentation/providers/address_provider.dart';

class ShippingAddressPage extends StatefulWidget {
  /// Địa chỉ được chọn sẽ được trả về cho màn hình gọi (ví dụ trang thanh toán)
  final bool selectable;
  final String? selectedId;

  const ShippingAddressPage({
    super.key,
    this.selectable = false,
    this.selectedId,
  });

  const ShippingAddressPage.selectable({
    super.key,
    this.selectable = true,
    this.selectedId,
  });

  @override
  State<ShippingAddressPage> createState() => _ShippingAddressPageState();
}

class _ShippingAddressPageState extends State<ShippingAddressPage> {
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<AddressProvider>()
          .fetchAddresses(forceRefresh: true);
    });
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
      ),
    );
  }

  Future<void> _openForm({ShippingAddress? existing}) async {
    final result = await showModalBottomSheet<ShippingAddress>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _AddressFormSheet(existing: existing),
      ),
    );

    if (result == null || !mounted) return;

    setState(() => _submitting = true);
    final provider = context.read<AddressProvider>();
    try {
      final ok = existing == null
          ? await provider.addAddress(result) != null
          : await provider.updateAddress(existing.id, result);
      if (!mounted) return;
      if (ok) {
        _snack(existing == null
            ? 'Đã thêm địa chỉ mới'
            : 'Đã cập nhật địa chỉ');
      } else {
        _snack('Không thể lưu địa chỉ. Vui lòng thử lại', isError: true);
      }
    } catch (e) {
      if (mounted) _snack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _confirmDelete(ShippingAddress address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Xoá địa chỉ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Bạn có chắc muốn xoá địa chỉ "${address.recipientName}"?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ', style: TextStyle(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Xoá',
              style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _submitting = true);
    try {
      final ok = await context.read<AddressProvider>().deleteAddress(address.id);
      if (!mounted) return;
      _snack(ok ? 'Đã xoá địa chỉ' : 'Không thể xoá địa chỉ', isError: !ok);
    } catch (e) {
      if (mounted) _snack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _setDefault(ShippingAddress address) async {
    setState(() => _submitting = true);
    try {
      final ok = await context.read<AddressProvider>().setDefault(address.id);
      if (!mounted) return;
      _snack(ok ? 'Đã đặt địa chỉ mặc định' : 'Không thể đặt mặc định',
          isError: !ok);
    } catch (e) {
      if (mounted) _snack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AddressProvider>();
    final state = provider.state;
    final addresses = provider.items;
    final isBusy = _submitting || state.isLoading;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        elevation: 0,
        title: const Text(
          'Địa chỉ giao hàng',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            onPressed: isBusy ? null : () => _openForm(),
            icon: const Icon(Icons.add_rounded, color: AppTheme.primary),
            tooltip: 'Thêm địa chỉ',
          ),
        ],
      ),
      body: isBusy && addresses.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : addresses.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: () => provider.fetchAddresses(forceRefresh: true),
                  color: AppTheme.primary,
                  backgroundColor: AppTheme.surface2,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: addresses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _buildAddressCard(
                      addresses[i],
                      isSelected: widget.selectable &&
                          widget.selectedId == addresses[i].id,
                    ),
                  ),
                ),
      floatingActionButton: addresses.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: isBusy ? null : () => _openForm(),
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Thêm địa chỉ',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppTheme.surface2,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(
                Icons.location_off_rounded,
                color: AppTheme.textMuted,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Chưa có địa chỉ nào',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Thêm địa chỉ giao hàng để thanh toán nhanh hơn',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Thêm địa chỉ',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(ShippingAddress addr, {bool isSelected = false}) {
    final borderColor = isSelected
        ? AppTheme.primary
        : (addr.isDefault
            ? AppTheme.primary.withOpacity(0.5)
            : AppTheme.surface2);

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primary.withOpacity(0.08) : AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.location_on_rounded,
                color: (isSelected || addr.isDefault)
                    ? AppTheme.primary
                    : AppTheme.textMuted,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  addr.recipientName.isEmpty
                      ? 'Chưa đặt tên'
                      : addr.recipientName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              if (addr.isDefault)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Mặc định',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          if (addr.phone.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.phone_rounded,
                    size: 13, color: AppTheme.textMuted),
                const SizedBox(width: 6),
                Text(
                  addr.phone,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
          if (addr.fullAddress.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.map_rounded, size: 13, color: AppTheme.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    addr.fullAddress,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (!addr.isDefault)
                GestureDetector(
                  onTap: _submitting ? null : () => _setDefault(addr),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.primary),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Đặt mặc định',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              const Spacer(),
              _iconAction(
                icon: Icons.edit_rounded,
                color: AppTheme.textSecondary,
                onTap: _submitting ? null : () => _openForm(existing: addr),
              ),
              const SizedBox(width: 6),
              _iconAction(
                icon: Icons.delete_outline_rounded,
                color: AppTheme.error,
                onTap: _submitting ? null : () => _confirmDelete(addr),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconAction({
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

/// Bottom sheet nhập / sửa địa chỉ giao hàng
class _AddressFormSheet extends StatefulWidget {
  final ShippingAddress? existing;

  const _AddressFormSheet({this.existing});

  @override
  State<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<_AddressFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _detailCtrl;
  late String _province;
  late String _district;
  late String _ward;
  late bool _isDefault;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.recipientName ?? '');
    _phoneCtrl = TextEditingController(text: e?.phone ?? '');
    _detailCtrl = TextEditingController(text: e?.detailAddress ?? '');
    _province = (e?.province.isNotEmpty ?? false) ? e!.province : VietnamRegions.provinces.first;
    _district = (e?.district.isNotEmpty ?? false) ? e!.district : VietnamRegions.districts.first;
    _ward = (e?.ward.isNotEmpty ?? false) ? e!.ward : VietnamRegions.wards.first;
    _isDefault = e?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _detailCtrl.dispose();
    super.dispose();
  }

  Future<void> _pick(
    String title,
    List<String> options,
    String current,
    ValueChanged<String> onSelected,
  ) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surface2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (_, i) {
                  final value = options[i];
                  final selected = value == current;
                  return ListTile(
                    onTap: () => Navigator.pop(ctx, value),
                    title: Text(
                      value,
                      style: TextStyle(
                        color: selected ? AppTheme.primary : Colors.white,
                        fontSize: 14,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                    trailing: selected
                        ? const Icon(Icons.check_rounded,
                            color: AppTheme.primary, size: 18)
                        : null,
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (picked != null) onSelected(picked);
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final detail = _detailCtrl.text.trim();

    if (name.length < 2) {
      _toast('Vui lòng nhập họ tên người nhận');
      return;
    }
    if (phone.length < 9) {
      _toast('Số điện thoại không hợp lệ');
      return;
    }
    if (detail.length < 3) {
      _toast('Vui lòng nhập địa chỉ chi tiết');
      return;
    }

    setState(() => _saving = true);
    Navigator.pop(
      context,
      ShippingAddress(
        id: widget.existing?.id ?? '',
        recipientName: name,
        phone: phone,
        province: _province,
        district: _district,
        ward: _ward,
        detailAddress: detail,
        isDefault: _isDefault,
        createdAt: widget.existing?.createdAt ?? '',
      ),
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            const SizedBox(height: 16),
            Text(
              isEdit ? 'Sửa địa chỉ' : 'Thêm địa chỉ mới',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            _field(_nameCtrl, 'Họ và tên người nhận', Icons.person_rounded),
            const SizedBox(height: 12),
            _field(
              _phoneCtrl,
              'Số điện thoại',
              Icons.phone_rounded,
              type: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _field(
              _detailCtrl,
              'Số nhà, đường, phố',
              Icons.home_rounded,
              lines: 2,
            ),
            const SizedBox(height: 12),
            _pickerField(
              'Tỉnh / Thành phố',
              _province,
              Icons.public_rounded,
              () => _pick(
                'Chọn tỉnh / thành phố',
                VietnamRegions.provinces,
                _province,
                (v) => setState(() => _province = v),
              ),
            ),
            const SizedBox(height: 12),
            _pickerField(
              'Quận / Huyện',
              _district,
              Icons.location_city_rounded,
              () => _pick(
                'Chọn quận / huyện',
                VietnamRegions.districts,
                _district,
                (v) => setState(() => _district = v),
              ),
            ),
            const SizedBox(height: 12),
            _pickerField(
              'Phường / Xã',
              _ward,
              Icons.architecture_rounded,
              () => _pick(
                'Chọn phường / xã',
                VietnamRegions.wards,
                _ward,
                (v) => setState(() => _ward = v),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Switch(
                  value: _isDefault,
                  activeThumbColor: AppTheme.primary,
                  onChanged: (v) => setState(() => _isDefault = v),
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Đặt làm địa chỉ mặc định',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                isEdit ? 'Cập nhật địa chỉ' : 'Thêm địa chỉ',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType type = TextInputType.text,
    int lines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        maxLines: lines,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
          prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _pickerField(
    String hint,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        decoration: BoxDecoration(
          color: AppTheme.surface2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Icon(icon, color: AppTheme.textMuted, size: 20),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hint,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
            const Icon(Icons.expand_more_rounded,
                color: AppTheme.textMuted, size: 20),
            const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }
}
