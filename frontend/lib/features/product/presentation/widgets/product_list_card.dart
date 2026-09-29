import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/auth_guard.dart';
import '../../../wishlist/presentation/providers/wishlist_provider.dart';
import '../../data/models/product_model.dart';

class ProductListCard extends StatelessWidget {
  final Product product;
  const ProductListCard({super.key, required this.product});

  String _fmt(num p) {
    final s = p.toStringAsFixed(0);
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isFav = context.watch<WishlistProvider>().isFavorite(product.id);

    return GestureDetector(
      onTap: () => context.push('/products/${product.id}'),
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(16)),
              child: SizedBox(
                width: 90,
                height: 96,
                child: product.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => Container(
                          color: AppTheme.surface2,
                          child: Center(
                            child: Text(
                              product.name.isNotEmpty ? product.name[0] : '?',
                              style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                      )
                    : Container(
                        color: AppTheme.surface2,
                        child: Center(
                          child: Text(
                            product.name.isNotEmpty ? product.name[0] : '?',
                            style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 28,
                                fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_fmt(product.price)}đ',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFav ? Colors.redAccent : AppTheme.textMuted,
                size: 20,
              ),
              onPressed: () {
                if (!AuthGuard.check(
                  context,
                  actionTitle: 'Đăng nhập để lưu yêu thích',
                  actionMessage:
                      'Vui lòng đăng nhập để lưu "${product.name}" vào danh sách yêu thích của bạn.',
                )) {
                  return;
                }
                context.read<WishlistProvider>().toggleWishlist(product);
              },
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.arrow_forward_ios_rounded,
                  color: AppTheme.textMuted, size: 14),
            ),
          ],
        ),
      ),
    );
  }
}
