import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/product_model.dart';
import '../../data/models/review_model.dart';
import '../../../cart/data/cart_model.dart';
import '../../../auth/data/auth_model.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;
  const ProductDetailPage({super.key, required this.productId});
  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  Product? _product;
  bool _loading = true;
  ProductVariant? _selectedVariant;
  int _qty = 1;
  bool _addedToCart = false;
  List<Review> _reviews = [];
  bool _loadingReviews = true;
  double _avgRating = 5.0;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.apiBase}/products/${widget.productId}'));
      final d = jsonDecode(res.body);
      final data = d is Map && d['data'] != null ? d['data'] : d;
      if (mounted) setState(() {
        _product = Product.fromJson(data);
        if (_product!.variants.isNotEmpty) _selectedVariant = _product!.variants.first;
        _loading = false;
      });
      _loadReviews();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadReviews() async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.apiBase}/reviews/product/${widget.productId}?limit=100'));
      final d = jsonDecode(res.body);
      final data = d is Map && d['data'] != null ? d['data'] : d;
      final items = (data['items'] as List?)?.map((j) => Review.fromJson(j)).toList() ?? [];
      if (mounted) setState(() {
        _reviews = items;
        if (_reviews.isNotEmpty) {
          _avgRating = _reviews.fold(0.0, (s, r) => s + r.rating) / _reviews.length;
        }
        _loadingReviews = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingReviews = false);
    }
  }

  Future<void> _submitReview(int rating, String comment) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng đăng nhập')));
      return;
    }
    
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.apiBase}/reviews/${widget.productId}'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'rating': rating, 'comment': comment}),
      );
      final body = jsonDecode(res.body);
      if (res.statusCode == 201) {
        context.pop();
        _loadReviews();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đánh giá thành công')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(body['message'] ?? 'Lỗi')));
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi kết nối')));
    }
  }

  void _showReviewForm() {
    int rating = 5;
    final txtCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: StatefulBuilder(
          builder: (ctx, setModalState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Viết đánh giá', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => IconButton(
                  icon: Icon(Icons.star_rounded, color: index < rating ? AppTheme.primary : AppTheme.border, size: 36),
                  onPressed: () => setModalState(() => rating = index + 1),
                )),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: txtCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Nhập nhận xét của bạn...',
                  hintStyle: const TextStyle(color: AppTheme.textMuted),
                  filled: true,
                  fillColor: AppTheme.surface2,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: () => _submitReview(rating, txtCtrl.text.trim()),
                  child: const Text('Gửi đánh giá', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _addToCart() {
    if (_selectedVariant == null || _product == null) return;
    context.read<CartProvider>().addItem(_product!, _selectedVariant!, _qty);
    setState(() => _addedToCart = true);
    Future.delayed(const Duration(seconds: 2), () { if (mounted) setState(() => _addedToCart = false); });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('✅ Đã thêm vào giỏ hàng'),
        action: SnackBarAction(label: 'Xem giỏ', textColor: AppTheme.primary, onPressed: () => context.go('/cart')),
      ),
    );
  }

  String _fmt(num p) { final s = p.toStringAsFixed(0); final b = StringBuffer(); for (int i = 0; i < s.length; i++) { if (i > 0 && (s.length - i) % 3 == 0) b.write('.'); b.write(s[i]); } return b.toString(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () { if (context.canPop()) context.pop(); else context.go('/products'); },
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
            child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 18),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
            child: IconButton(icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 18), onPressed: () => context.go('/cart')),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _product == null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
                  const SizedBox(height: 12),
                  const Text('Không tìm thấy sản phẩm', style: TextStyle(color: AppTheme.textSecondary)),
                  TextButton(onPressed: () => context.go('/products'), child: const Text('Quay lại', style: TextStyle(color: AppTheme.primary))),
                ]))
              : _buildBody(),
      bottomNavigationBar: _product == null || _loading ? null : _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    final p = _product!;
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Hero image
        SizedBox(
          height: 380,
          width: double.infinity,
          child: Stack(fit: StackFit.expand, children: [
            (p.thumbnailUrl ?? "").isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: (p.thumbnailUrl ?? ""), fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(color: AppTheme.surface2, child: Center(child: Text(p.name.isNotEmpty ? p.name[0] : '?', style: const TextStyle(color: AppTheme.primary, fontSize: 80, fontWeight: FontWeight.w900)))),
                  )
                : Container(color: AppTheme.surface2, child: Center(child: Text(p.name.isNotEmpty ? p.name[0] : '?', style: const TextStyle(color: AppTheme.primary, fontSize: 80, fontWeight: FontWeight.w900)))),
            // Bottom gradient
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(height: 120, decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, AppTheme.bg.withOpacity(0.95)]),
              )),
            ),
          ]),
        ),

        // Content
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Title & price
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.2))),
              const SizedBox(width: 16),
              Text('${_fmt(p.price)}đ', style: const TextStyle(color: AppTheme.primary, fontSize: 22, fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.star_rounded, color: AppTheme.primary, size: 16),
              Text(' ${_avgRating.toStringAsFixed(1)} ', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 13)),
              Text('(${_reviews.length} đánh giá) • ${p.variants.fold(0, (s, v) => s + v.stock)} còn lại', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
            ]),

            const SizedBox(height: 20),
            // Description
            if ((p.description ?? '').isNotEmpty) ...[
              const Text('Mô tả', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(p.description ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.6)),
              const SizedBox(height: 20),
            ],

            // Variants
            if (p.variants.isNotEmpty) ...[
              const Text('Chọn phân loại', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: p.variants.map((v) {
                final sel = v.id == _selectedVariant?.id;
                return GestureDetector(
                  onTap: () => setState(() => _selectedVariant = v),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: sel ? AppTheme.primaryGradient : null,
                      color: sel ? null : AppTheme.surface2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: sel ? Colors.transparent : AppTheme.border, width: 1.5),
                      boxShadow: sel ? [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))] : null,
                    ),
                    child: Text('${v.size} / ${v.color}',
                        style: TextStyle(color: sel ? Colors.black : AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                );
              }).toList()),
              const SizedBox(height: 20),
            ],

            // Quantity
            const Text('Số lượng', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Row(children: [
              _QtyBtn(icon: Icons.remove_rounded, onTap: () { if (_qty > 1) setState(() => _qty--); }),
              Container(
                width: 52, height: 44,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: AppTheme.surface2, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
                child: Center(child: Text('$_qty', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800))),
              ),
              _QtyBtn(icon: Icons.add_rounded, onTap: () => setState(() => _qty++)),
            ]),
            const SizedBox(height: 30),

            // Reviews section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Đánh giá', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                TextButton(
                  onPressed: _showReviewForm,
                  child: const Text('Viết đánh giá', style: TextStyle(color: AppTheme.primary)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_loadingReviews)
              const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            else if (_reviews.isEmpty)
              const Text('Chưa có đánh giá nào', style: TextStyle(color: AppTheme.textMuted))
            else
              ..._reviews.map((r) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.surface2, borderRadius: BorderRadius.circular(12)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    CircleAvatar(radius: 12, backgroundColor: AppTheme.primary.withOpacity(0.2), child: Text(r.userName.isNotEmpty ? r.userName[0].toUpperCase() : '?', style: const TextStyle(color: AppTheme.primary, fontSize: 10))),
                    const SizedBox(width: 8),
                    Expanded(child: Text(r.userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13))),
                    Row(children: List.generate(5, (i) => Icon(Icons.star_rounded, size: 14, color: i < r.rating ? AppTheme.primary : AppTheme.border))),
                  ]),
                  if ((r.comment ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(r.comment!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  ],
                ]),
              )),
            
            const SizedBox(height: 100),
          ]),
        ),
      ]),
    );
  }

  Widget _buildBottomBar() => Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      border: Border(top: BorderSide(color: AppTheme.border)),
    ),
    child: Row(children: [
      // Wishlist
      Container(
        width: 52, height: 52,
        decoration: BoxDecoration(color: AppTheme.surface2, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.border)),
        child: const Icon(Icons.favorite_border_rounded, color: AppTheme.textMuted),
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
                  ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)])
                  : AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 4))],
            ),
            child: Center(
              child: Text(
                _addedToCart ? '✅ Đã thêm!' : 'Thêm vào giỏ hàng',
                style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
      ),
    ]),
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
      width: 44, height: 44,
      decoration: BoxDecoration(color: AppTheme.surface2, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
      child: Icon(icon, color: AppTheme.primary, size: 22),
    ),
  );
}
