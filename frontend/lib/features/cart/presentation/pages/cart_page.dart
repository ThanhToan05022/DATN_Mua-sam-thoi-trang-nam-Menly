import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
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
    final cart = context.watch<CartProvider>();
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text('Giỏ hàng${cart.totalItems > 0 ? " (${cart.totalItems})" : ""}'),
        backgroundColor: AppTheme.bg,
        actions: [
          if (cart.items.isNotEmpty)
            TextButton.icon(
              onPressed: () => _confirmClear(context, cart),
              icon: const Icon(Icons.delete_sweep_rounded, size: 18, color: AppTheme.error),
              label: const Text('Xoá hết', style: TextStyle(color: AppTheme.error, fontSize: 13)),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => cart.fetchCart(showLoading: true),
        color: AppTheme.primary,
        backgroundColor: AppTheme.surface,
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
                Expanded(
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: cart.items.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _CartItem(
                      item: cart.items[i],
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

  Widget _buildEmpty(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 100, height: 100,
        decoration: BoxDecoration(color: AppTheme.surface2, shape: BoxShape.circle, border: Border.all(color: AppTheme.border)),
        child: const Icon(Icons.shopping_bag_outlined, size: 48, color: AppTheme.textMuted),
      ),
      const SizedBox(height: 20),
      const Text('Giỏ hàng trống', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      const Text('Hãy khám phá và thêm sản phẩm yêu thích', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
      const SizedBox(height: 28),
      ElevatedButton.icon(
        onPressed: () => context.go('/products'),
        icon: const Icon(Icons.shopping_bag_rounded, size: 18, color: Colors.black),
        label: const Text('Mua sắm ngay', style: TextStyle(color: Colors.black)),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    ]),
  );

  Widget _buildSummary(BuildContext context, CartProvider cart) => Container(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      border: Border(top: BorderSide(color: AppTheme.border)),
    ),
    child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Tổng cộng:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
        Text('${_fmt(cart.totalPrice)}đ',
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
      ]),
      const SizedBox(height: 14),
      SizedBox(
        width: double.infinity, height: 54,
        child: ElevatedButton.icon(
          onPressed: () => _proceedToCheckout(context),
          icon: const Icon(Icons.payment_rounded, size: 20, color: Colors.black),
          label: const Text('Tiến hành thanh toán',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    ]),
  );

  void _confirmClear(BuildContext context, CartProvider cart) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface2,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.border2, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Icon(Icons.delete_forever_rounded, color: AppTheme.error, size: 40),
          const SizedBox(height: 12),
          const Text('Xoá tất cả sản phẩm?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Hành động này không thể hoàn tác', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(foregroundColor: AppTheme.textSecondary, side: BorderSide(color: AppTheme.border2), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Huỷ', style: TextStyle(fontWeight: FontWeight.w700)),
            )),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              onPressed: () { cart.clear(); Navigator.of(context).pop(); },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
  const _CartItem({required this.item, required this.onRemove, required this.onQtyChange});

  String _fmt(num p) { final s = p.toStringAsFixed(0); final b = StringBuffer(); for (int i = 0; i < s.length; i++) { if (i > 0 && (s.length - i) % 3 == 0) b.write('.'); b.write(s[i]); } return b.toString(); }

  @override
  Widget build(BuildContext context) {
    final thumb = item.product.thumbnailUrl ?? '';
    return Dismissible(
      key: ValueKey(item.variant.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: AppTheme.error.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete_rounded, color: AppTheme.error, size: 28),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
        child: Row(children: [
          // ✅ FIX 1: Ảnh sản phẩm thật
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 72, height: 72,
              child: thumb.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: thumb,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppTheme.surface2,
                        child: const Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2)),
                      ),
                      errorWidget: (context, url, error) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.product.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, height: 1.3)),
            const SizedBox(height: 4),
            Text('${item.variant.size} · ${item.variant.color}',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('${_fmt(item.product.price * item.quantity)}đ',
                  style: const TextStyle(color: AppTheme.primary, fontSize: 14, fontWeight: FontWeight.w800)),
              Row(children: [
                _tiny(Icons.remove_rounded, () {
                  if (item.quantity > 1) {
                    onQtyChange(item.quantity - 1);
                  } else {
                    onRemove();
                  }
                }),
                Container(
                  width: 32, height: 28, margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(color: AppTheme.surface2, borderRadius: BorderRadius.circular(8)),
                  child: Center(child: Text('${item.quantity}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13))),
                ),
                _tiny(Icons.add_rounded, () => onQtyChange(item.quantity + 1)),
              ]),
            ]),
          ])),
        ]),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: AppTheme.surface2,
    child: Center(child: Text(
      item.product.name.isNotEmpty ? item.product.name[0].toUpperCase() : '?',
      style: const TextStyle(color: AppTheme.primary, fontSize: 28, fontWeight: FontWeight.w900),
    )),
  );

  Widget _tiny(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 28, height: 28,
      decoration: BoxDecoration(color: AppTheme.surface2, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.border)),
      child: Icon(icon, color: AppTheme.primary, size: 16),
    ),
  );
}
