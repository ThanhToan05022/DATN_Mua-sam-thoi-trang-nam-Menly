import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/utils/auth_guard.dart';
import '../../data/cart_model.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  String _fmt(num p) {
    final s = p.toStringAsFixed(0);
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return b.toString();
  }

  void _proceedToCheckout(BuildContext context) {
    if (!AuthGuard.check(
      context,
      actionTitle: 'Đăng nhập để thanh toán',
      actionMessage:
          'Bạn đang ở chế độ xem ẩn danh. Để tiến hành đặt hàng và thanh toán, vui lòng đăng nhập tài khoản.',
      redirectPath: '/checkout',
    )) {
      return;
    }

    context.push('/checkout');
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final cart = context.watch<CartProvider>();
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: Text('Giỏ hàng${cart.totalItems > 0 ? " (${cart.totalItems})" : ""}'),
        backgroundColor: c.background,
        actions: [
          if (cart.items.isNotEmpty)
            TextButton.icon(
              onPressed: () => _confirmClear(context, cart),
              icon: Icon(Icons.delete_sweep_rounded, size: 18, color: c.danger),
              label: Text('Xoá hết', style: TextStyle(color: c.danger, fontSize: 13)),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => cart.fetchCart(showLoading: true),
        color: c.secondary,
        backgroundColor: c.surface,
        child: cart.items.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: _buildEmpty(context),
                  ),
                ],
              )
            : Column(children: [
                _buildSelectAll(context, cart),
                Expanded(
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: cart.items.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _CartItem(
                      item: cart.items[i],
                      selected: cart.isSelected(cart.items[i].variant.id),
                      onToggleSelected: () =>
                          cart.toggleSelected(cart.items[i].variant.id),
                      onRemove: () => cart.removeItem(cart.items[i].variant.id),
                      onQtyChange: (q) => cart.updateQty(cart.items[i].variant.id, q),
                    ),
                  ),
                ),
                _buildSummary(context, cart),
              ]),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 100, height: 100,
          decoration: BoxDecoration(color: c.surfaceVariant, shape: BoxShape.circle, border: Border.all(color: c.border)),
          child: Icon(Icons.shopping_bag_outlined, size: 48, color: c.textMuted),
        ),
        const SizedBox(height: 20),
        Text('Giỏ hàng trống', style: TextStyle(color: c.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Hãy khám phá và thêm sản phẩm yêu thích', style: TextStyle(color: c.textMuted, fontSize: 14)),
        const SizedBox(height: 28),
        ElevatedButton.icon(
          onPressed: () => context.go('/products'),
          icon: Icon(Icons.shopping_bag_rounded, size: 18, color: c.onPrimary),
          label: Text('Mua sắm ngay', style: TextStyle(color: c.onPrimary)),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ]),
    );
  }

  Widget _buildSelectAll(BuildContext context, CartProvider cart) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: () => cart.setAllSelected(!cart.allSelected),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: cart.allSelected ? c.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: cart.allSelected ? c.primary : c.border,
                  width: 1.6,
                ),
              ),
              child: cart.allSelected
                  ? Icon(Icons.check_rounded, size: 15, color: c.onPrimary)
                  : null,
            ),
            const SizedBox(width: 10),
            Text('Chọn tất cả',
                style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('${cart.selectedCount} sản phẩm đã chọn',
                style: TextStyle(color: c.textMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(BuildContext context, CartProvider cart) {
    final c = AppColors.of(context);
    final hasSelection = cart.selectedCount > 0;
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Tổng cộng:', style: TextStyle(color: c.textSecondary, fontSize: 15)),
          Text('${_fmt(cart.selectedTotalPrice)}đ',
              style: TextStyle(color: c.secondary, fontSize: 20, fontWeight: FontWeight.w900)),
        ]),
        const SizedBox(height: 14),
        PrimaryButton(
          label: hasSelection
              ? 'Thanh toán (${cart.selectedCount})'
              : 'Chọn sản phẩm để mua',
          icon: Icons.payment_rounded,
          onPressed: hasSelection ? () => _proceedToCheckout(context) : null,
        ),
      ]),
    );
  }

  void _confirmClear(BuildContext context, CartProvider cart) {
    final c = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surfaceVariant,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Icon(Icons.delete_forever_rounded, color: c.danger, size: 40),
          const SizedBox(height: 12),
          Text('Xoá tất cả sản phẩm?', style: TextStyle(color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Hành động này không thể hoàn tác', style: TextStyle(color: c.textMuted, fontSize: 14)),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(foregroundColor: c.textSecondary, side: BorderSide(color: c.border), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Huỷ', style: TextStyle(fontWeight: FontWeight.w700)),
            )),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              onPressed: () { cart.clear(); Navigator.of(context).pop(); },
              style: ElevatedButton.styleFrom(backgroundColor: c.danger, foregroundColor: c.onPrimary, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Xoá tất cả', style: TextStyle(fontWeight: FontWeight.w700)),
            )),
          ]),
        ]),
      ),
    );
  }
}

