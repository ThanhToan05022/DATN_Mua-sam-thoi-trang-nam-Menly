import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/auth_guard.dart';
import '../../data/models/product_model.dart';
import '../../../cart/data/cart_model.dart';
import '../../../wishlist/presentation/providers/wishlist_provider.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;
  const ProductDetailPage({super.key, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  Product? _product;
  bool _loading = true;
  String? _errorMessage;
  ProductVariant? _selectedVariant;
  String? _selectedSize;
  String? _selectedColor;
  int _qty = 1;
  bool _addedToCart = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final res = await DioClient.instance.dio.get(
        '/products/${widget.productId}',
      );
      final data = res.data;
      final Map<String, dynamic> json = data is Map<String, dynamic>
          ? (data['data'] is Map<String, dynamic> ? data['data'] : data)
          : {};

      if (mounted) {
        setState(() {
          _product = Product.fromJson(json);
          if (_product!.variants.isNotEmpty) {
            _selectedVariant = _product!.variants.first;
            _selectedSize = _selectedVariant?.size;
            _selectedColor = _selectedVariant?.color;
          }
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _addToCart() {
    if (_selectedVariant == null || _product == null) return;

    if (!AuthGuard.check(
      context,
      actionTitle: 'Đăng nhập để mua hàng',
      actionMessage:
          'Bạn đang duyệt ẩn danh. Vui lòng đăng nhập tài khoản để thêm "${_product!.name}" vào giỏ hàng và tiến hành mua đồ.',
    )) {
      return;
    }

    context.read<CartProvider>().addItem(_product!, _selectedVariant!, _qty);
    setState(() => _addedToCart = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _addedToCart = false);
    });
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('✅ Đã thêm vào giỏ hàng'),
        duration: const Duration(seconds: 2),
        persist: false,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'Xem giỏ',
          textColor: AppTheme.primary,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            context.go('/cart');
          },
        ),
      ),
    );
  }

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
    return Scaffold(
      backgroundColor: AppTheme.bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/products');
            }
          },
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Icon(
              Icons.arrow_back_ios_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
        actions: [
          // Wishlist Action
          Consumer<WishlistProvider>(
            builder: (context, wishlist, _) {
              final isFav =
                  _product != null && wishlist.isFavorite(_product!.id);
              return Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: IconButton(
                  icon: Icon(
                    isFav
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isFav ? Colors.redAccent : Colors.white,
                    size: 18,
                  ),
                  tooltip: isFav ? 'Bỏ thích' : 'Yêu thích',
                  onPressed: () {
                    if (_product != null) {
                      if (!AuthGuard.check(
                        context,
                        actionTitle: 'Đăng nhập để lưu yêu thích',
                        actionMessage:
                            'Vui lòng đăng nhập để lưu "${_product!.name}" vào danh sách yêu thích của bạn.',
                      )) {
                        return;
                      }
                      wishlist.toggleWishlist(_product!);
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isFav
                                ? 'Đã xóa "${_product!.name}" khỏi danh sách yêu thích'
                                : 'Đã thêm "${_product!.name}" vào danh sách yêu thích ❤️',
                          ),
                          persist: false,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(0, 8, 8, 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.shopping_bag_outlined,
                color: Colors.white,
                size: 18,
              ),
              onPressed: () => context.go('/cart'),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : _product == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppTheme.error,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage ?? 'Không tìm thấy sản phẩm',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _load,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            )
          : _buildBody(),
      bottomNavigationBar: _product == null || _loading
          ? null
          : _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    final p = _product!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero image
          SizedBox(
            height: 380,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                p.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: p.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppTheme.surface2,
                          child: Center(
                            child: Text(
                              p.name.isNotEmpty ? p.name[0] : '?',
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 80,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppTheme.surface2,
                          child: Center(
                            child: Text(
                              p.name.isNotEmpty ? p.name[0] : '?',
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 80,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Container(
                        color: AppTheme.surface2,
                        child: Center(
                          child: Text(
                            p.name.isNotEmpty ? p.name[0] : '?',
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontSize: 80,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                // Bottom gradient
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppTheme.bg.withOpacity(0.95),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title & price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        p.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${_fmt(p.price)}đ',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: AppTheme.primary,
                      size: 16,
                    ),
                    const Text(
                      ' 4.8 ',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '• ${p.stock} còn lại',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                // Description
                if (p.description != null && p.description!.isNotEmpty) ...[
                  const Text(
                    'Mô tả',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p.description!,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Variants
                if (p.variants.isNotEmpty) ...[
                  Builder(
                    builder: (context) {
                      final uniqueSizes = <String>[];
                      for (final v in p.variants) {
                        final s = v.size.trim();
                        if (s.isNotEmpty && !uniqueSizes.contains(s)) {
                          uniqueSizes.add(s);
                        }
                      }

                      final uniqueColors = <String>[];
                      for (final v in p.variants) {
                        final c = v.color.trim();
                        if (c.isNotEmpty && !uniqueColors.contains(c)) {
                          uniqueColors.add(c);
                        }
                      }

                      if (uniqueSizes.isEmpty && uniqueColors.isEmpty) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Chọn phân loại',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: p.variants.map((v) {
                                final sel = v.id == _selectedVariant?.id;
                                return GestureDetector(
                                  onTap: () => setState(() => _selectedVariant = v),
                                  child: _buildVariantPill(
                                    label: v.sku.isNotEmpty ? v.sku : 'Mặc định',
                                    selected: sel,
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 20),
                          ],
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Chọn phân loại',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Size section (Bên trên là Size)
                          if (uniqueSizes.isNotEmpty) ...[
                            Row(
                              children: [
                                const Text(
                                  'Kích thước',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (_selectedSize != null) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '($_selectedSize)',
                                    style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: uniqueSizes.map((size) {
                                final sel = size == _selectedSize;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedSize = size;
                                      final match = p.variants.cast<ProductVariant?>().firstWhere(
                                        (v) => v?.size == size && v?.color == _selectedColor,
                                        orElse: () => p.variants.cast<ProductVariant?>().firstWhere(
                                          (v) => v?.size == size,
                                          orElse: () => p.variants.first,
                                        ),
                                      );
                                      if (match != null) {
                                        _selectedVariant = match;
                                        _selectedColor = match.color;
                                      }
                                    });
                                  },
                                  child: _buildVariantPill(
                                    label: size,
                                    selected: sel,
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Color section (Bên dưới là Màu)
                          if (uniqueColors.isNotEmpty) ...[
                            Row(
                              children: [
                                const Text(
                                  'Màu sắc',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (_selectedColor != null) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '($_selectedColor)',
                                    style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: uniqueColors.map((color) {
                                final sel = color == _selectedColor;
                                final isAvailableForSize = p.variants.any(
                                  (v) => v.size == _selectedSize && v.color == color,
                                );
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedColor = color;
                                      final match = p.variants.cast<ProductVariant?>().firstWhere(
                                        (v) => v?.color == color && v?.size == _selectedSize,
                                        orElse: () => p.variants.cast<ProductVariant?>().firstWhere(
                                          (v) => v?.color == color,
                                          orElse: () => p.variants.first,
                                        ),
                                      );
                                      if (match != null) {
                                        _selectedVariant = match;
                                        _selectedSize = match.size;
                                      }
                                    });
                                  },
                                  child: _buildVariantPill(
                                    label: color,
                                    selected: sel,
                                    dimmed: !isAvailableForSize,
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ],
                      );
                    },
                  ),
                ],

                // Quantity
                const Text(
                  'Số lượng',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _QtyBtn(
                      icon: Icons.remove_rounded,
                      onTap: () {
                        if (_qty > 1) setState(() => _qty--);
                      },
                    ),
                    Container(
                      width: 52,
                      height: 44,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Center(
                        child: Text(
                          '$_qty',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    _QtyBtn(
                      icon: Icons.add_rounded,
                      onTap: () => setState(() => _qty++),
                    ),
                  ],
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariantPill({
    required String label,
    required bool selected,
    bool dimmed = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        gradient: selected ? AppTheme.primaryGradient : null,
        color: selected ? null : AppTheme.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected
              ? Colors.transparent
              : (dimmed ? AppTheme.border.withOpacity(0.3) : AppTheme.border),
          width: 1.5,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected
              ? Colors.black
              : (dimmed ? AppTheme.textMuted : AppTheme.textSecondary),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildBottomBar() => Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      border: Border(top: BorderSide(color: AppTheme.border)),
    ),
    child: Row(
      children: [
        // Wishlist toggle
        Consumer<WishlistProvider>(
          builder: (context, wishlist, _) {
            final isFav = _product != null && wishlist.isFavorite(_product!.id);
            return GestureDetector(
              onTap: () {
                if (_product != null) {
                  if (!AuthGuard.check(
                    context,
                    actionTitle: 'Đăng nhập để lưu yêu thích',
                    actionMessage:
                        'Vui lòng đăng nhập để lưu "${_product!.name}" vào danh sách yêu thích của bạn.',
                  )) {
                    return;
                  }
                  wishlist.toggleWishlist(_product!);
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isFav
                            ? 'Đã xóa "${_product!.name}" khỏi danh sách yêu thích'
                            : 'Đã thêm "${_product!.name}" vào danh sách yêu thích ❤️',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isFav
                      ? Colors.redAccent.withOpacity(0.15)
                      : AppTheme.surface2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isFav ? Colors.redAccent : AppTheme.border,
                  ),
                ),
                child: Icon(
                  isFav
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFav ? Colors.redAccent : AppTheme.textMuted,
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 12),
        // Add to cart
        Expanded(
          child: GestureDetector(
            onTap: _addToCart,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 52,
              decoration: BoxDecoration(
                gradient: _addedToCart
                    ? const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      )
                    : AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _addedToCart ? '✅ Đã thêm!' : 'Thêm vào giỏ hàng',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Icon(icon, color: AppTheme.primary, size: 22),
    ),
  );
}
