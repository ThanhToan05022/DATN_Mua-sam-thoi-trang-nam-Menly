import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/order_model.dart';
import '../providers/order_provider.dart';

class AdminOrderManagementPage extends StatefulWidget {
  const AdminOrderManagementPage({super.key});

  @override
  State<AdminOrderManagementPage> createState() =>
      _AdminOrderManagementPageState();
}

class _AdminOrderManagementPageState extends State<AdminOrderManagementPage> {
  String _selectedStatus = 'all';

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
      context.read<OrderProvider>().fetchAdminOrders(forceRefresh: true);
    });
  }

  void _onSelectTab(String status) {
    setState(() => _selectedStatus = status);
  }

  List<Order> _getFilteredOrders(List<Order> orders) {
    if (_selectedStatus == 'all') return orders;
    return orders.where((o) => o.status == _selectedStatus).toList();
  }

  void _showUpdateStatusSheet(Order order) {
    final c = AppColors.of(context);
    if (order.status == 'cancelled') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '⚠️ Đơn hàng đã ở trạng thái ĐÃ HUỶ, không thể chuyển sang trạng thái khác.',
          ),
          backgroundColor: c.danger,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
      ),
      builder: (ctx) {
        final options = [
          {
            'id': 'pending_payment',
            'label': 'Chờ xác nhận',
            'color': const Color(0xFFF59E0B),
          },
          {
            'id': 'processing',
            'label': 'Đang xử lý đóng gói',
            'color': const Color(0xFF8B5CF6),
          },
          {
            'id': 'shipping',
            'label': 'Đang giao hàng',
            'color': const Color(0xFF06B6D4),
          },
          {
            'id': 'completed',
            'label': 'Giao hàng thành công',
            'color': const Color(0xFF10B981),
          },
          {
            'id': 'cancelled',
            'label': 'Huỷ đơn hàng',
            'color': const Color(0xFFEF4444),
          },
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: c.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Cập nhật trạng thái: ${order.code}',
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                ...options.map((opt) {
                  final isCurrent = order.status == opt['id'];
                  final optColor = opt['color'] as Color;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      onTap: isCurrent
                          ? null
                          : () async {
                              Navigator.of(ctx).pop();
                              final success = await context
                                  .read<OrderProvider>()
                                  .updateOrderStatus(
                                    order.id,
                                    opt['id'] as String,
                                  );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? '✅ Đã cập nhật trạng thái đơn ${order.code}'
                                          : '❌ Cập nhật thất bại. Đơn hàng có thể đã huỷ hoặc không hợp lệ.',
                                    ),
                                    backgroundColor: success
                                        ? c.success
                                        : c.danger,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? optColor.withValues(alpha: 0.15)
                              : c.surfaceVariant,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          border: Border.all(
                            color: isCurrent ? optColor : c.border,
                            width: isCurrent ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: optColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  opt['label'] as String,
                                  style: TextStyle(
                                    color: c.textPrimary,
                                    fontSize: 14,
                                    fontWeight: isCurrent
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            if (isCurrent)
                              Icon(
                                Icons.check_circle_rounded,
                                color: c.secondary,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final auth = context.watch<AuthProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final state = orderProvider.adminOrdersState;
    final allOrders = state.data ?? [];
    final filtered = _getFilteredOrders(allOrders);

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: c.textPrimary,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quản lý đơn hàng',
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              auth.user?.isAdmin == true
                  ? 'Quyền Quản trị viên (Toàn quyền)'
                  : 'Quyền Nhân viên (Vận hành)',
              style: TextStyle(
                color: auth.user?.isAdmin == true
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF3B82F6),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: c.textPrimary),
            onPressed: () => context.read<OrderProvider>().fetchAdminOrders(
              forceRefresh: true,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status Tabs
            SizedBox(
              height: 48,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: _statusTabs.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final tab = _statusTabs[i];
                  final isSelected = _selectedStatus == tab['id'];
                  return GestureDetector(
                    onTap: () => _onSelectTab(tab['id']!),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? c.primary : c.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : c.border,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          tab['label']!,
                          style: TextStyle(
                            color: isSelected
                                ? c.onPrimary
                                : c.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
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
                  ? const LoadingView(message: 'Đang tải đơn hàng...')
                  : state.isError && allOrders.isEmpty
                  ? _buildErrorView(state.message ?? 'Đã có lỗi xảy ra')
                  : filtered.isEmpty
                  ? _buildEmptyView()
                  : RefreshIndicator(
                      onRefresh: () => context
                          .read<OrderProvider>()
                          .fetchAdminOrders(forceRefresh: true),
                      color: c.secondary,
                      backgroundColor: c.surfaceVariant,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (_, i) =>
                            _buildAdminOrderCard(filtered[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminOrderCard(Order order) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: c.border.withValues(alpha: 0.6)),
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
              Text(
                order.code,
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
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
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: c.surfaceVariant, height: 1),
          ),

          // Shipping Info
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                color: c.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '${order.shipName} (${order.shipPhone})',
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_outlined,
                color: c.textMuted,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.shipAddress,
                  style: TextStyle(
                    color: c.textSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // Items preview
          if (order.items.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...order.items.map(
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• ${i.productName} (${i.size}, ${i.color}) x${i.quantity}',
                  style: TextStyle(
                    color: c.textMuted,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: c.surfaceVariant, height: 1),
          ),

          // Actions & Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tổng thu:',
                    style: TextStyle(color: c.textMuted, fontSize: 11),
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
              if (order.status == 'cancelled') ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: c.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: c.danger.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.block_rounded,
                        size: 14,
                        color: c.danger,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Đã huỷ (Cố định)',
                        style: TextStyle(
                          color: c.danger,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                SecondaryButton(
                  label: 'Đổi trạng thái',
                  icon: Icons.edit_note_rounded,
                  expanded: false,
                  height: 44,
                  onPressed: () => _showUpdateStatusSheet(order),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return const StatusView(
      icon: Icons.inbox_rounded,
      title: 'Không có đơn hàng nào',
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
          context.read<OrderProvider>().fetchAdminOrders(forceRefresh: true),
    );
  }
}
