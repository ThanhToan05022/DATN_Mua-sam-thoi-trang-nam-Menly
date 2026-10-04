import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../cart/data/cart_model.dart';
import '../../../wishlist/presentation/providers/wishlist_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/user_avatar_view.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _showLogoutDialog = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().fetchProfile();
    });
  }

  void _confirmLogout() => setState(() => _showLogoutDialog = true);

  Future<void> _doLogout() async {
    setState(() => _showLogoutDialog = false);
    await context.read<AuthProvider>().logout();
    if (mounted) {
      context.read<CartProvider>().resetLocal();
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final authProvider = context.watch<AuthProvider>();
    final isLoggedIn = authProvider.isLoggedIn;
    final user = authProvider.user;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: c.background,
          appBar: AppBar(
            title: const Text('Tài khoản'),
            backgroundColor: c.background,
            foregroundColor: c.textPrimary,
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
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                    border: Border.all(color: c.border.withValues(alpha: 0.6)),
                    boxShadow: [
                      BoxShadow(color: c.shadow, blurRadius: 24, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Đăng xuất',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: c.textPrimary),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Bạn có chắc muốn đăng xuất khỏi tài khoản không?',
                        style: TextStyle(fontSize: 14, color: c.textMuted),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      Row(
                        children: [
                          Expanded(
                            child: SecondaryButton(
                              label: 'Huỷ',
                              height: 48,
                              onPressed: () =>
                                  setState(() => _showLogoutDialog = false),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: PrimaryButton(
                              label: 'Đăng xuất',
                              height: 48,
                              background: c.danger,
                              foreground: Colors.white,
                              onPressed: _doLogout,
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
    final c = AppColors.of(context);
    final favCount = context.watch<WishlistProvider>().favoriteCount;

    String roleLabel = 'Khách hàng';
    Color roleColor = c.secondary;
    if (user.isAdmin) {
      roleLabel = 'Quản trị viên (Admin)';
      roleColor = const Color(0xFFEF4444);
    } else if (user.isStaff) {
      roleLabel = 'Nhân viên vận hành';
      roleColor = const Color(0xFF3B82F6);
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl,
          MediaQuery.of(context).padding.bottom + 96),
      children: [
        // Avatar & info
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: () => context.push('/edit-profile'),
                child: UserAvatarView(
                  avatarUrl: user.avatarUrl,
                  fullName: user.fullName,
                  size: 84,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                user.fullName,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                user.email,
                style: TextStyle(fontSize: 13, color: c.textMuted),
              ),
              if (user.phone != null && user.phone!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.phone_outlined, size: 13, color: c.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      user.phone!,
                      style: TextStyle(fontSize: 12, color: c.textMuted),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              // Role Badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  border: Border.all(color: roleColor.withValues(alpha: 0.4)),
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
                    const SizedBox(width: AppSpacing.xs),
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
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.push('/edit-profile'),
                icon: const Icon(Icons.edit_outlined, size: 14),
                label: const Text(
                  'Chỉnh sửa hồ sơ',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryLight,
                  side: BorderSide(color: AppTheme.primaryLight.withOpacity(0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),

        _menuItem(
          icon: Icons.person_outline_rounded,
          label: 'Thông tin cá nhân',
          onTap: () => context.push('/edit-profile'),
        ),
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
          const SizedBox(height: AppSpacing.sm),
          Divider(color: c.border.withValues(alpha: 0.6)),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
            child: Text(
              user.isAdmin ? 'QUẢN TRỊ VIÊN' : 'VẬN HÀNH HỆ THỐNG',
              style: TextStyle(
                color: c.secondary,
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
            icon: Icons.notifications_outlined,
            label: 'Thông báo',
            onTap: () => context.push('/notifications')),
        _menuItem(
            icon: Icons.help_outline_rounded,
            label: 'Trợ giúp & Hỗ trợ',
            onTap: () => context.push('/help-support')),
        const SizedBox(height: AppSpacing.md),
        Divider(color: c.border.withValues(alpha: 0.6)),
        const SizedBox(height: AppSpacing.md),
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
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: c.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_outline_rounded,
                  size: 44, color: c.secondary),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Bạn chưa đăng nhập',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary)),
          const SizedBox(height: AppSpacing.sm),
          Text(
              'Đăng nhập để theo dõi đơn hàng, quản lý danh sách yêu thích và trải nghiệm mua sắm tốt hơn',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: c.textMuted, height: 1.5)),
          const SizedBox(height: AppSpacing.xxxl),
          PrimaryButton(
            label: 'Đăng nhập',
            onPressed: () => context.push('/login'),
          ),
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(
            label: 'Tạo tài khoản',
            onPressed: () => context.push('/register'),
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
    final c = AppColors.of(context);
    final accent = isRed ? c.danger : c.secondary;
    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: c.border.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(color: c.shadow, blurRadius: 18, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isRed ? c.danger.withValues(alpha: 0.12) : c.primarySoft,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isRed ? c.danger : c.textPrimary,
                ),
              ),
            ),
            if (badgeText != null)
              Container(
                margin: const EdgeInsets.only(right: AppSpacing.sm),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: c.danger,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
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
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: c.textMuted),
          ],
        ),
      ),
    );
  }
}
