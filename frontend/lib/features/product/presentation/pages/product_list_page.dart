import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../wishlist/presentation/providers/wishlist_provider.dart';
import '../../data/models/product_model.dart';
import '../providers/product_provider.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/product_empty_view.dart';
import '../widgets/product_grid_card.dart';
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

  @override
  Widget build(BuildContext context) {
    final pProvider = context.watch<ProductProvider>();
    final productsState = pProvider.productsState;
    final categories = pProvider.categories;
    final filtered = _filterProducts(productsState.data ?? [], categories);

    return Scaffold(
      backgroundColor: AppTheme.bg,
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
                              color: AppTheme.primary,
                              backgroundColor: AppTheme.surface2,
                              child: _gridView
                                  ? GridView.builder(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 12, 16, 24),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                        childAspectRatio: 0.68,
                                      ),
                                      itemCount: filtered.length,
                                      itemBuilder: (_, i) => ProductGridCard(
                                          product: filtered[i]),
                                    )
                                  : ListView.separated(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 12, 16, 24),
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
