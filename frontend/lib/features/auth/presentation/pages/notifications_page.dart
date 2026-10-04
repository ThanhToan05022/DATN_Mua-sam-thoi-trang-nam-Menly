import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../core/widgets/state_views.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('notifications');
    if (raw != null) {
      _notifications = List<Map<String, dynamic>>.from(jsonDecode(raw));
    } else {
      // Tạo thông báo mẫu ban đầu
      _notifications = [
        {
          'id': '1',
          'title': 'Chào mừng bạn đến với Menly!',
          'body': 'Khám phá bộ sưu tập thời trang nam mới nhất với nhiều ưu đãi hấp dẫn.',
          'type': 'promo',
          'read': false,
          'createdAt': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
        },
        {
          'id': '2',
          'title': 'Giảm giá 20% cho đơn hàng đầu tiên',
          'body': 'Sử dụng mã WELCOME20 để nhận ưu đãi giảm 20% cho đơn hàng đầu tiên của bạn.',
          'type': 'promo',
          'read': false,
          'createdAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        },
        {
          'id': '3',
          'title': 'Bộ sưu tập Thu Đông 2026',
          'body': 'Các mẫu áo khoác, áo len và phụ kiện mùa đông đã có mặt. Mua ngay!',
          'type': 'news',
          'read': true,
          'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        },
      ];
      _saveNotifications();
    }
    setState(() => _loading = false);
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notifications', jsonEncode(_notifications));
  }

  void _markAsRead(int index) {
    if (!_notifications[index]['read']) {
      setState(() => _notifications[index]['read'] = true);
      _saveNotifications();
    }
  }

  void _markAllRead() {
    setState(() {
      for (var n in _notifications) {
        n['read'] = true;
      }
    });
    _saveNotifications();
  }

  void _deleteNotification(int index) {
    setState(() => _notifications.removeAt(index));
    _saveNotifications();
  }

  void _clearAll() {
    final c = AppColors.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        title: Text('Xoá tất cả', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w700)),
        content: Text('Bạn có chắc muốn xoá tất cả thông báo?', style: TextStyle(color: c.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Huỷ', style: TextStyle(color: c.textMuted))),
          TextButton(
            onPressed: () {
              setState(() => _notifications.clear());
              _saveNotifications();
              Navigator.pop(ctx);
            },
            child: Text('Xoá tất cả', style: TextStyle(color: c.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  int get _unreadCount => _notifications.where((n) => n['read'] != true).length;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: const Text('Thông báo'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => context.pop()),
        actions: [
          if (_notifications.isNotEmpty) ...[
            if (_unreadCount > 0)
              IconButton(
                icon: Icon(Icons.done_all_rounded, color: c.secondary, size: 22),
                onPressed: _markAllRead,
                tooltip: 'Đánh dấu tất cả đã đọc',
              ),
            IconButton(
              icon: Icon(Icons.delete_sweep_rounded, color: c.textMuted, size: 22),
              onPressed: _clearAll,
              tooltip: 'Xoá tất cả',
            ),
          ],
        ],
      ),
      body: _loading
          ? const LoadingView()
          : _notifications.isEmpty
              ? const StatusView(
                  icon: Icons.notifications_off_outlined,
                  title: 'Không có thông báo nào',
                  message: 'Các thông báo và ưu đãi mới sẽ xuất hiện ở đây.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: _notifications.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, i) => _notifCard(i),
                ),
    );
  }

  Widget _notifCard(int index) {
    final c = AppColors.of(context);
    final n = _notifications[index];
    final isRead = n['read'] == true;
    final type = n['type'] ?? 'general';

    IconData icon;
    Color iconColor;
    switch (type) {
      case 'promo':
        icon = Icons.local_offer_rounded;
        iconColor = c.secondary;
        break;
      case 'order':
        icon = Icons.shopping_bag_rounded;
        iconColor = c.secondary;
        break;
      case 'news':
        icon = Icons.new_releases_rounded;
        iconColor = c.success;
        break;
      default:
        icon = Icons.notifications_rounded;
        iconColor = c.textSecondary;
    }

    return Dismissible(
      key: Key(n['id'] ?? index.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteNotification(index),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        decoration: BoxDecoration(
          color: c.danger.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: Icon(Icons.delete_rounded, color: c.danger, size: 22),
      ),
      child: Pressable(
        onTap: () => _markAsRead(index),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isRead ? c.surface : c.surfaceVariant,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
                color: isRead
                    ? c.border.withValues(alpha: 0.6)
                    : c.secondary.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                  color: c.shadow, blurRadius: 16, offset: const Offset(0, 6)),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(n['title'] ?? '',
                              style: TextStyle(
                                color: c.textPrimary,
                                fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                                fontSize: 13,
                              )),
                        ),
                        if (!isRead)
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(color: c.secondary, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(n['body'] ?? '',
                        style: TextStyle(color: c.textMuted, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Text(_timeAgo(n['createdAt'] ?? ''),
                        style: TextStyle(color: c.textMuted, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(String iso) {
    try {
      final d = DateTime.parse(iso);
      final diff = DateTime.now().difference(d);
      if (diff.inMinutes < 1) return 'Vừa xong';
      if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
      if (diff.inHours < 24) return '${diff.inHours} giờ trước';
      if (diff.inDays < 7) return '${diff.inDays} ngày trước';
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return '';
    }
  }
}
