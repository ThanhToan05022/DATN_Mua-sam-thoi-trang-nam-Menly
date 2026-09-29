import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _name = '';
  String _email = '';
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';
    setState(() {
      _name = prefs.getString('userName') ?? '';
      _email = prefs.getString('userEmail') ?? '';
      _isLoggedIn = token.isNotEmpty;
    });
  }

  bool _showLogoutDialog = false;

  void _confirmLogout() => setState(() => _showLogoutDialog = true);

  Future<void> _doLogout() async {
    setState(() => _showLogoutDialog = false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('userName');
    await prefs.remove('userEmail');
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
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
          body: _isLoggedIn ? _buildLoggedIn() : _buildGuest(),
        ),
        // Logout confirm overlay (thay showDialog để tránh GoRouter conflict)
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
                    boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 30)],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Đăng xuất',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                      const SizedBox(height: 10),
                      const Text('Bạn có chắc muốn đăng xuất không?',
                          style: TextStyle(fontSize: 14, color: AppTheme.textMuted)),
                      const SizedBox(height: 24),
                      Row(children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => _showLogoutDialog = false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textMuted,
                              side: BorderSide(color: AppTheme.surface2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoggedIn() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Avatar & info
        Center(
          child: Column(children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: Center(
                child: Text(
                  _name.isNotEmpty ? _name[0].toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(_name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 4),
            Text(_email, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
          ]),
        ),
        const SizedBox(height: 32),

        // Menu items
        _menuItem(icon: Icons.shopping_bag_outlined, label: 'Đơn hàng của tôi', onTap: () => context.push('/my-orders')),
        _menuItem(icon: Icons.location_on_outlined, label: 'Địa chỉ giao hàng', onTap: () => context.push('/shipping-address')),
        _menuItem(icon: Icons.lock_outline_rounded, label: 'Đổi mật khẩu', onTap: () => context.push('/change-password')),
        _menuItem(icon: Icons.notifications_outlined, label: 'Thông báo', onTap: () => context.push('/notifications')),
        _menuItem(icon: Icons.help_outline_rounded, label: 'Trợ giúp & Hỗ trợ', onTap: () => context.push('/help-support')),
        const SizedBox(height: 12),
        const Divider(color: AppTheme.surface2),
        const SizedBox(height: 12),
        _menuItem(icon: Icons.logout_rounded, label: 'Đăng xuất', onTap: _confirmLogout, isRed: true),
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
          const Icon(Icons.person_outline_rounded, size: 80, color: AppTheme.textMuted),
          const SizedBox(height: 20),
          const Text('Bạn chưa đăng nhập', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 8),
          const Text('Đăng nhập để theo dõi đơn hàng và trải nghiệm mua sắm tốt hơn', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppTheme.textMuted)),
          const SizedBox(height: 36),
          ElevatedButton(
            onPressed: () => context.push('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Đăng nhập', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: () => context.push('/register'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: const BorderSide(color: AppTheme.primary),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Tạo tài khoản', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _menuItem({required IconData icon, required String label, required VoidCallback onTap, bool isRed = false}) {
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
        child: Row(children: [
          Icon(icon, color: isRed ? AppTheme.error : AppTheme.primary, size: 20),
          const SizedBox(width: 14),
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isRed ? AppTheme.error : Colors.white)),
          const Spacer(),
          if (!isRed) Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
        ]),
      ),
    );
  }
}
