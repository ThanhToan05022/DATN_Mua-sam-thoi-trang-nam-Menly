import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../cart/data/cart_model.dart';
import '../../../product/data/models/product_model.dart';
import '../../data/order_model.dart';
import '../providers/order_provider.dart';

/// Chi tiết đơn hàng: timeline trạng thái, thông tin giao hàng, sản phẩm,
/// tổng tiền và các hành động (mua lại / huỷ đơn).
class OrderDetailPage extends StatefulWidget {
  final String orderId;

  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  Order? _order;
  bool _loading = true;
  bool _acting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final order = await context.read<OrderProvider>().getOrderDetail(widget.orderId);

    if (!mounted) return;
    setState(() {
      _order = order;
      _loading = false;
      _error = order == null ? 'Không tìm thấy đơn hàng' : null;
    });
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

  Future<void> _reorder() async {
    final order = _order;
    if (order == null || order.items.isEmpty) return;

    setState(() => _acting = true);
    final cart = context.read<CartProvider>();
    var added = 0;

    try {
      for (final item in order.items) {
        if (item.variantId.isEmpty) continue;
        final variant = ProductVariant(
          id: item.variantId,
          size: item.size,
          color: item.color,
          sku: 'SKU-${item.variantId}',
          stock: item.quantity,
        );
        final product = Product(
          id: '',
          categoryId: '',
          name: item.productName,
          slug: '',
          price: item.unitPrice,
          thumbnailUrl: item.thumbnailUrl,
          isActive: true,
          createdAt: '',
          variants: [variant],
        );
        await cart.addItem(product, variant, item.quantity);
        added++;
      }
      if (!mounted) return;
      if (added == 0) {
        _snack('Không thể mua lại: đơn không còn sản phẩm', isError: true);
      } else {
        _snack('Đã thêm $added sản phẩm vào giỏ hàng');
        context.push('/cart');
      }
    } catch (e) {
      if (mounted) _snack('Không thể mua lại: $e', isError: true);
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Huỷ đơn hàng',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Bạn có chắc muốn huỷ đơn hàng này?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ', style: TextStyle(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Xác nhận huỷ',
              style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _acting = true);
    final ok = await context.read<OrderProvider>().cancelOrder(_order!.id);
    if (!mounted) return;

    if (ok) {
      _snack('Đã huỷ đơn hàng');
      await _load();
    } else {
      _snack('Không thể huỷ đơn hàng', isError: true);
    }
    if (mounted) setState(() => _acting = false);
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        elevation: 0,
        title: const Text(
          'Chi tiết đơn hàng',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : order == null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppTheme.primary,
                  backgroundColor: AppTheme.surface2,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      _buildStatusHeader(order),
                      const SizedBox(height: 16),
                      _buildTimeline(order),
                      const SizedBox(height: 16),
                      _buildShipping(order),
                      const SizedBox(height: 16),
                      _buildItems(order),
                      const SizedBox(height: 16),
                      _buildTotals(order),
                      if (order.note != null && order.note!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildNote(order.note!),
                      ],
                    ],
                  ),
                ),
      bottomNavigationBar: order == null || _loading
          ? null
          : _buildActions(order),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_rounded,
                size: 48, color: AppTheme.textMuted),
            const SizedBox(height: 14),
            Text(
              _error ?? 'Không tìm thấy đơn hàng',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.black,
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(Order order) {
    final color = _statusColor(order.status);
    final done = order.isFinished || order.status == 'cancelled';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              done ? Icons.check_circle_rounded : Icons.local_shipping_rounded,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _statusLabel(order.status),
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mã đơn: ${order.code}',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            _formatDate(order.createdAt),
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(Order order) {
    final steps = order.timeline;

    return _card(
      'Theo dõi đơn hàng',
      Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            _timelineRow(steps[i], isLast: i == steps.length - 1),
        ],
      ),
    );
  }

  Widget _timelineRow(OrderTimelineStep step, {required bool isLast}) {
    final color = step.current
        ? AppTheme.primary
        : (step.completed ? AppTheme.success : AppTheme.textMuted);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: step.completed ? color : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: step.completed
                    ? Icon(Icons.check_rounded, size: 13, color: AppTheme.bg)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: step.completed
                        ? AppTheme.success.withOpacity(0.4)
                        : AppTheme.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          step.label,
                          style: TextStyle(
                            color: step.completed
                                ? Colors.white
                                : AppTheme.textMuted,
                            fontSize: 14,
                            fontWeight: step.current
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (step.createdAt != null && step.completed)
                        Text(
                          _formatDate(step.createdAt!),
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    step.description,
                    style: TextStyle(
                      color: step.completed
                          ? AppTheme.textSecondary
                          : AppTheme.textMuted,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                  if (step.current && step.note != null && step.note!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.surface2,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        step.note!,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShipping(Order order) {
    return _card(
      'Thông tin giao hàng',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(Icons.person_rounded, 'Người nhận', order.shipName),
          const SizedBox(height: 10),
          _infoRow(Icons.phone_rounded, 'Số điện thoại', order.shipPhone),
          const SizedBox(height: 10),
          _infoRow(Icons.location_on_rounded, 'Địa chỉ', order.shipAddress),
          const SizedBox(height: 10),
          _infoRow(Icons.payment_rounded, 'Thanh toán', order.paymentLabel),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.textMuted),
        const SizedBox(width: 10),
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '—' : value,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildItems(Order order) {
    if (order.items.isEmpty) {
      return _card(
        'Sản phẩm',
        const Text(
          'Không có thông tin sản phẩm',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
        ),
      );
    }

    return _card(
      'Sản phẩm (${order.items.length})',
      Column(
        children: [
          for (var i = 0; i < order.items.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(color: AppTheme.border, height: 1),
              ),
            _orderItemRow(order.items[i]),
          ],
        ],
      ),
    );
  }

  Widget _orderItemRow(OrderItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 52,
            height: 52,
            color: AppTheme.surface2,
            child: item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty
                ? Image.network(
                    item.thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.checkroom_rounded,
                            color: AppTheme.textMuted, size: 22),
                  )
                : const Icon(Icons.checkroom_rounded,
                    color: AppTheme.textMuted, size: 22),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                [item.size, item.color].where((s) => s.isNotEmpty).join(' · '),
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatPrice(item.subtotal),
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'x${item.quantity}',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTotals(Order order) {
    return _card(
      'Thanh toán',
      Column(
        children: [
          _totalRow('Tạm tính', _formatPrice(order.subtotal)),
          const SizedBox(height: 8),
          _totalRow('Phí vận chuyển', _formatPrice(order.shippingFee)),
          if (order.discountAmount > 0) ...[
            const SizedBox(height: 8),
            _totalRow(
              'Giảm giá${order.voucherCode != null ? ' (${order.voucherCode})' : ''}',
              '-${_formatPrice(order.discountAmount)}',
              color: AppTheme.success,
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: AppTheme.border, height: 1),
          ),
          _totalRow(
            'Tổng cộng',
            _formatPrice(order.total),
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value, {bool bold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: bold ? Colors.white : AppTheme.textSecondary,
            fontSize: bold ? 14 : 13,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color ?? (bold ? AppTheme.primary : Colors.white),
            fontSize: bold ? 16 : 13,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildNote(String note) {
    return _card(
      'Ghi chú',
      Text(
        note,
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
      ),
    );
  }

  Widget _card(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildActions(Order order) {
    final canReorder = order.items.isNotEmpty && order.status != 'cancelled';
    final canCancel = order.canCancel;

    if (!canReorder && !canCancel) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (canCancel) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: _acting ? null : _cancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: const BorderSide(color: AppTheme.error),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Huỷ đơn',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            if (canReorder)
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _acting ? null : _reorder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _acting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          'Mua lại',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _statusLabel(String status) {
    switch (status) {
      case 'pending_payment':
        return 'Chờ thanh toán';
      case 'paid':
        return 'Đã thanh toán';
      case 'processing':
        return 'Đã xác nhận';
      case 'shipping':
        return 'Đang giao hàng';
      case 'completed':
      case 'delivered':
        return 'Hoàn tất';
      case 'cancelled':
        return 'Đã huỷ';
      default:
        return status;
    }
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'completed':
      case 'delivered':
        return AppTheme.success;
      case 'cancelled':
        return AppTheme.error;
      case 'paid':
      case 'processing':
      case 'shipping':
        return AppTheme.primary;
      default:
        return AppTheme.warning;
    }
  }

  static String _formatPrice(int value) {
    final s = value.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${value < 0 ? '-' : ''}$buf đ';
  }

  static String _formatDate(String iso) {
    if (iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final two = (int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year} '
        '${two(dt.hour)}:${two(dt.minute)}';
  }
}