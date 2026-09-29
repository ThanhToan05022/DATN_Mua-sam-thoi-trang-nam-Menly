import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/theme/app_theme.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});
  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<dynamic> _orders = [];
  bool _loading = true;
  String? _error;

  final _tabs = ['Tất cả', 'Chờ xử lý', 'Đang giao', 'Hoàn thành', 'Đã huỷ'];
  final _statusMap = {
    'Tất cả': null,
    'Chờ xử lý': 'pending',
    'Đang giao': 'shipping',
    'Hoàn thành': 'delivered',
    'Đã huỷ': 'cancelled',
  };

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _fetchOrders();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    setState(() { _loading = true; _error = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? '';
      final res = await http.get(
        Uri.parse('${ApiConfig.apiBase}/orders?limit=50'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        setState(() {
          _orders = body['data'] ?? body['orders'] ?? (body is List ? body : []);
          _loading = false;
        });
      } else {
        setState(() { _error = 'Không thể tải đơn hàng (${res.statusCode})'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Lỗi kết nối: $e'; _loading = false; });
    }
  }

  List<dynamic> _filteredOrders(String tab) {
    final status = _statusMap[tab];
    if (status == null) return _orders;
    return _orders.where((o) => o['status'] == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Đơn hàng của tôi'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => context.pop()),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          tabAlignment: TabAlignment.start,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabCtrl,
                  children: _tabs.map((tab) => _buildOrderList(_filteredOrders(tab))).toList(),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 48),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: AppTheme.textMuted, fontSize: 14), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchOrders,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Thử lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<dynamic> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: AppTheme.textMuted.withOpacity(0.4)),
            const SizedBox(height: 12),
            const Text('Chưa có đơn hàng nào', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _fetchOrders,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _orderCard(orders[i]),
      ),
    );
  }

  Widget _orderCard(Map<String, dynamic> order) {
    final code = order['code'] ?? order['id']?.toString().substring(0, 8) ?? '---';
    final status = order['status'] ?? 'pending';
    final total = order['totalAmount'] ?? order['total'] ?? 0;
    final createdAt = order['createdAt'] ?? '';
    final items = order['items'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.surface2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: code + status
          Row(
            children: [
              const Icon(Icons.receipt_outlined, size: 16, color: AppTheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text('#$code', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
              ),
              _statusBadge(status),
            ],
          ),
          if (createdAt.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(_formatDate(createdAt), style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          ],
          const Divider(color: AppTheme.surface2, height: 20),
          // Items preview
          ...items.take(3).map<Widget>((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${item['productName'] ?? 'Sản phẩm'} ${item['size'] != null ? '(${item['size']})' : ''} x${item['quantity'] ?? 1}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          )),
          if (items.length > 3)
            Text('... và ${items.length - 3} sản phẩm khác', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          const SizedBox(height: 8),
          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${items.length} sản phẩm', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              Text('${_fmt(total is int ? total : (total as num).toInt())} đ',
                  style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    String text;
    switch (status) {
      case 'pending':
      case 'processing':
        color = AppTheme.warning;
        text = 'Chờ xử lý';
        break;
      case 'shipping':
        color = AppTheme.info;
        text = 'Đang giao';
        break;
      case 'delivered':
        color = AppTheme.success;
        text = 'Hoàn thành';
        break;
      case 'cancelled':
        color = AppTheme.error;
        text = 'Đã huỷ';
        break;
      default:
        color = AppTheme.textMuted;
        text = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11)),
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
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
}
