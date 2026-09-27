import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/product_model.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});
  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  List<Product> _products = [];
  List<Category> _categories = [];
  String _selectedCatId = 'all';
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await Future.wait([
        http.get(Uri.parse('${ApiConfig.apiBase}/products?limit=50')),
        http.get(Uri.parse('${ApiConfig.apiBase}/categories')),
      ]);
      final prodData = jsonDecode(res[0].body);
      final catData = jsonDecode(res[1].body);
      final List prodList = prodData is List ? prodData : (prodData['data'] ?? prodData['items'] ?? []);
      final List catList = catData is List ? catData : (catData['data'] ?? []);
      if (mounted) {
        setState(() {
          _products = prodList.map((e) => Product.fromJson(e)).toList();
          _categories = catList.map((e) => Category.fromJson(e)).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Product> get _filtered {
    var list = _products;
    if (_selectedCatId != 'all') list = list.where((p) => p.categoryId == _selectedCatId).toList();
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) list = list.where((p) => p.name.toLowerCase().contains(q)).toList();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sản phẩm'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Tìm kiếm sản phẩm...',
                    prefixIcon: Icon(Icons.search, color: AppTheme.textMuted, size: 18),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _CatChip(label: 'Tất cả', selected: _selectedCatId == 'all', onTap: () => setState(() => _selectedCatId = 'all')),
                    ..._categories.map((c) => _CatChip(
                      label: c.name,
                      selected: _selectedCatId == c.id,
                      onTap: () => setState(() => _selectedCatId = c.id),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, childAspectRatio: 0.68, crossAxisSpacing: 12, mainAxisSpacing: 12,
              ),
              itemCount: _filtered.length,
              itemBuilder: (ctx, i) => _ProductTile(product: _filtered[i]),
            ),
    );
  }
}

class _CatChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CatChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? AppTheme.primary : AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? AppTheme.primary : AppTheme.border),
      ),
      child: Text(label, style: TextStyle(
        color: selected ? Colors.black : AppTheme.textSecondary,
        fontSize: 12, fontWeight: FontWeight.w600,
      )),
    ),
  );
}

class _ProductTile extends StatelessWidget {
  final Product product;
  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/products/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 1,
                child: product.thumbnailUrl != null
                    ? CachedNetworkImage(imageUrl: product.thumbnailUrl!, fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _placeholder())
                    : _placeholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text('${_fmt(product.price)} đ',
                      style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: AppTheme.surface,
    child: const Center(child: Icon(Icons.checkroom_rounded, color: AppTheme.border, size: 40)),
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
