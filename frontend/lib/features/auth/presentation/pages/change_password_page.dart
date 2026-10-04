import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_buttons.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});
  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _showSuccess = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String? _validatePassword(String pass) {
    if (pass.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
    if (!RegExp(r'[A-Z]').hasMatch(pass)) return 'Cần ít nhất 1 chữ hoa';
    if (!RegExp(r'[0-9]').hasMatch(pass)) return 'Cần ít nhất 1 chữ số';
    return null;
  }

  Future<void> _changePassword() async {
    if (_currentCtrl.text.isEmpty) {
      _snack('Vui lòng nhập mật khẩu hiện tại');
      return;
    }
    final validateErr = _validatePassword(_newCtrl.text);
    if (validateErr != null) {
      _snack(validateErr);
      return;
    }
    if (_newCtrl.text != _confirmCtrl.text) {
      _snack('Mật khẩu xác nhận không khớp');
      return;
    }
    if (_currentCtrl.text == _newCtrl.text) {
      _snack('Mật khẩu mới phải khác mật khẩu hiện tại');
      return;
    }

    setState(() => _loading = true);
    try {
      final res = await DioClient.instance.dio.post(
        '/profile/change-password',
        data: {
          'currentPassword': _currentCtrl.text,
          'newPassword': _newCtrl.text,
        },
      );
      if (res.statusCode == 200) {
        setState(() => _showSuccess = true);
        _currentCtrl.clear();
        _newCtrl.clear();
        _confirmCtrl.clear();
      } else {
        _snack('Đổi mật khẩu thất bại');
      }
    } catch (e) {
      String msg = 'Đổi mật khẩu thất bại';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          msg = data['message'].toString();
        } else if (data is Map && data['error'] != null) {
          final err = data['error'];
          msg = (err is Map ? err['message'] : err).toString();
        } else if (e.message != null && e.message!.isNotEmpty) {
          msg = e.message!;
        }
      } else {
        msg = e.toString();
      }
      _snack(msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    final c = AppColors.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: c.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: const Text('Đổi mật khẩu'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Success message
            if (_showSuccess) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: c.success, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Đổi mật khẩu thành công!',
                          style: TextStyle(color: c.success, fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _showSuccess = false),
                      child: Icon(Icons.close_rounded, color: c.success, size: 18),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Security icon
            Center(
              child: Container(
                width: 70, height: 70,
                decoration: BoxDecoration(
                  color: c.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock_outline_rounded, color: c.secondary, size: 32),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text('Bảo mật tài khoản',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.textPrimary)),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text('Đổi mật khẩu để bảo vệ tài khoản của bạn',
                  style: TextStyle(fontSize: 13, color: c.textMuted), textAlign: TextAlign.center),
            ),
            const SizedBox(height: 32),

            // Form
            _label('Mật khẩu hiện tại'),
            const SizedBox(height: 8),
            _passwordField(_currentCtrl, 'Nhập mật khẩu hiện tại', _obscureCurrent,
                () => setState(() => _obscureCurrent = !_obscureCurrent)),
            const SizedBox(height: 18),

            _label('Mật khẩu mới'),
            const SizedBox(height: 8),
            _passwordField(_newCtrl, 'Nhập mật khẩu mới', _obscureNew,
                () => setState(() => _obscureNew = !_obscureNew)),
            const SizedBox(height: 8),
            // Password requirements
            _requirement('Tối thiểu 6 ký tự', _newCtrl.text.length >= 6),
            _requirement('Ít nhất 1 chữ hoa', RegExp(r'[A-Z]').hasMatch(_newCtrl.text)),
            _requirement('Ít nhất 1 chữ số', RegExp(r'[0-9]').hasMatch(_newCtrl.text)),
            const SizedBox(height: 18),

            _label('Xác nhận mật khẩu mới'),
            const SizedBox(height: 8),
            _passwordField(_confirmCtrl, 'Nhập lại mật khẩu mới', _obscureConfirm,
                () => setState(() => _obscureConfirm = !_obscureConfirm)),
            if (_confirmCtrl.text.isNotEmpty && _confirmCtrl.text != _newCtrl.text) ...[
              const SizedBox(height: 6),
              Text('Mật khẩu không khớp', style: TextStyle(color: c.danger, fontSize: 12)),
            ],
            const SizedBox(height: 32),

            // Button
            PrimaryButton(
              label: 'Đổi mật khẩu',
              loading: _loading,
              onPressed: _loading ? null : _changePassword,
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    final c = AppColors.of(context);
    return Text(text,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textSecondary));
  }

  Widget _passwordField(TextEditingController ctrl, String hint, bool obscure, VoidCallback toggleObscure) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.surfaceVariant),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        onChanged: (_) => setState(() {}),
        style: TextStyle(color: c.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: c.textMuted, fontSize: 14),
          prefixIcon: Icon(Icons.lock_outline_rounded, color: c.textMuted, size: 20),
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: c.textMuted, size: 20),
            onPressed: toggleObscure,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _requirement(String text, bool met) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(met ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: met ? c.success : c.textMuted, size: 14),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: met ? c.success : c.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}
