import 'package:flutter/foundation.dart' hide Category;
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/view_state.dart';
import '../../data/models/product_model.dart';

class ProductProvider extends ChangeNotifier {
  final DioClient _dioClient;

  ProductProvider({DioClient? dioClient})
      : _dioClient = dioClient ?? DioClient.instance;

  ViewState<List<Product>> _productsState = ViewState.initial();
  ViewState<List<Product>> get productsState => _productsState;

  ViewState<List<Category>> _categoriesState = ViewState.initial();
  ViewState<List<Category>> get categoriesState => _categoriesState;

  List<Product> get allProducts => _productsState.data ?? [];
  List<Category> get categories => _categoriesState.data ?? [];

  String _selectedCategory = 'all';
  String get selectedCategory => _selectedCategory;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  void setSelectedCategory(String catId) {
    if (_selectedCategory == catId) return;
    _selectedCategory = catId;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  List<Product> get filteredProducts {
    var list = allProducts;
    if (_selectedCategory != 'all') {
      final target = _selectedCategory.trim().toLowerCase();
      list = list.where((p) {
        if (p.categoryId.toLowerCase() == target) return true;
        return categories.any((c) =>
            (c.id.toLowerCase() == target ||
                c.slug.toLowerCase() == target ||
                c.name.toLowerCase() == target) &&
            p.categoryId.toLowerCase() == c.id.toLowerCase());
      }).toList();
    }

    if (_searchQuery.isNotEmpty) {
      list = list.where((p) {
        return p.name.toLowerCase().contains(_searchQuery) ||
            (p.description?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }

    return list;
  }

  /// Tải đồng thời danh mục và sản phẩm từ API
  Future<void> fetchAll({bool forceRefresh = false}) async {
    if (!forceRefresh && _productsState.isSuccess && _categoriesState.isSuccess) {
      return;
    }

    _productsState = ViewState.loading(_productsState.data);
    _categoriesState = ViewState.loading(_categoriesState.data);
    notifyListeners();

    try {
      final results = await Future.wait([
        _dioClient.dio.get('/products', queryParameters: {'limit': 200}),
        _dioClient.dio.get('/categories'),
      ]);

      final pData = results[0].data;
      final cData = results[1].data;

      final List pList = pData is List ? pData : (pData['data'] ?? pData['items'] ?? []);
      final List cList = cData is List ? cData : (cData['data'] ?? []);

      final products = pList.map((e) => Product.fromJson(e)).toList();
      final categories = cList.map((e) => Category.fromJson(e)).toList();

      _productsState = ViewState.success(products);
      _categoriesState = ViewState.success(categories);
    } catch (e) {
      _productsState = ViewState.error(e.toString(), _productsState.data);
      _categoriesState = ViewState.error(e.toString(), _categoriesState.data);
    } finally {
      notifyListeners();
    }
  }

  /// Tải chi tiết một sản phẩm
  Future<Product> getProductDetail(String id) async {
    try {
      final response = await _dioClient.dio.get('/products/$id');
      final data = response.data;
      final Map<String, dynamic> json = data is Map<String, dynamic>
          ? (data['data'] is Map<String, dynamic> ? data['data'] : data)
          : {};
      return Product.fromJson(json);
    } catch (e) {
      throw 'Không thể tải chi tiết sản phẩm: $e';
    }
  }
}
