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
  bool _gridView = true;
  final _searchCtrl = TextEditingController();

  int _selectedPriceIndex = 0;
  final List<Map<String, dynamic>> _priceFilters = [
    {'label': 'Tất cả giá', 'min': null, 'max': null},
    {'label': 'Dưới 200k', 'min': null, 'max': 200000},
    {'label': '200k - 500k', 'min': 200000, 'max': 500000},
    {'label': '500k - 1Tr', 'min': 500000, 'max': 1000000},
    {'label': 'Trên 1Tr', 'min': 1000000, 'max': null},
  ];

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    try {
      if (mounted) setState(() => _loading = true);
      
      final price = _priceFilters[_selectedPriceIndex];
      String url = '${ApiConfig.apiBase}/products?limit=100';
      if (price['min'] != null) url += '&minPrice=${price['min']}';
      if (price['max'] != null) url += '&maxPrice=${price['max']}';

      final res = await Future.wait([
        http.get(Uri.parse(url)),
        http.get(Uri.parse('${ApiConfig.apiBase}/categories')),
      ]);
      final pd = jsonDecode(res[0].body);
      final cd = jsonDecode(res[1].body);
      final List pl = pd is List ? pd : (pd['data'] ?? pd['items'] ?? []);
      final List cl = cd is List ? cd : (cd['data'] ?? []);
      if (mounted) setState(() {
        _products = pl.map((e) => Product.fromJson(e)).toList();
        _categories = cl.map((e) => Category.fromJson(e)).toList();
        _loading = false;
      });
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
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearch(),
            _buildCategories(),
            _buildPriceFilters(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  : filtered.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: AppTheme.primary,
                          backgroundColor: AppTheme.surface2,
                          child: _gridView ? _buildGrid(filtered) : _buildList(filtered),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    child: Row(
      children: [
        const Text('Sản phẩm', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
        const Spacer(),
        _IconBtn(
          icon: _gridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
          onTap: () => setState(() => _gridView = !_gridView),
        ),
      ],
    ),
  );

  Widget _buildSearch() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    child: Container(
      height: 46,
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: const InputDecoration(
          hintText: 'Tìm kiếm sản phẩm...',
          hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    ),
  );

  Widget _buildCategories() => SizedBox(
    height: 44,
    child: ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      scrollDirection: Axis.horizontal,
      itemCount: _categories.length + 1,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, i) {
        final isAll = i == 0;
        final id = isAll ? 'all' : _categories[i - 1].id;
        final label = isAll ? 'Tất cả' : _categories[i - 1].name;
        final selected = _selectedCatId == id;
        return GestureDetector(
          onTap: () => setState(() => _selectedCatId = id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              gradient: selected ? AppTheme.primaryGradient : null,
              color: selected ? null : AppTheme.surface2,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: selected ? Colors.transparent : AppTheme.border),
              boxShadow: selected ? [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))] : null,
            ),
            child: Center(
              child: Text(label,
                style: TextStyle(
                  color: selected ? Colors.black : AppTheme.textSecondary,
                  fontSize: 13, fontWeight: FontWeight.w700,
                )),
            ),
          ),
        );
      },
    ),
  );

  Widget _buildPriceFilters() => SizedBox(
    height: 38,
    child: ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      scrollDirection: Axis.horizontal,
      itemCount: _priceFilters.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, i) {
        final selected = _selectedPriceIndex == i;
        return GestureDetector(
          onTap: () {
            setState(() => _selectedPriceIndex = i);
            _load(); // Reload from backend with new price params
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: selected ? AppTheme.primary : AppTheme.surface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selected ? AppTheme.primary : AppTheme.border),
            ),
            child: Center(
              child: Text(_priceFilters[i]['label'],
                style: TextStyle(
                  color: selected ? Colors.black : AppTheme.textSecondary,
                  fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                )),
            ),
          ),
        );
      },
    ),
  );

  Widget _buildGrid(List<Product> list) => GridView.builder(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.68,
    ),
    itemCount: list.length,
    itemBuilder: (_, i) => _GridCard(product: list[i]),
  );

  Widget _buildList(List<Product> list) => ListView.separated(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
    itemCount: list.length,
    separatorBuilder: (_, __) => const SizedBox(height: 10),
    itemBuilder: (_, i) => _ListCard(product: list[i]),
  );

  Widget _buildEmpty() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.search_off_rounded, size: 64, color: AppTheme.textMuted),
      const SizedBox(height: 12),
      const Text('Không tìm thấy sản phẩm', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      TextButton(onPressed: () { 
        _searchCtrl.clear(); 
        setState(() {
          _selectedCatId = 'all';
          _selectedPriceIndex = 0;
        });
        _load();
      }, child: const Text('Xoá bộ lọc', style: TextStyle(color: AppTheme.primary))),
    ]),
  );
}

class _GridCard extends StatelessWidget {
  final Product product;
  const _GridCard({required this.product});
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: (product.thumbnailUrl ?? "").isNotEmpty
                  ? CachedNetworkImage(imageUrl: (product.thumbnailUrl ?? ""), fit: BoxFit.cover,
                      placeholder: (_, __) => _placeholder(product.name),
                      errorWidget: (_, __, ___) => _placeholder(product.name))
                  : _placeholder(product.name),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, height: 1.3)),
              const SizedBox(height: 5),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(_fmt(product.price) + 'đ', style: const TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w800)),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.add_rounded, color: AppTheme.primary, size: 16),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
  Widget _placeholder(String n) => Container(color: AppTheme.surface2, child: Center(child: Text(n.isNotEmpty ? n[0].toUpperCase() : '?', style: const TextStyle(color: AppTheme.primary, fontSize: 36, fontWeight: FontWeight.w900))));
  String _fmt(num p) { final s = p.toStringAsFixed(0); final b = StringBuffer(); for (int i = 0; i < s.length; i++) { if (i > 0 && (s.length - i) % 3 == 0) b.write('.'); b.write(s[i]); } return b.toString(); }
}

class _ListCard extends StatelessWidget {
  final Product product;
  const _ListCard({required this.product});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/products/${product.id}'),
      child: Container(
        height: 96,
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
        child: Row(children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            child: SizedBox(
              width: 90,
              child: (product.thumbnailUrl ?? "").isNotEmpty
                  ? CachedNetworkImage(imageUrl: (product.thumbnailUrl ?? ""), fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: AppTheme.surface2, child: Center(child: Text(product.name.isNotEmpty ? product.name[0] : '?', style: const TextStyle(color: AppTheme.primary, fontSize: 28, fontWeight: FontWeight.w900)))))
                  : Container(color: AppTheme.surface2, child: Center(child: Text(product.name.isNotEmpty ? product.name[0] : '?', style: const TextStyle(color: AppTheme.primary, fontSize: 28, fontWeight: FontWeight.w900)))),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, height: 1.3)),
                const SizedBox(height: 6),
                Text('${_fmt(product.price)}đ', style: const TextStyle(color: AppTheme.primary, fontSize: 14, fontWeight: FontWeight.w800)),
              ]),
            ),
          ),
          const Padding(padding: EdgeInsets.only(right: 12), child: Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textMuted, size: 14)),
        ]),
      ),
    );
  }
  String _fmt(num p) { final s = p.toStringAsFixed(0); final b = StringBuffer(); for (int i = 0; i < s.length; i++) { if (i > 0 && (s.length - i) % 3 == 0) b.write('.'); b.write(s[i]); } return b.toString(); }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40, height: 40,
      decoration: BoxDecoration(color: AppTheme.surface2, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
      child: Icon(icon, color: AppTheme.textSecondary, size: 20),
    ),
  );
}
