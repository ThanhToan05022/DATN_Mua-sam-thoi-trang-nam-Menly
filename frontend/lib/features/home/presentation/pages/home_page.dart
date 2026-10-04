import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/category_pill.dart';
import '../../../../core/widgets/display_settings.dart';
import '../../../../core/widgets/product_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/utils/auth_guard.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../cart/data/cart_model.dart';
import '../../../product/data/models/product_model.dart';
import '../../../product/presentation/providers/product_provider.dart';
import '../../../wishlist/presentation/providers/wishlist_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final provider = context.watch<ProductProvider>();

    return Scaffold(
      backgroundColor: c.background,
      body: RefreshIndicator(
        color: c.primary,
        onRefresh: () => provider.fetchAll(forceRefresh: true),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const _HomeHeader(),
            const SizedBox(height: 18),
            const _PromoCard(),
            const SizedBox(height: 24),
            _buildCategories(provider),
            const SizedBox(height: 24),
            _buildProducts(provider),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 96),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories(ProductProvider provider) {
    return provider.categoriesState.when(
      initial: () => const SizedBox.shrink(),
      loading: () => const _RailSkeleton(height: 46),
      error: (_) => const SizedBox.shrink(),
      success: (categories) {
        if (categories.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: SectionHeader(title: 'Danh mục'),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 46,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final cat = categories[i];
                  return CategoryPill(
                    label: cat.name,
                    icon: categoryIcon('${cat.slug} ${cat.name}'),
                    onTap: () => context.go('/products', extra: cat.id),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProducts(ProductProvider provider) {
    return provider.productsState.when(
      initial: () => const SizedBox(height: 280, child: LoadingView()),
      loading: () => const SizedBox(height: 280, child: LoadingView()),
      error: (msg) => SizedBox(
        height: 320,
        child: StatusView(
          icon: Icons.wifi_off_rounded,
          title: 'Không tải được sản phẩm',
          message: msg,
          actionLabel: 'Thử lại',
          danger: true,
          onAction: () => provider.fetchAll(forceRefresh: true),
        ),
      ),
      success: (products) {
        if (products.isEmpty) {
          return const SizedBox(
            height: 280,
            child: StatusView(
              icon: Icons.inventory_2_outlined,
              title: 'Chưa có sản phẩm',
              message: 'Hãy quay lại sau nhé',
            ),
          );
        }
        final featured = products.take(8).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SectionHeader(
                title: 'Sản phẩm nổi bật',
                actionLabel: 'Xem tất cả',
                onAction: () => context.go('/products'),
              ),
            ),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.55,
              ),
              itemCount: featured.length,
              itemBuilder: (_, i) => _ProductTile(product: featured[i]),
            ),
          ],
        );
      },
    );
  }
}

/// A product tile wired to wishlist + navigation.
class _ProductTile extends StatelessWidget {
  final Product product;
  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();
    return ProductCard(
      product: product,
      isFavorite: wishlist.isFavorite(product.id),
      onTap: () => context.push('/products/${product.id}'),
      onToggleFavorite: () async {
        try {
          await context.read<WishlistProvider>().toggleWishlist(product);
        } catch (_) {}
      },
      onAdd: () => _quickAdd(context, product),
    );
  }

  void _quickAdd(BuildContext context, Product product) {
    if (product.variants.isEmpty) {
      context.push('/products/${product.id}');
      return;
    }
    final ok = AuthGuard.check(context, redirectPath: '/');
    if (!ok) return;
    context.read<CartProvider>().addItem(product, product.variants.first, 1);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã thêm vào giỏ hàng')),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final auth = context.watch<AuthProvider>();
    final name = auth.user?.fullName ?? 'Khách';

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 10, 20, 4),
      color: c.background,
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: c.primarySoft,
                child: Icon(Icons.person_rounded, color: c.secondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auth.isLoggedIn ? 'Xin chào' : 'Chào mừng đến',
                      style: TextStyle(color: c.textSecondary, fontSize: 12.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      auth.isLoggedIn ? name : 'Menly Boutique',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              _HeaderIcon(
                icon: Icons.notifications_none_rounded,
                onTap: () => context.push('/notifications'),
              ),
              const SizedBox(width: 10),
              const DisplaySettingsButton(),
            ],
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () => context.go('/products'),
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: c.surfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: c.textMuted),
                  const SizedBox(width: 10),
                  Text(
                    'Tìm kiếm sản phẩm...',
                    style: TextStyle(color: c.textMuted, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Material(
      color: c.surfaceVariant,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 21, color: c.textPrimary),
        ),
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(c.inkCard, c.secondary, 0.22)!,
              c.inkCard,
            ],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          boxShadow: [
            BoxShadow(
              color: c.secondary.withValues(alpha: 0.22),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          child: Stack(
            children: [
              // Decorative glow circles for depth.
              Positioned(
                right: -34,
                top: -40,
                child: _circle(130, c.secondary.withValues(alpha: 0.22)),
              ),
              Positioned(
                right: 44,
                bottom: -46,
                child: _circle(96, c.onInk.withValues(alpha: 0.05)),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: c.secondary,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusPill),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bolt_rounded,
                                    size: 14, color: Colors.white),
                                const SizedBox(width: 4),
                                const Text(
                                  'ƯU ĐÃI ĐẶC BIỆT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text.rich(
                            TextSpan(
                              style: TextStyle(
                                color: c.onInk,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                height: 1.1,
                              ),
                              children: [
                                const TextSpan(text: 'Giảm đến '),
                                TextSpan(
                                  text: '50%',
                                  style: TextStyle(color: c.secondary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Bộ sưu tập Thu Đông 2026',
                            style: TextStyle(
                              color: c.onInk.withValues(alpha: 0.65),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                          PrimaryButton(
                            label: 'Khám phá ngay',
                            icon: Icons.arrow_forward_rounded,
                            expanded: false,
                            height: 44,
                            background: c.secondary,
                            foreground: Colors.white,
                            onPressed: () => context.go('/products'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        color: c.secondary.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: c.secondary.withValues(alpha: 0.5),
                          width: 1.4,
                        ),
                      ),
                      child: Icon(Icons.local_offer_rounded,
                          color: c.secondary, size: 30),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circle(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _RailSkeleton extends StatelessWidget {
  final double height;
  const _RailSkeleton({required this.height});
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(
          3,
          (_) => Container(
            width: 110,
            height: height,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: c.surfaceVariant,
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            ),
          ),
        ),
      ),
    );
  }
}

