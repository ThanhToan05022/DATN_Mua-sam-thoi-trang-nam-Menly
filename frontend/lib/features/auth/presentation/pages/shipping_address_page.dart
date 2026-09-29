import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';

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
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.surface2, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Text(isEdit ? 'Sửa địa chỉ' : 'Thêm địa chỉ mới',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 20),
              _buildField(nameCtrl, 'Họ và tên', Icons.person_rounded),
              const SizedBox(height: 12),
              _buildField(phoneCtrl, 'Số điện thoại', Icons.phone_rounded, type: TextInputType.phone),
              const SizedBox(height: 12),
              _buildField(addressCtrl, 'Địa chỉ chi tiết', Icons.location_on_rounded, lines: 2),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty || addressCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin'), backgroundColor: AppTheme.error),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(isEdit ? 'Cập nhật' : 'Thêm địa chỉ',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteAddress(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xoá địa chỉ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: const Text('Bạn có chắc muốn xoá địa chỉ này?', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ', style: TextStyle(color: AppTheme.textMuted))),
          TextButton(
            onPressed: () {
              setState(() {
                _addresses.removeAt(index);
                if (_defaultIndex >= _addresses.length) _defaultIndex = _addresses.isEmpty ? 0 : _addresses.length - 1;
              });
              _saveAddresses();
              Navigator.pop(ctx);
            },
            child: const Text('Xoá', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint, IconData icon, {TextInputType type = TextInputType.text, int lines = 1}) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Địa chỉ giao hàng'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => context.pop()),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppTheme.primary),
            onPressed: () => _addOrEditAddress(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _addresses.isEmpty
              ? _buildEmpty()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _addresses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _addressCard(i),
                ),
      floatingActionButton: _addresses.isEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _addOrEditAddress(),
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Thêm địa chỉ', style: TextStyle(fontWeight: FontWeight.w700)),
            )
          : null,
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_off_rounded, size: 64, color: AppTheme.textMuted.withOpacity(0.4)),
          const SizedBox(height: 12),
          const Text('Chưa có địa chỉ nào', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
          const SizedBox(height: 6),
          const Text('Thêm địa chỉ giao hàng để mua sắm nhanh hơn', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _addressCard(int index) {
    final addr = _addresses[index];
    final isDefault = index == _defaultIndex;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDefault ? AppTheme.primary.withOpacity(0.5) : AppTheme.surface2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_rounded, color: isDefault ? AppTheme.primary : AppTheme.textMuted, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(addr['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
              ),
              if (isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Mặc định', style: TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(addr['phone'] ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 4),
          Text(addr['address'] ?? '', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          const SizedBox(height: 10),
          Row(
            children: [
              if (!isDefault)
                GestureDetector(
                  onTap: () {
                    setState(() => _defaultIndex = index);
                    _saveAddresses();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.primary),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Đặt mặc định', style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ),
              const Spacer(),
              GestureDetector(
                onTap: () => _addOrEditAddress(editIndex: index),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.edit_rounded, color: AppTheme.textSecondary, size: 18),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _deleteAddress(index),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
