import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/auth_guard.dart';
import '../../../../core/widgets/product_card.dart';
import '../../../cart/data/cart_model.dart';
import '../../../wishlist/presentation/providers/wishlist_provider.dart';
import '../../data/models/product_model.dart';
import '../providers/product_provider.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/product_empty_view.dart';
import '../widgets/product_list_card.dart';
import '../widgets/product_list_header.dart';
import '../widgets/product_search_bar.dart';
import '../widgets/product_skeleton_grid.dart';
import '../widgets/product_sort_bar.dart';

class ProductListPage extends StatefulWidget {
  final String? initialCategoryId;
  const ProductListPage({super.key, this.initialCategoryId});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  late String _selectedCatId;
  bool _gridView = true;
  String _sortBy = 'default';
  final _searchCtrl = TextEditingController();
  final _catScrollCtrl = ScrollController();

  int _selectedPriceIndex = 0;
  final List<Map<String, dynamic>> _priceFilters = const [
    {'label': 'Tất cả giá', 'min': null, 'max': null},
    {'label': 'Dưới 200k', 'min': null, 'max': 200000},
    {'label': '200k - 500k', 'min': 200000, 'max': 500000},
    {'label': '500k - 1Tr', 'min': 500000, 'max': 1000000},
    {'label': 'Trên 1Tr', 'min': 1000000, 'max': null},
  ];

