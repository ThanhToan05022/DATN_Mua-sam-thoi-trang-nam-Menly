import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../product/data/models/product_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Product> _featured = [];
  List<Category> _categories = [];
  bool _loading = true;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _load();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _userName = prefs.getString('userName') ?? '');
  }

  Future<void> _load() async {
    try {
      final res = await Future.wait([
        http.get(Uri.parse('${ApiConfig.apiBase}/products?limit=10')),
        http.get(Uri.parse('${ApiConfig.apiBase}/categories')),
      ]);
      final pd = jsonDecode(res[0].body);
      final cd = jsonDecode(res[1].body);
      final List pl = pd is List ? pd : (pd['data'] ?? pd['items'] ?? []);
      final List cl = cd is List ? cd : (cd['data'] ?? []);
      if (mounted) {
        setState(() {
          _featured = pl.map((e) => Product.fromJson(e)).toList();
          _categories = cl.map((e) => Category.fromJson(e)).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.primary,
        backgroundColor: AppTheme.surface2,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            if (_loading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppTheme.primary)))
            else ...[
              _buildBanner(),
              _buildSectionHeader('Danh mục', onSeeAll: () => context.go('/products')),
              _buildCategories(),
              _buildSectionHeader('Sản phẩm nổi bật', onSeeAll: () => context.go('/products')),
              _buildFeaturedGrid(),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      snap: true,
      backgroundColor: AppTheme.bg,
      elevation: 0,
      title: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(child: Text('M', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18))),
        ),
        const SizedBox(width: 10),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MENLY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2)),
            Text('Thời trang nam', style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w500)),
          ],
        ),
      ]),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
          onPressed: () => context.go('/products'),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: AppTheme.textSecondary),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildBanner() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [Color(0xFF1a1028), Color(0xFF0d0a1a)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: AppTheme.border),
        ),
        child: Stack(
          children: [
            // Glow
            Positioned(top: -30, right: -30, child: Container(
              width: 150, height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [AppTheme.primary.withOpacity(0.25), Colors.transparent]),
              ),
            )),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                    ),
                    child: const Text('🔥 NEW COLLECTION', style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _userName.isNotEmpty ? 'Chào, $_userName!' : 'Phong cách\nđỉnh cao',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, height: 1.2),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => context.go('/products'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: const Text('Khám phá ngay', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 13)),
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

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            if (onSeeAll != null)
              GestureDetector(
                onTap: onSeeAll,
                child: const Text('Xem tất cả →', style: TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 88,
        child: _categories.isEmpty
            ? const Center(child: Text('Không có danh mục', style: TextStyle(color: AppTheme.textMuted)))
            : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final c = _categories[i];
                  return GestureDetector(
                    onTap: () => context.go('/products'),
                    child: Column(
                      children: [
                        Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(
                            gradient: AppTheme.cardGradient,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Center(
                            child: Text(
                              c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                              style: const TextStyle(color: AppTheme.primary, fontSize: 22, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 64,
                          child: Text(
                            c.name,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildFeaturedGrid() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) => _ProductCard(product: _featured[i]),
          childCount: _featured.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.68,
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/products/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    product.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: AppTheme.surface2, child: const Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2))),
                            errorWidget: (_, __, ___) => _imagePlaceholder(product.name),
                          )
                        : _imagePlaceholder(product.name),
                    // Gradient bottom
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, height: 1.3)),
                  const SizedBox(height: 6),
                  Text(
                    '${_fmt(product.price)}đ',
                    style: const TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder(String name) => Container(
    color: AppTheme.surface2,
    child: Center(
      child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(color: AppTheme.primary, fontSize: 36, fontWeight: FontWeight.w900)),
    ),
  );

  String _fmt(num price) {
    final s = price.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
