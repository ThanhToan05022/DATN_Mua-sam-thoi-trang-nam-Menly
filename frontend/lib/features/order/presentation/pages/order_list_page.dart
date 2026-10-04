import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/state_views.dart';
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
    final c = AppColors.of(context);
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: c.danger, size: 26),
            const SizedBox(width: 10),
            Text(
              'Huỷ đơn hàng',
              style: TextStyle(
                color: c.textPrimary,
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
              style: TextStyle(color: c.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: noteCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Nhập lý do huỷ (tùy chọn)...',
                hintStyle: TextStyle(color: c.textMuted, fontSize: 13),
                filled: true,
                fillColor: c.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(color: c.textPrimary, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Đóng', style: TextStyle(color: c.textMuted)),
          ),
          PrimaryButton(
            label: 'Xác nhận huỷ',
            expanded: false,
            height: 44,
            background: c.danger,
            foreground: c.onPrimary,
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
                    SnackBar(
                      content: const Text('Đã huỷ đơn hàng thành công'),
                      backgroundColor: c.success,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Không thể huỷ đơn hàng. Vui lòng thử lại sau'),
                      backgroundColor: c.danger,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final orderProvider = context.watch<OrderProvider>();
    final state = orderProvider.myOrdersState;
    final allOrders = state.data ?? [];
    final filtered = _filterOrders(allOrders, _selectedFilter);

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: c.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Đơn hàng của tôi',
          style: TextStyle(
            color: c.textPrimary,
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
                        color: isSelected ? c.primary : c.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : c.border,
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              tab['label']!,
                              style: TextStyle(
                                color: isSelected ? c.onPrimary : c.textSecondary,
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
                                      ? c.onPrimary.withValues(alpha: 0.2)
                                      : c.border,
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radiusPill),
                                ),
                                child: Text(
                                  '$count',
                                  style: TextStyle(
                                    color: isSelected ? c.onPrimary : c.textPrimary,
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
                              color: c.secondary,
                              backgroundColor: c.surfaceVariant,
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
    final c = AppColors.of(context);
    final canCancel = order.status == 'pending_payment' ||
        order.status == 'pending' ||
        order.status == 'processing';

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: order.status == 'cancelled'
              ? c.danger.withValues(alpha: 0.3)
              : c.border.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: c.shadow,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.receipt_long_rounded,
                      color: c.secondary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    order.code,
                    style: TextStyle(
                      color: c.textPrimary,
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
                  color: order.statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: order.statusColor.withValues(alpha: 0.4)),
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
            style: TextStyle(color: c.textMuted, fontSize: 12),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: c.surfaceVariant, height: 1),
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
                        decoration: BoxDecoration(
                          color: c.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${item.productName}${item.size.isNotEmpty ? ' (${item.size}, ${item.color})' : ''}',
                          style: TextStyle(
                            color: c.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'x${item.quantity}',
                        style: TextStyle(
                          color: c.textMuted,
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
                color: c.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(color: c.danger.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: c.danger, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Lý do: ${order.note}',
                      style: TextStyle(color: c.danger, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: c.surfaceVariant, height: 1),
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
                    color: c.textMuted,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    order.paymentMethod == 'vnpay'
                        ? 'VNPay'
                        : 'Thanh toán COD',
                    style: TextStyle(
                      color: c.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    'Tổng tiền: ',
                    style: TextStyle(
                      color: c.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    order.formattedTotal,
                    style: TextStyle(
                      color: c.secondary,
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
            const SizedBox(height: AppSpacing.md),
            SecondaryButton(
              label: 'Huỷ đơn hàng',
              icon: Icons.cancel_outlined,
              height: 46,
              foreground: AppColors.of(context).danger,
              onPressed: () => _showCancelDialog(context, order),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSkeletonList() {
    final c = AppColors.of(context);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, _) => Container(
        height: 140,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: c.border.withValues(alpha: 0.6)),
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return StatusView(
      icon: Icons.shopping_bag_outlined,
      title: _selectedFilter == 'all'
          ? 'Chưa có đơn hàng nào'
          : 'Không có đơn hàng ${_statusTabs.firstWhere((t) => t['id'] == _selectedFilter)['label']!.toLowerCase()}',
      message: 'Khám phá các sản phẩm thời trang và đặt hàng ngay!',
      actionLabel: 'Mua sắm ngay',
      onAction: () => context.go('/products'),
    );
  }

  Widget _buildErrorView(String msg) {
    return StatusView(
      icon: Icons.error_outline_rounded,
      title: 'Không tải được đơn hàng',
      message: msg,
      danger: true,
      actionLabel: 'Thử lại',
      onAction: () =>
          context.read<OrderProvider>().fetchMyOrders(forceRefresh: true),
    );
  }
}
