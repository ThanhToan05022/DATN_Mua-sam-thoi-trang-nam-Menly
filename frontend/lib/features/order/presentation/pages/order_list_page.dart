import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/order_model.dart';
import '../providers/order_provider.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  String _selectedFilter = 'all';

  final List<Map<String, String>> _statusTabs = const [
    {'id': 'all', 'label': 'Tất cả'},
    {'id': 'pending_payment', 'label': 'Chờ xác nhận'},
    {'id': 'processing', 'label': 'Đang xử lý'},
    {'id': 'shipping', 'label': 'Đang giao'},
    {'id': 'completed', 'label': 'Hoàn thành'},
    {'id': 'cancelled', 'label': 'Đã huỷ'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().fetchMyOrders(forceRefresh: true);
    });
  }

  List<Order> _filterOrders(List<Order> orders, String filter) {
    if (filter == 'all') return orders;
    if (filter == 'pending_payment') {
      return orders.where((o) => o.status == 'pending_payment' || o.status == 'pending').toList();
    }
    if (filter == 'processing') {
      return orders.where((o) => o.status == 'processing' || o.status == 'paid').toList();
    }
    if (filter == 'shipping') {
      return orders.where((o) => o.status == 'shipping').toList();
    }
    if (filter == 'completed') {
      return orders.where((o) => o.status == 'completed' || o.status == 'delivered').toList();
    }
    if (filter == 'cancelled') {
      return orders.where((o) => o.status == 'cancelled').toList();
    }
    return orders.where((o) => o.status == filter).toList();
  }

  void _showCancelDialog(BuildContext context, Order order) {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 26),
            SizedBox(width: 10),
            Text(
              'Huỷ đơn hàng',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn có chắc chắn muốn huỷ đơn hàng #${order.code}?',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: noteCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Nhập lý do huỷ (tùy chọn)...',
                hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                filled: true,
                fillColor: AppTheme.surface2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final reason = noteCtrl.text.trim().isNotEmpty
                  ? noteCtrl.text.trim()
                  : 'Khách hàng huỷ đơn';
              final success = await context.read<OrderProvider>().cancelOrder(
                order.id,
                reason: reason,
              );
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã huỷ đơn hàng thành công'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Không thể huỷ đơn hàng. Vui lòng thử lại sau'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Xác nhận huỷ', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final state = orderProvider.myOrdersState;
    final allOrders = state.data ?? [];
    final filtered = _filterOrders(allOrders, _selectedFilter);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Đơn hàng của tôi',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status Tabs
            SizedBox(
              height: 48,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                scrollDirection: Axis.horizontal,
                itemCount: _statusTabs.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final tab = _statusTabs[i];
                  final tabId = tab['id']!;
                  final isSelected = _selectedFilter == tabId;
                  final count = _filterOrders(allOrders, tabId).length;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = tabId),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppTheme.primaryGradient : null,
                        color: isSelected ? null : AppTheme.surface2,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : AppTheme.border,
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              tab['label']!,
                              style: TextStyle(
                                color: isSelected ? Colors.black : AppTheme.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (count > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.black.withOpacity(0.15)
                                      : AppTheme.border2,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$count',
                                  style: TextStyle(
                                    color: isSelected ? Colors.black : Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Orders list
            Expanded(
              child: state.isLoading && allOrders.isEmpty
                  ? _buildSkeletonList()
                  : state.isError && allOrders.isEmpty
                      ? _buildErrorView(state.message ?? 'Đã có lỗi xảy ra')
                      : filtered.isEmpty
                          ? _buildEmptyView()
                          : RefreshIndicator(
                              onRefresh: () => context
                                  .read<OrderProvider>()
                                  .fetchMyOrders(forceRefresh: true),
                              color: AppTheme.primary,
                              backgroundColor: AppTheme.surface2,
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                itemCount: filtered.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 14),
                                itemBuilder: (_, i) =>
                                    _buildOrderCard(filtered[i]),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    // Dùng chung quy tắc với backend: chỉ chặn khi đang giao/hoàn thành/đã huỷ.
    final canCancel = order.canCancel;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => context.push('/order-detail/${order.id.isNotEmpty ? order.id : order.code}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: order.status == 'cancelled'
                ? AppTheme.error.withOpacity(0.3)
                : AppTheme.border,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded,
                        color: AppTheme.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      order.code,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: order.statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: order.statusColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    order.statusLabel,
                    style: TextStyle(
                      color: order.statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              order.formattedDate,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: AppTheme.surface2, height: 1),
            ),

            // Items Preview
            if (order.items.isNotEmpty) ...[
              ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${item.productName}${item.size.isNotEmpty ? ' (${item.size}, ${item.color})' : ''}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          'x${item.quantity}',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],

            // Ghi chú huỷ hoặc lý do
            if (order.status == 'cancelled' && order.note != null && order.note!.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(top: 4, bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.error.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppTheme.error, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Lý do: ${order.note}',
                        style: const TextStyle(color: AppTheme.error, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(color: AppTheme.surface2, height: 1),
            ),

            // Footer: Total & Payment
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      order.paymentMethod == 'vnpay'
                          ? Icons.credit_card_rounded
                          : Icons.local_shipping_outlined,
                      color: AppTheme.textMuted,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      order.paymentMethod == 'vnpay'
                          ? 'VNPay'
                          : 'Thanh toán COD',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text(
                      'Tổng tiền: ',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      order.formattedTotal,
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Action Button: Huỷ đơn hàng nếu đơn còn có thể huỷ
            if (canCancel) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showCancelDialog(context, order),
                  icon: const Icon(Icons.cancel_outlined, size: 16, color: AppTheme.error),
                  label: const Text(
                    'Huỷ đơn hàng',
                    style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.error.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, _) => Container(
        height: 140,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.border),
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.surface2,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.border),
            ),
            child: const Icon(Icons.shopping_bag_outlined,
                color: AppTheme.textMuted, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'all'
                ? 'Chưa có đơn hàng nào'
                : 'Không có đơn hàng ${_statusTabs.firstWhere((t) => t['id'] == _selectedFilter)['label']!.toLowerCase()}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Khám phá các sản phẩm thời trang và đặt hàng ngay!',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.go('/products'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Mua sắm ngay',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppTheme.error, size: 48),
            const SizedBox(height: 12),
            Text(msg,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context
                  .read<OrderProvider>()
                  .fetchMyOrders(forceRefresh: true),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
