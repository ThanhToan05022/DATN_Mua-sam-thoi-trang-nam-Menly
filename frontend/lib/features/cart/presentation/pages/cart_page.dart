import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/cart_model.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text('Giỏ hàng (${cart.totalItems})'),
        actions: [
          if (cart.items.isNotEmpty)
            TextButton(
              onPressed: () => _confirmClear(context, cart),
              child: const Text('Xóa tất cả', style: TextStyle(color: AppTheme.error, fontSize: 13)),
            ),
        ],
      ),
      body: cart.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_bag_outlined, size: 80, color: AppTheme.border),
                  const SizedBox(height: 16),
                  const Text('Giỏ hàng trống', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/products'),
                    child: const Text('Mua sắm ngay'),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: cart.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) => _CartItemTile(item: cart.items[i]),
            ),
      bottomNavigationBar: cart.items.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng cộng', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                      Text('${_fmt(cart.totalPrice)} đ',
                          style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.go('/checkout'),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.payment_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Tiến hành thanh toán'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _confirmClear(BuildContext ctx, CartProvider cart) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Xóa giỏ hàng?', style: TextStyle(color: Colors.white)),
        content: const Text('Tất cả sản phẩm sẽ bị xóa khỏi giỏ hàng.', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          TextButton(onPressed: () { cart.clear(); Navigator.pop(ctx); },
              child: const Text('Xóa', style: TextStyle(color: AppTheme.error))),
        ],
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 72, height: 80,
              child: item.product.thumbnailUrl != null
                  ? Image.network(item.product.thumbnailUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: AppTheme.surface, child: const Icon(Icons.checkroom_rounded, color: AppTheme.border)))
                  : Container(color: AppTheme.surface, child: const Icon(Icons.checkroom_rounded, color: AppTheme.border)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                Text('Size: ${item.variant.size}  |  Màu: ${item.variant.color}',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('${_fmt(item.product.price)} đ',
                        style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                    const Spacer(),
                    _QtyControl(
                      qty: item.quantity,
                      onDec: () => cart.updateQty(item.variant.id, item.quantity - 1),
                      onInc: () => cart.updateQty(item.variant.id, item.quantity + 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 20),
            onPressed: () => cart.removeItem(item.variant.id),
          ),
        ],
      ),
    );
  }
}

class _QtyControl extends StatelessWidget {
  final int qty;
  final VoidCallback onDec;
  final VoidCallback onInc;
  const _QtyControl({required this.qty, required this.onDec, required this.onInc});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      GestureDetector(
        onTap: onDec,
        child: Container(
          width: 26, height: 26,
          decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppTheme.border)),
          child: const Icon(Icons.remove, size: 14, color: Colors.white),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Text('$qty', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ),
      GestureDetector(
        onTap: onInc,
        child: Container(
          width: 26, height: 26,
          decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(6)),
          child: const Icon(Icons.add, size: 14, color: Colors.black),
        ),
      ),
    ],
  );
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
