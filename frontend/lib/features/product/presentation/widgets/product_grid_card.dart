import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/auth_guard.dart';
import '../../../cart/data/cart_model.dart';
import '../../../wishlist/presentation/providers/wishlist_provider.dart';
import '../../data/models/product_model.dart';

class ProductGridCard extends StatelessWidget {
  final Product product;
  const ProductGridCard({super.key, required this.product});

  String _fmt(num p) {
    final s = p.toStringAsFixed(0);
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return b.toString();
  }

  Widget _placeholder(AppColors c, String n) => Container(
        color: c.surfaceVariant,
        child: Center(
          child: Text(
            n.isNotEmpty ? n[0].toUpperCase() : '?',
            style: TextStyle(
              color: c.secondary,
              fontSize: 36,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isFav = context.watch<WishlistProvider>().isFavorite(product.id);

    return GestureDetector(
      onTap: () => context.push('/products/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(18)),
                    child: product.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => _placeholder(c, product.name),
                            errorWidget: (_, _, _) =>
                                _placeholder(c, product.name),
                          )
                        : _placeholder(c, product.name),
                  ),
                  // Nút tim yêu thích
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          isFav
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFav ? Colors.redAccent : Colors.white,
                          size: 18,
                        ),
                        tooltip: isFav ? 'Bỏ thích' : 'Yêu thích',
                        onPressed: () {
                          if (!AuthGuard.check(
                            context,
                            actionTitle: 'Đăng nhập để lưu yêu thích',
                            actionMessage:
                                'Vui lòng đăng nhập để lưu "${product.name}" vào danh sách yêu thích của bạn.',
                          )) {
                            return;
                          }
                          context
                              .read<WishlistProvider>()
                              .toggleWishlist(product);
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isFav
                                    ? 'Đã xóa "${product.name}" khỏi danh sách yêu thích'
                                    : 'Đã thêm "${product.name}" vào danh sách yêu thích ❤️',
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_fmt(product.price)}đ',
                        style: TextStyle(
                          color: c.secondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Kiểm tra chặn mua sắm nếu là ẩn danh
                          if (!AuthGuard.check(
                            context,
                            actionTitle: 'Đăng nhập để mua hàng',
                            actionMessage:
                                'Bạn đang ở chế độ xem ẩn danh. Để thêm vào giỏ hàng và mua sản phẩm, vui lòng đăng nhập tài khoản.',
                            redirectPath: '/cart',
                          )) {
                            return;
                          }
                          if (product.variants.isNotEmpty) {
                            final v = product.variants.first;
                            context.read<CartProvider>().addItem(product, v, 1);
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Đã thêm "${product.name}" vào giỏ'),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } else {
                            context.push('/products/${product.id}');
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: c.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.add_shopping_cart_rounded,
                            color: c.onPrimary,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