// ============================================================
// _CartItem — hiện ảnh thật từ thumbnailUrl
// ============================================================
class _CartItem extends StatelessWidget {
  final CartItem item;
  final VoidCallback onRemove;
  final ValueChanged<int> onQtyChange;
  final bool selected;
  final VoidCallback onToggleSelected;
  const _CartItem({
    required this.item,
    required this.onRemove,
    required this.onQtyChange,
    required this.selected,
    required this.onToggleSelected,
  });

  String _fmt(num p) { final s = p.toStringAsFixed(0); final b = StringBuffer(); for (int i = 0; i < s.length; i++) { if (i > 0 && (s.length - i) % 3 == 0) b.write('.'); b.write(s[i]); } return b.toString(); }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final thumb = item.product.thumbnailUrl ?? '';
    return Dismissible(
      key: ValueKey(item.variant.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: c.danger.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
        child: Icon(Icons.delete_rounded, color: c.danger, size: 28),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
        child: Row(children: [
          // Checkbox chọn sản phẩm để thanh toán
          GestureDetector(
            onTap: onToggleSelected,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: selected ? c.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: selected ? c.primary : c.border,
                    width: 1.6,
                  ),
                ),
                child: selected
                    ? Icon(Icons.check_rounded, size: 16, color: c.onPrimary)
                    : null,
              ),
            ),
          ),
          // Ảnh sản phẩm thật
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 72, height: 72,
              child: thumb.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: thumb,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: c.surfaceVariant,
                        child: Center(child: CircularProgressIndicator(color: c.secondary, strokeWidth: 2)),
                      ),
                      errorWidget: (context, url, error) => _placeholder(context),
                    )
                  : _placeholder(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Text(item.product.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.w700, height: 1.3)),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onRemove,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Icon(Icons.delete_outline_rounded, size: 20, color: c.textMuted),
                ),
              ),
            ]),
            const SizedBox(height: 4),
            Text('${item.variant.size} · ${item.variant.color}',
                style: TextStyle(color: c.textMuted, fontSize: 12)),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('${_fmt(item.product.price * item.quantity)}đ',
                  style: TextStyle(color: c.secondary, fontSize: 14, fontWeight: FontWeight.w800)),
              Row(children: [
                _tiny(context, Icons.remove_rounded, () {
                  if (item.quantity > 1) {
                    onQtyChange(item.quantity - 1);
                  } else {
                    onRemove();
                  }
                }),
                Container(
                  width: 32, height: 28, margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(color: c.surfaceVariant, borderRadius: BorderRadius.circular(8)),
                  child: Center(child: Text('${item.quantity}', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w800, fontSize: 13))),
                ),
                _tiny(context, Icons.add_rounded, () => onQtyChange(item.quantity + 1)),
              ]),
            ]),
          ])),
        ]),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      color: c.surfaceVariant,
      child: Center(child: Text(
        item.product.name.isNotEmpty ? item.product.name[0].toUpperCase() : '?',
        style: TextStyle(color: c.secondary, fontSize: 28, fontWeight: FontWeight.w900),
      )),
    );
  }

  Widget _tiny(BuildContext context, IconData icon, VoidCallback onTap) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(color: c.surfaceVariant, borderRadius: BorderRadius.circular(8), border: Border.all(color: c.border)),
        child: Icon(icon, color: c.secondary, size: 16),
      ),
    );
  }
}
