import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
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
    if (order.status == 'cancelled') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '⚠️ Đơn hàng đã ở trạng thái ĐÃ HUỶ, không thể chuyển sang trạng thái khác.',
          ),
          backgroundColor: AppTheme.error,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                      color: AppTheme.border2,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Cập nhật trạng thái: ${order.code}',
                  style: const TextStyle(
                    color: Colors.white,
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
                      borderRadius: BorderRadius.circular(14),
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
                                        ? AppTheme.success
                                        : AppTheme.error,
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
                              ? optColor.withOpacity(0.15)
                              : AppTheme.surface2,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isCurrent ? optColor : AppTheme.border,
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
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: isCurrent
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            if (isCurrent)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppTheme.primary,
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
    final auth = context.watch<AuthProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final state = orderProvider.adminOrdersState;
    final allOrders = state.data ?? [];
    final filtered = _getFilteredOrders(allOrders);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quản lý đơn hàng',
              style: TextStyle(
                color: Colors.white,
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
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
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
                        gradient: isSelected ? AppTheme.primaryGradient : null,
                        color: isSelected ? null : AppTheme.surface2,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : AppTheme.border,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          tab['label']!,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.black
                                : AppTheme.textSecondary,
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
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    )
                  : state.isError && allOrders.isEmpty
                  ? _buildErrorView(state.message ?? 'Đã có lỗi xảy ra')
                  : filtered.isEmpty
                  ? _buildEmptyView()
                  : RefreshIndicator(
                      onRefresh: () => context
                          .read<OrderProvider>()
                          .fetchAdminOrders(forceRefresh: true),
                      color: AppTheme.primary,
                      backgroundColor: AppTheme.surface2,
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
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.code,
                style: const TextStyle(
                  color: Colors.white,
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
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: AppTheme.surface2, height: 1),
          ),

          // Shipping Info
          Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                color: AppTheme.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '${order.shipName} (${order.shipPhone})',
                style: const TextStyle(
                  color: Colors.white,
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
              const Icon(
                Icons.location_on_outlined,
                color: AppTheme.textMuted,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.shipAddress,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
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
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: AppTheme.surface2, height: 1),
          ),

          // Actions & Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tổng thu:',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
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
              if (order.status == 'cancelled') ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.block_rounded,
                        size: 14,
                        color: Color(0xFFEF4444),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Đã huỷ (Cố định)',
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: () => _showUpdateStatusSheet(order),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.surface2,
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: AppTheme.border2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                  ),
                  icon: const Icon(Icons.edit_note_rounded, size: 18),
                  label: const Text(
                    'Đổi trạng thái',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.inbox_rounded, color: AppTheme.textMuted, size: 48),
          SizedBox(height: 12),
          Text(
            'Không có đơn hàng nào',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
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
            const Icon(
              Icons.error_outline_rounded,
              color: AppTheme.error,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.read<OrderProvider>().fetchAdminOrders(
                forceRefresh: true,
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
