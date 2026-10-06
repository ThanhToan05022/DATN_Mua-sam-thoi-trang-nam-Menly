import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/auth_guard.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../cart/data/cart_model.dart';
import '../../../wishlist/presentation/providers/wishlist_provider.dart';
import '../../data/models/product_model.dart';
import '../../data/models/review_model.dart';
import '../providers/product_provider.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;
  const ProductDetailPage({super.key, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late Future<Product> _future;
  String? _size;
  String? _color;
  int _qty = 1;
  List<Review> _reviews = [];
  bool _loadingReviews = true;
  double _avgRating = 5.0;

  @override
  void initState() {
    super.initState();
    _future = context.read<ProductProvider>().getProductDetail(widget.productId);
    _loadReviews();
  }

  List<String> _distinct(List<ProductVariant> v, String Function(ProductVariant) f) {
    final seen = <String>[];
    for (final x in v) {
      final val = f(x);
      if (val.isNotEmpty && !seen.contains(val)) seen.add(val);
    }
    return seen;
  }

  ProductVariant? _selectedVariant(Product p) {
    for (final v in p.variants) {
      if ((_size == null || v.size == _size) &&
          (_color == null || v.color == _color)) {
        return v;
      }
    }
    return p.variants.isNotEmpty ? p.variants.first : null;
  }

  Future<void> _addToCart(Product p, {bool buyNow = false}) async {
    final variant = _selectedVariant(p);
    if (variant == null) return;
    final ok = AuthGuard.check(context, redirectPath: '/products/${p.id}');
    if (!ok) return;
    await context.read<CartProvider>().addItem(p, variant, _qty);
    if (!mounted) return;
    if (buyNow) {
      context.push('/checkout');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã thêm vào giỏ hàng')),
      );
    }
  }

  Future<void> _loadReviews() async {
    try {
      final res = await DioClient.instance.dio.get('/reviews/product/${widget.productId}?limit=50');
      final data = res.data;
      final map = data is Map ? (data['data'] ?? data) : {};
      final items = (map['items'] as List?)?.map((j) => Review.fromJson(j as Map<String, dynamic>)).toList() ?? [];
      if (mounted) {
        setState(() {
          _reviews = items;
          if (_reviews.isNotEmpty) {
            _avgRating = _reviews.fold(0.0, (s, r) => s + r.rating) / _reviews.length;
          }
          _loadingReviews = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingReviews = false);
    }
  }

  Future<void> _submitReview(int rating, String comment) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để đánh giá')),
      );
      return;
    }

    try {
      await DioClient.instance.dio.post(
        '/reviews/${widget.productId}',
        data: {'rating': rating, 'comment': comment},
      );
      if (mounted) {
        Navigator.of(context).pop();
        _loadReviews();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đánh giá sản phẩm thành công!')),
        );
      }
    } catch (e) {
      String errMsg = 'Lỗi gửi đánh giá';
      if (e is DioException && e.response?.data is Map) {
        final d = e.response!.data as Map;
        errMsg = d['error']?['message'] ?? d['message'] ?? errMsg;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errMsg)),
        );
      }
    }
  }

  void _showReviewForm() {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để viết đánh giá')),
      );
      return;
    }

    int rating = 5;
    final txtCtrl = TextEditingController();
    final c = AppColors.of(context);
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: StatefulBuilder(
          builder: (ctx, setModalState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Đánh giá sản phẩm',
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => IconButton(
                    icon: Icon(
                      Icons.star_rounded,
                      color: index < rating
                          ? c.secondary
                          : c.textMuted.withValues(alpha: 0.3),
                      size: 38,
                    ),
                    onPressed: () => setModalState(() => rating = index + 1),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: c.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.border),
                ),
                child: TextField(
                  controller: txtCtrl,
                  style: TextStyle(color: c.textPrimary, fontSize: 14),
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Cảm nhận của bạn về chất liệu, form dáng...',
                    hintStyle: TextStyle(color: c.textMuted, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Gửi đánh giá',
                loading: submitting,
                onPressed: () async {
                  setModalState(() => submitting = true);
                  await _submitReview(rating, txtCtrl.text.trim());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: FutureBuilder<Product>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: c.primary));
          }
          if (snap.hasError || !snap.hasData) {
            return _ErrorView(onBack: () => context.pop());
          }
          return _buildContent(snap.data!, c);
        },
      ),
    );
  }

  Widget _buildContent(Product p, AppColors c) {
    final sizes = _distinct(p.variants, (v) => v.size);
    final colors = _distinct(p.variants, (v) => v.color);
    final variant = _selectedVariant(p);
    final stock = variant?.stock ?? p.stock;
    final wishlist = context.watch<WishlistProvider>();
    final fav = wishlist.isFavorite(p.id);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _ImageHeader(product: p, favorite: fav),
              Transform.translate(
                offset: const Offset(0, -20),
                child: Container(
                  decoration: BoxDecoration(
                    color: c.background,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CategoryChipLabel(label: 'Thời trang nam'),
                      const SizedBox(height: 8),
                      Text(
                        p.name,
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            formatVnd(p.price),
                            style: TextStyle(
                              color: c.secondary,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (_reviews.isNotEmpty) ...[
                            Icon(Icons.star_rounded, color: c.secondary, size: 18),
                            const SizedBox(width: 3),
                            Text(
                              _avgRating.toStringAsFixed(1),
                              style: TextStyle(
                                color: c.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              ' (${_reviews.length})',
                              style: TextStyle(color: c.textMuted, fontSize: 13),
                            ),
                          ],
                          const Spacer(),
                          _StockBadge(stock: stock),
                        ],
                      ),
                      if (p.description != null &&
                          p.description!.trim().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          p.description!,
                          style: TextStyle(
                            color: c.textSecondary,
                            fontSize: 14,
                            height: 1.55,
                          ),
                        ),
                      ],
                      if (sizes.isNotEmpty) ...[
                        const SizedBox(height: 22),
                        _SelectorLabel('Kích cỡ'),
                        const SizedBox(height: 10),
                        _OptionRow(
                          options: sizes,
                          selected: _size ?? sizes.first,
                          onSelect: (s) => setState(() => _size = s),
                        ),
                      ],
                      if (colors.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _SelectorLabel('Màu sắc'),
                        const SizedBox(height: 10),
                        _OptionRow(
                          options: colors,
                          selected: _color ?? colors.first,
                          onSelect: (s) => setState(() => _color = s),
                        ),
                      ],
                      const SizedBox(height: 20),
                      _SelectorLabel('Số lượng'),
                      const SizedBox(height: 10),
                      _QtyStepper(
                        qty: _qty,
                        max: stock,
                        onChanged: (q) => setState(() => _qty = q),
                      ),
                      const SizedBox(height: 28),
                      Divider(color: c.border.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),

                      // Reviews Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Đánh giá & Nhận xét',
                            style: TextStyle(
                              color: c.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _showReviewForm,
                            icon: Icon(Icons.rate_review_outlined, size: 16, color: c.secondary),
                            label: Text(
                              'Viết đánh giá',
                              style: TextStyle(color: c.secondary, fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (_loadingReviews)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(color: c.secondary, strokeWidth: 2),
                          ),
                        )
                      else if (_reviews.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: c.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'Chưa có đánh giá nào cho sản phẩm này.',
                              style: TextStyle(color: c.textMuted, fontSize: 13),
                            ),
                          ),
                        )
                      else
                        ..._reviews.map((r) => Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: c.surfaceVariant,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: c.border.withValues(alpha: 0.4)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: c.secondary.withValues(alpha: 0.2),
                                        child: Text(
                                          r.userName.isNotEmpty ? r.userName[0].toUpperCase() : '?',
                                          style: TextStyle(color: c.secondary, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          r.userName,
                                          style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                                        ),
                                      ),
                                      Row(
                                        children: List.generate(
                                          5,
                                          (i) => Icon(
                                            Icons.star_rounded,
                                            size: 15,
                                            color: i < r.rating ? c.secondary : c.textMuted.withValues(alpha: 0.3),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if ((r.comment ?? '').isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      r.comment!,
                                      style: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.4),
                                    ),
                                  ],
                                ],
                              ),
                            )),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        _BottomBar(
          onAddToCart: () => _addToCart(p),
          onBuyNow: () => _addToCart(p, buyNow: true),
          disabled: stock <= 0,
        ),
      ],
    );
  }
}

