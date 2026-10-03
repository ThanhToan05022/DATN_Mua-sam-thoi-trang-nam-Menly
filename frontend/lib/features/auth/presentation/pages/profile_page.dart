import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../cart/data/cart_model.dart';
import '../../../address/presentation/providers/address_provider.dart';
import '../../../wishlist/presentation/providers/wishlist_provider.dart';
import '../providers/auth_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _showLogoutDialog = false;
  bool _uploadingAvatar = false;
  bool _fetchedProfile = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  /// Lấy tên/SĐT/avatar mới nhất từ server (chỉ gọi 1 lần)
  Future<void> _loadProfile() async {
    if (_fetchedProfile) return;
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) return;
    _fetchedProfile = true;
    await auth.fetchProfile();
  }

  void _confirmLogout() => setState(() => _showLogoutDialog = true);

  /// Chọn ảnh từ thư viện hoặc chụp ảnh mới
  Future<void> _pickAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text(
                'Đổi ảnh đại diện',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library_rounded, color: AppTheme.primary),
              title: const Text('Chọn từ thư viện',
                  style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.primary),
              title: const Text('Chụp ảnh mới',
                  style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (bytes.length > 4 * 1024 * 1024) {
        _snack('Ảnh quá lớn, vui lòng chọn ảnh nhỏ hơn', isError: true);
        return;
      }

      setState(() => _uploadingAvatar = true);
      final ok = await context
          .read<AuthProvider>()
          .uploadAvatar('data:image/jpeg;base64,${base64Encode(bytes)}');

      if (!mounted) return;
      _snack(ok ? 'Đã cập nhật ảnh đại diện' : 'Không thể tải ảnh lên',
          isError: !ok);
    } catch (e) {
      if (mounted) _snack('Không thể chọn ảnh: $e', isError: true);
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  /// Hộp thoại sửa họ tên và số điện thoại
  Future<void> _openEditProfile() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final nameCtrl = TextEditingController(text: user.fullName);
    final phoneCtrl = TextEditingController(text: user.phone ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Sửa hồ sơ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Họ và tên',
                labelStyle: const TextStyle(color: AppTheme.textMuted),
                prefixIcon: const Icon(Icons.person_rounded,
                    color: AppTheme.textMuted, size: 20),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Số điện thoại',
                labelStyle: const TextStyle(color: AppTheme.textMuted),
                prefixIcon: const Icon(Icons.phone_rounded,
                    color: AppTheme.textMuted, size: 20),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ',
                style: TextStyle(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Lưu',
              style:
                  TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    // Đọc giá trị trước khi dispose controller
    final name = nameCtrl.text.trim();
    final phone = phoneCtrl.text.trim();
    nameCtrl.dispose();
    phoneCtrl.dispose();

    if (saved != true || !mounted) return;

    if (name.length < 2) {
      _snack('Vui lòng nhập họ tên hợp lệ', isError: true);
      return;
    }
    if (phone.isNotEmpty && phone.length < 9) {
      _snack('Số điện thoại không hợp lệ', isError: true);
      return;
    }

    final synced =
        await context.read<AuthProvider>().updateProfile(fullName: name, phone: phone);
    if (!mounted) return;
    _snack(synced ? 'Đã cập nhật hồ sơ' : 'Đã lưu tạm, không đồng bộ được lên máy chủ',
        isError: !synced);
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

  Future<void> _doLogout() async {
    setState(() => _showLogoutDialog = false);
    await context.read<AuthProvider>().logout();
    if (mounted) {
      context.read<CartProvider>().resetLocal();
      // Xoá cache địa chỉ để tài khoản sau không thấy dữ liệu của tài khoản này.
      context.read<AddressProvider>().resetLocal();
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isLoggedIn = authProvider.isLoggedIn;
    final user = authProvider.user;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppTheme.bg,
          appBar: AppBar(
            title: const Text('Tài khoản'),
            backgroundColor: AppTheme.bg,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: isLoggedIn && user != null
              ? _buildLoggedIn(user)
              : _buildGuest(),
        ),
        // Logout confirm overlay
        if (_showLogoutDialog)
          GestureDetector(
            onTap: () => setState(() => _showLogoutDialog = false),
            child: Container(
              color: Colors.black54,
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: () {}, // block tap-through
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.surface2),
                    boxShadow: const [
                      BoxShadow(color: Colors.black54, blurRadius: 30)
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Đăng xuất',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Bạn có chắc muốn đăng xuất khỏi tài khoản không?',
                        style: TextStyle(
                            fontSize: 14, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  setState(() => _showLogoutDialog = false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.textMuted,
                                side:
                                    const BorderSide(color: AppTheme.surface2),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Huỷ'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _doLogout,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.error,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: const Text('Đăng xuất',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoggedIn(AuthUser user) {
    final favCount = context.watch<WishlistProvider>().favoriteCount;

    String roleLabel = 'Khách hàng';
    Color roleColor = AppTheme.primary;
    if (user.isAdmin) {
      roleLabel = 'Quản trị viên (Admin)';
      roleColor = const Color(0xFFEF4444);
    } else if (user.isStaff) {
      roleLabel = 'Nhân viên vận hành';
      roleColor = const Color(0xFF3B82F6);
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Avatar & info
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: _uploadingAvatar ? null : _pickAvatar,
                child: Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [AppTheme.primary, AppTheme.primaryLight]),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: AppTheme.primary.withOpacity(0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6))
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                          ? Image.network(
                              user.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(
                                  user.fullName.isNotEmpty
                                      ? user.fullName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                user.fullName.isNotEmpty
                                    ? user.fullName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900),
                              ),
                            ),
                    ),
                    if (_uploadingAvatar)
                      Container(
                        width: 80,
                        height: 80,
                        color: Colors.black54,
                        child: const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    else
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt_rounded,
                              size: 13, color: Colors.black),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _openEditProfile,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Sửa hồ sơ',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        size: 15, color: AppTheme.primary),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                user.fullName,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                user.email,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textMuted),
              ),
              if (user.phone != null && user.phone!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.phone_rounded,
                        size: 12, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      user.phone!,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              // Role Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: roleColor.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      user.isAdmin
                          ? Icons.shield_rounded
                          : (user.isStaff
                              ? Icons.badge_rounded
                              : Icons.person_rounded),
                      size: 14,
                      color: roleColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      roleLabel,
                      style: TextStyle(
                        color: roleColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        _menuItem(
          icon: Icons.favorite_rounded,
          label: 'Sản phẩm yêu thích',
          badgeText: favCount > 0 ? '$favCount' : null,
          onTap: () => context.push('/wishlist'),
        ),
        _menuItem(
          icon: Icons.shopping_bag_outlined,
          label: 'Đơn hàng của tôi',
          onTap: () => context.push('/my-orders'),
        ),
        if (user.isAdmin || user.isStaff) ...[
          const SizedBox(height: 8),
          const Divider(color: AppTheme.surface2),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              user.isAdmin ? 'QUẢN TRỊ VIÊN' : 'VẬN HÀNH HỆ THỐNG',
              style: const TextStyle(
                color: AppTheme.primaryLight,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
          _menuItem(
            icon: Icons.admin_panel_settings_rounded,
            label: 'Quản lý đơn hàng (${user.isAdmin ? "Admin" : "Vận hành"})',
            badgeText: user.isAdmin ? 'Admin' : 'Staff',
            onTap: () => context.push('/admin/orders'),
          ),
        ],
        _menuItem(
            icon: Icons.location_on_outlined,
            label: 'Địa chỉ giao hàng',
            onTap: () => context.push('/shipping-address')),
        _menuItem(
            icon: Icons.lock_outline_rounded,
            label: 'Đổi mật khẩu',
            onTap: () => context.push('/change-password')),
        _menuItem(
            icon: Icons.notifications_outlined,
            label: 'Thông báo',
            onTap: () => context.push('/notifications')),
        _menuItem(
            icon: Icons.help_outline_rounded,
            label: 'Trợ giúp & Hỗ trợ',
            onTap: () => context.push('/help-support')),
        const SizedBox(height: 12),
        const Divider(color: AppTheme.surface2),
        const SizedBox(height: 12),
        _menuItem(
          icon: Icons.logout_rounded,
          label: 'Đăng xuất',
          onTap: _confirmLogout,
          isRed: true,
        ),
      ],
    );
  }

  Widget _buildGuest() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.person_outline_rounded,
              size: 80, color: AppTheme.textMuted),
          const SizedBox(height: 20),
          const Text('Bạn chưa đăng nhập',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 8),
          const Text(
              'Đăng nhập để theo dõi đơn hàng, quản lý danh sách yêu thích và trải nghiệm mua sắm tốt hơn',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppTheme.textMuted)),
          const SizedBox(height: 36),
          ElevatedButton(
            onPressed: () => context.push('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Đăng nhập',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: () => context.push('/register'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: const BorderSide(color: AppTheme.primary),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Tạo tài khoản',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    String? badgeText,
    bool isRed = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.surface2),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isRed ? AppTheme.error : AppTheme.primary, size: 20),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isRed ? AppTheme.error : Colors.white,
              ),
            ),
            const Spacer(),
            if (badgeText != null)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (!isRed)
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}