  @override
  void initState() {
    super.initState();
    _selectedCatId = widget.initialCategoryId ?? 'all';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pProvider = context.read<ProductProvider>();
      pProvider.fetchAll();
      context.read<WishlistProvider>().fetchWishlist();
      _scrollToSelected();
    });
  }

  @override
  void didUpdateWidget(covariant ProductListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final targetCat = widget.initialCategoryId ?? 'all';
    if (targetCat != _selectedCatId) {
      setState(() => _selectedCatId = targetCat);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _catScrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToSelected() {
    if (!mounted || !_catScrollCtrl.hasClients || _selectedCatId == 'all') return;
    final categories = context.read<ProductProvider>().categories;
    final target = _selectedCatId.trim().toLowerCase();
    final idx = categories.indexWhere((c) =>
        c.id.toLowerCase() == target ||
        c.slug.toLowerCase() == target ||
        c.name.toLowerCase() == target);
    if (idx != -1) {
      final itemIndex = idx + 1;
      final offset = (itemIndex * 95.0) - 40.0;
      _catScrollCtrl.animateTo(
        offset.clamp(0.0, _catScrollCtrl.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  List<Product> _filterProducts(List<Product> products, List<Category> categories) {
    var list = products;
    if (_selectedCatId != 'all') {
      final target = _selectedCatId.trim().toLowerCase();
      list = list.where((p) {
        if (p.categoryId.trim().toLowerCase() == target) return true;
        return categories.any((c) =>
            (c.id.toLowerCase() == target ||
                c.slug.toLowerCase() == target ||
                c.name.toLowerCase() == target) &&
            c.id.toLowerCase() == p.categoryId.trim().toLowerCase());
      }).toList();
    }
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((p) => p.name.toLowerCase().contains(q)).toList();
    }

    final priceFilter = _priceFilters[_selectedPriceIndex];
    if (priceFilter['min'] != null) {
      final minVal = priceFilter['min'] as int;
      list = list.where((p) => p.price >= minVal).toList();
    }
    if (priceFilter['max'] != null) {
      final maxVal = priceFilter['max'] as int;
      list = list.where((p) => p.price <= maxVal).toList();
    }

    final sortedList = List<Product>.from(list);
    switch (_sortBy) {
      case 'price_asc':
        sortedList.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        sortedList.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'newest':
        sortedList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      default:
        break;
    }

    return sortedList;
  }

  Widget _buildPriceFilters(AppColors c) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _priceFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final selected = _selectedPriceIndex == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedPriceIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: selected ? c.secondary : c.surfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                border: Border.all(
                  color: selected ? c.secondary : c.border,
                ),
              ),
              child: Center(
                child: Text(
                  _priceFilters[i]['label'] as String,
                  style: TextStyle(
                    color: selected ? Colors.black : c.textSecondary,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pProvider = context.watch<ProductProvider>();
    final productsState = pProvider.productsState;
    final categories = pProvider.categories;
    final filtered = _filterProducts(productsState.data ?? [], categories);
    final c = AppColors.of(context);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header (Tiêu đề, Wishlist badge, Toggle Grid/List)
            ProductListHeader(
              isGridView: _gridView,
              onToggleView: () => setState(() => _gridView = !_gridView),
            ),

            // 2. Ô tìm kiếm sản phẩm
            ProductSearchBar(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              onClear: () => setState(() {}),
            ),

            // 3. Thanh lọc danh mục ngang
            CategoryFilterBar(
              scrollController: _catScrollCtrl,
              categories: categories,
              selectedCatId: _selectedCatId,
              onSelectCategory: (id) => setState(() => _selectedCatId = id),
            ),

            const SizedBox(height: 6),

            // 3.5. Thanh lọc theo khoảng giá
            _buildPriceFilters(c),

            // 4. Thanh sắp xếp (giá tiền tăng/giảm, mới nhất, mặc định)
            ProductSortBar(
              totalCount: filtered.length,
              currentSort: _sortBy,
              onSortChanged: (newSort) => setState(() => _sortBy = newSort),
            ),

            // 5. Nội dung danh sách sản phẩm theo trạng thái
            Expanded(
              child: productsState.isLoading &&
                      (productsState.data == null || productsState.data!.isEmpty)
                  ? const ProductSkeletonGrid()
                  : productsState.isError &&
                          (productsState.data == null ||
                              productsState.data!.isEmpty)
                      ? ProductErrorView(
                          error: productsState.message ?? 'Đã có lỗi xảy ra',
                          onRetry: () => context
                              .read<ProductProvider>()
                              .fetchAll(forceRefresh: true),
                        )
                      : filtered.isEmpty
                          ? ProductEmptyView(
                              onClearFilters: () {
                                _searchCtrl.clear();
                                setState(() {
                                  _selectedCatId = 'all';
                                  _selectedPriceIndex = 0;
                                  _sortBy = 'default';
                                });
                              },
                            )
                          : RefreshIndicator(
                              onRefresh: () async {
                                await Future.wait([
                                  pProvider.fetchAll(forceRefresh: true),
                                  context
                                      .read<WishlistProvider>()
                                      .fetchWishlist(forceRefresh: true),
                                ]);
                              },
                              color: c.secondary,
                              backgroundColor: c.surfaceVariant,
                              child: _gridView
                                  ? GridView.builder(
                                      padding: EdgeInsets.fromLTRB(16, 12, 16,
                                          MediaQuery.of(context).padding.bottom +
                                              96),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 14,
                                        mainAxisSpacing: 16,
                                        childAspectRatio: 0.55,
                                      ),
                                      itemCount: filtered.length,
                                      itemBuilder: (_, i) =>
                                          _GridTile(product: filtered[i]),
                                    )
                                  : ListView.separated(
                                      padding: EdgeInsets.fromLTRB(16, 12, 16,
                                          MediaQuery.of(context).padding.bottom +
                                              96),
                                      itemCount: filtered.length,
                                      separatorBuilder: (_, _) =>
                                          const SizedBox(height: 10),
                                      itemBuilder: (_, i) => ProductListCard(
                                          product: filtered[i]),
                                    ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grid tile wiring the shared [ProductCard] to wishlist, navigation and a
/// quick add-to-cart so the catalog grid matches the rest of the app.
class _GridTile extends StatelessWidget {
  final Product product;
  const _GridTile({required this.product});

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
      onAdd: () {
        if (product.variants.isEmpty) {
          context.push('/products/${product.id}');
          return;
        }
        if (!AuthGuard.check(context, redirectPath: '/products')) return;
        context.read<CartProvider>().addItem(product, product.variants.first, 1);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã thêm vào giỏ hàng')),
        );
      },
    );
  }
}
