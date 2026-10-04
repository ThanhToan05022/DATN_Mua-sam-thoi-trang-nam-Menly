import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/add_to_cart_button.dart';
import '../../../../core/utils/auth_guard.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../cart/data/cart_model.dart';
import '../providers/wishlist_provider.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<AuthProvider>().isLoggedIn) {
        context.read<WishlistProvider>().fetchWishlist();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final auth = context.watch<AuthProvider>();
    final wishlistProv = context.watch<WishlistProvider>();
    final state = wishlistProv.state;
    final items = wishlistProv.items;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: Text(
          items.isNotEmpty
              ? 'Sản phẩm yêu thích (${items.length})'
              : 'Sản phẩm yêu thích',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: c.background,
        elevation: 0,
        actions: [
          if (auth.isLoggedIn && items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Làm mới',
              onPressed: () => context
                  .read<WishlistProvider>()
                  .fetchWishlist(forceRefresh: true),
            ),
        ],
      ),
      body: !auth.isLoggedIn
          ? _buildGuestState(context)
          : RefreshIndicator(
              onRefresh: () => context
                  .read<WishlistProvider>()
                  .fetchWishlist(forceRefresh: true),
              color: c.secondary,
              backgroundColor: c.surface,
              child: Builder(
                builder: (context) {
                  if (state.isLoading && items.isEmpty) {
                    return _buildSkeletonGrid();
                  }

                  if (state.isError && items.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 64,
                              color: c.danger,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              state.message ??
                                  'Không thể tải danh sách yêu thích',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: c.textSecondary,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () => context
                                  .read<WishlistProvider>()
                                  .fetchWishlist(forceRefresh: true),
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (items.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: c.surfaceVariant,
                                border: Border.all(color: c.border),
                              ),
                              child: Icon(
                                Icons.favorite_border_rounded,
                                size: 64,
                                color: c.textMuted,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Danh sách yêu thích trống',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: c.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Hãy thả tim những sản phẩm bạn thích để lưu lại và mua sắm tiện lợi hơn.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: c.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () => context.go('/products'),
                              child: const Text('Khám phá sản phẩm ngay'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: EdgeInsets.fromLTRB(
                        16, 16, 16, MediaQuery.of(context).padding.bottom + 96),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final product = items[index];
                      return GestureDetector(
                        onTap: () => context.push('/products/${product.id}'),
                        child: Container(
                          decoration: BoxDecoration(
                            color: c.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: c.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Ảnh + Nút Bỏ thích
                              Expanded(
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius:
                                          const BorderRadius.vertical(
                                        top: Radius.circular(15),
                                      ),
                                      child: SizedBox(
                                        width: double.infinity,
                                        height: double.infinity,
                                        child: product.imageUrl.isNotEmpty
                                            ? CachedNetworkImage(
                                                imageUrl: product.imageUrl,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) =>
                                                    Container(
                                                  color: c.surfaceVariant,
                                                ),
                                                errorWidget: (context, url, error) =>
                                                    Container(
                                                  color: c.surfaceVariant,
                                                  child: Icon(
                                                    Icons
                                                        .image_not_supported_rounded,
                                                    color: c.textMuted,
                                                  ),
                                                ),
                                              )
                                            : Container(
                                                color: c.surfaceVariant),
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black
                                              .withValues(alpha: 0.65),
                                          shape: BoxShape.circle,
                                        ),
                                        child: IconButton(
                                          constraints: const BoxConstraints(
                                            minWidth: 36,
                                            minHeight: 36,
                                          ),
                                          padding: EdgeInsets.zero,
                                          icon: const Icon(
                                            Icons.favorite_rounded,
                                            color: Colors.redAccent,
                                            size: 20,
                                          ),
                                          tooltip: 'Bỏ thích',
                                          onPressed: () {
                                            context
                                                .read<WishlistProvider>()
                                                .toggleWishlist(product);
                                            ScaffoldMessenger.of(context)
                                                .hideCurrentSnackBar();
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Đã bỏ thích "${product.name}"',
                                                ),
                                                duration:
                                                    const Duration(seconds: 1),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Thông tin sản phẩm
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: c.textPrimary,
                                        height: 1.25,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _currencyFormat.format(product.price),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: c.secondary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    AddToCartButton(
                                      height: 36,
                                      onTap: () {
                                        if (!AuthGuard.check(
                                          context,
                                          actionTitle: 'Đăng nhập để mua hàng',
                                          actionMessage:
                                              'Bạn đang duyệt ẩn danh. Vui lòng đăng nhập để thêm "${product.name}" vào giỏ hàng và thanh toán.',
                                        )) {
                                          return;
                                        }
                                        if (product.variants.isNotEmpty) {
                                          final v = product.variants.first;
                                          context
                                              .read<CartProvider>()
                                              .addItem(product, v, 1);
                                          ScaffoldMessenger.of(context)
                                              .hideCurrentSnackBar();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Đã thêm "${product.name}" vào giỏ hàng',
                                              ),
                                              duration:
                                                  const Duration(seconds: 1),
                                            ),
                                          );
                                        } else {
                                          context
                                              .push('/products/${product.id}');
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }

  /// Taste Skill Styled Guest State
  Widget _buildGuestState(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.redAccent.withValues(alpha: 0.2),
                    c.secondary.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent.withValues(alpha: 0.2),
                    blurRadius: 28,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.favorite_outline_rounded,
                  color: Colors.redAccent,
                  size: 42,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Lưu lại phong cách của bạn',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Đăng nhập tài khoản Menly để quản lý sản phẩm yêu thích và lưu trữ những bộ trang phục bạn ưng ý nhất.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => context.push('/login'),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: c.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: c.primary.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Đăng nhập ngay',
                    style: TextStyle(
                      color: c.onPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.push('/register'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                foregroundColor: c.textPrimary,
                side: BorderSide(color: c.border, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Tạo tài khoản mới',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonGrid() {
    final c = AppColors.of(context);
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: 4,
      itemBuilder: (context, index) => Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: c.surfaceVariant,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(15)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 12,
                    decoration: BoxDecoration(
                      color: c.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 70,
                    height: 14,
                    decoration: BoxDecoration(
                      color: c.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    height: 28,
                    decoration: BoxDecoration(
                      color: c.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
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
