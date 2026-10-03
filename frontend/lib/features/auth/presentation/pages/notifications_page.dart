import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';

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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xoá tất cả', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: const Text('Bạn có chắc muốn xoá tất cả thông báo?', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ', style: TextStyle(color: AppTheme.textMuted))),
          TextButton(
            onPressed: () {
              setState(() => _notifications.clear());
              _saveNotifications();
              Navigator.pop(ctx);
            },
            child: const Text('Xoá tất cả', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  int get _unreadCount => _notifications.where((n) => n['read'] != true).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Thông báo'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => context.pop()),
        actions: [
          if (_notifications.isNotEmpty) ...[
            if (_unreadCount > 0)
              IconButton(
                icon: const Icon(Icons.done_all_rounded, color: AppTheme.primary, size: 22),
                onPressed: _markAllRead,
                tooltip: 'Đánh dấu tất cả đã đọc',
              ),
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: AppTheme.textMuted, size: 22),
              onPressed: _clearAll,
              tooltip: 'Xoá tất cả',
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _notifications.isEmpty
              ? _buildEmpty()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _notifCard(i),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_off_outlined, size: 64, color: AppTheme.textMuted.withOpacity(0.4)),
          const SizedBox(height: 12),
          const Text('Không có thông báo nào', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _notifCard(int index) {
    final n = _notifications[index];
    final isRead = n['read'] == true;
    final type = n['type'] ?? 'general';

    IconData icon;
    Color iconColor;
    switch (type) {
      case 'promo':
        icon = Icons.local_offer_rounded;
        iconColor = AppTheme.primary;
        break;
      case 'order':
        icon = Icons.shopping_bag_rounded;
        iconColor = AppTheme.info;
        break;
      case 'news':
        icon = Icons.new_releases_rounded;
        iconColor = AppTheme.success;
        break;
      default:
        icon = Icons.notifications_rounded;
        iconColor = AppTheme.textSecondary;
    }

    return Dismissible(
      key: Key(n['id'] ?? index.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteNotification(index),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.error.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_rounded, color: AppTheme.error, size: 22),
      ),
      child: GestureDetector(
        onTap: () => _markAsRead(index),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isRead ? AppTheme.surface : AppTheme.surface2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isRead ? AppTheme.surface2 : AppTheme.primary.withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(n['title'] ?? '',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                                fontSize: 13,
                              )),
                        ),
                        if (!isRead)
                          Container(
                            width: 8, height: 8,
                            decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(n['body'] ?? '',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Text(_timeAgo(n['createdAt'] ?? ''),
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
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