class _ImageHeader extends StatelessWidget {
  final Product product;
  final bool favorite;
  const _ImageHeader({required this.product, required this.favorite});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(28),
          ),
          child: SizedBox(
            height: 380,
            width: double.infinity,
            child: product.imageUrl.isEmpty
                ? Container(color: c.surfaceVariant)
                : CachedNetworkImage(
                    imageUrl: product.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: c.surfaceVariant),
                    errorWidget: (_, __, ___) =>
                        Container(color: c.surfaceVariant),
                  ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                background: c.surface,
                onTap: () => context.pop(),
              ),
              Consumer<WishlistProvider>(
                builder: (context, wishlist, _) => CircleIconButton(
                  icon: wishlist.isFavorite(product.id)
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  foreground: wishlist.isFavorite(product.id)
                      ? c.danger
                      : c.textPrimary,
                  background: c.surface,
                  onTap: () async {
                    try {
                      await wishlist.toggleWishlist(product);
                    } catch (_) {}
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OptionRow extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;
  const _OptionRow({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final o in options)
          GestureDetector(
            onTap: () => onSelect(o),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: o == selected ? c.inkCard : c.surfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Text(
                o,
                style: TextStyle(
                  color: o == selected ? c.onInk : c.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _QtyStepper extends StatelessWidget {
  final int qty;
  final int max;
  final ValueChanged<int> onChanged;
  const _QtyStepper(
      {required this.qty, required this.max, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    Widget btn(IconData icon, VoidCallback? onTap) => GestureDetector(
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: c.textPrimary),
          ),
        );
    return Row(
      children: [
        btn(Icons.remove_rounded, qty > 1 ? () => onChanged(qty - 1) : null),
        SizedBox(
          width: 48,
          child: Center(
            child: Text(
              '$qty',
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        btn(Icons.add_rounded,
            (max <= 0 || qty < max) ? () => onChanged(qty + 1) : null),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;
  final bool disabled;
  const _BottomBar({
    required this.onAddToCart,
    required this.onBuyNow,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(
        color: c.surface,
        boxShadow: [
          BoxShadow(
            color: c.shadow,
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: PrimaryButton(
              label: 'Mua ngay',
              icon: Icons.bolt_rounded,
              onPressed: disabled ? null : onBuyNow,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SecondaryButton(
              label: 'Thêm giỏ',
              icon: Icons.shopping_bag_outlined,
              onPressed: disabled ? null : onAddToCart,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectorLabel extends StatelessWidget {
  final String text;
  const _SelectorLabel(this.text);
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Text(
      text,
      style: TextStyle(
        color: c.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _CategoryChipLabel extends StatelessWidget {
  final String label;
  const _CategoryChipLabel({required this.label});
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.primarySoft,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: c.secondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final int stock;
  const _StockBadge({required this.stock});
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final inStock = stock > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: (inStock ? c.success : c.danger).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Text(
        inStock ? 'Còn $stock sản phẩm' : 'Hết hàng',
        style: TextStyle(
          color: inStock ? c.success : c.danger,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onBack;
  const _ErrorView({required this.onBack});
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: c.textMuted, size: 44),
            const SizedBox(height: 12),
            Text('Không tải được sản phẩm',
                style: TextStyle(color: c.textSecondary)),
            const SizedBox(height: 16),
            SecondaryButton(
              label: 'Quay lại',
              expanded: false,
              onPressed: onBack,
            ),
          ],
        ),
      ),
    );
  }
}
