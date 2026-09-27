import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/product_model.dart';
import '../../../cart/data/cart_model.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.apiBase}/products/${widget.productId}'));
      final data = jsonDecode(res.body);
      final json = data is Map && data.containsKey('data') ? data['data'] : data;
      if (mounted) {
        setState(() {
          _product = Product.fromJson(json);
          if (_product!.variants.isNotEmpty) _selectedVariant = _product!.variants.first;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _addToCart() {
    if (_product == null || _selectedVariant == null) return;
    context.read<CartProvider>().addItem(_product!, _selectedVariant!, _qty);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Đã thêm vào giỏ hàng!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => context.pop()),
        title: Text(_product?.name ?? 'Chi tiết sản phẩm'),
        actions: [
          Stack(
            children: [
              IconButton(icon: const Icon(Icons.shopping_bag_rounded), onPressed: () => context.go('/cart')),
              if (context.watch<CartProvider>().totalItems > 0)
                Positioned(
                  right: 8, top: 8,
                  child: Container(
                    width: 16, height: 16,
                    decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                    child: Center(
                      child: Text('${context.read<CartProvider>().totalItems}',
                          style: const TextStyle(fontSize: 9, color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _product == null
              ? const Center(child: Text('Không tìm thấy sản phẩm', style: TextStyle(color: AppTheme.textSecondary)))
              : _buildBody(),
      bottomNavigationBar: _product == null ? null : _buildBottom(),
    );
  }

  Widget _buildBody() {
    final p = _product!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.1,
            child: p.thumbnailUrl != null
                ? CachedNetworkImage(imageUrl: p.thumbnailUrl!, fit: BoxFit.cover)
                : Container(color: AppTheme.surface, child: const Center(child: Icon(Icons.checkroom_rounded, size: 80, color: AppTheme.border))),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('${_fmt(p.price)} đ', style: const TextStyle(color: AppTheme.primary, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (p.description != null && p.description!.isNotEmpty) ...[
                  const Text('Mô tả', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(p.description!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5)),
                  const SizedBox(height: 16),
                ],
                if (p.variants.isNotEmpty) ...[
                  const Text('Chọn size', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: p.variants.map((v) {
                      final sel = _selectedVariant?.id == v.id;
                      final outOfStock = v.stock <= 0;
                      return GestureDetector(
                        onTap: outOfStock ? null : () => setState(() => _selectedVariant = v),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? AppTheme.primary : (outOfStock ? AppTheme.bg : AppTheme.card),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: sel ? AppTheme.primary : AppTheme.border),
                          ),
                          child: Text(v.size, style: TextStyle(
                            color: sel ? Colors.black : (outOfStock ? AppTheme.textMuted : Colors.white),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          )),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  if (_selectedVariant != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.inventory_2_rounded, size: 14, color: AppTheme.success),
                          const SizedBox(width: 6),
                          Text('Còn ${_selectedVariant!.stock} sản phẩm',
                              style: const TextStyle(color: AppTheme.success, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
                // Quantity
                Row(
                  children: [
                    const Text('Số lượng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.border)),
                      child: Row(
                        children: [
                          IconButton(icon: const Icon(Icons.remove, size: 16), onPressed: _qty > 1 ? () => setState(() => _qty--) : null, color: Colors.white),
                          Text('$_qty', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          IconButton(icon: const Icon(Icons.add, size: 16), onPressed: () => setState(() => _qty++), color: AppTheme.primary),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottom() => Container(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
    decoration: const BoxDecoration(
      color: AppTheme.surface,
      border: Border(top: BorderSide(color: AppTheme.border)),
    ),
    child: ElevatedButton(
      onPressed: _selectedVariant != null ? _addToCart : null,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_rounded, size: 18),
          SizedBox(width: 8),
          Text('Thêm vào giỏ hàng'),
        ],
      ),
    ),
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
