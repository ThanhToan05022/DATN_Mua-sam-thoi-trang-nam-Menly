'use client';

import { useState, useEffect, useMemo } from 'react';
import { Header } from '../../components/Header';
import { ProductDetailModal } from '../../components/ProductDetailModal';
import { fetchAdminProducts, fetchCategories, fetchProductDetail } from '../../lib/api';
import { Product, Category } from '../../lib/types';
import { Search, Filter, Eye } from 'lucide-react';

export default function ProductsPage() {
  const [categories, setCategories] = useState<Category[]>([]);
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedProduct, setSelectedProduct] = useState<Product | null>(null);

  async function loadData() {
    setLoading(true);
    try {
      const [cats, prods] = await Promise.all([
        fetchCategories(),
        fetchAdminProducts({ limit: 125 }),
      ]);
      setCategories(cats);
      setProducts(prods.items || []);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadData();
  }, []);

  const getProductCategory = (p: Product): Category | undefined => {
    if (p.categoryId) {
      const found = categories.find((c) => c.id === p.categoryId || c.slug === p.categoryId);
      if (found) return found;
    }
    if (p.slug.startsWith('ao-so-mi')) return categories.find((c) => c.slug === 'ao-so-mi-nam');
    if (p.slug.startsWith('ao-polo') || p.slug.startsWith('ao-thun')) return categories.find((c) => c.slug === 'ao-polo-t-shirt');
    if (p.slug.startsWith('quan-tay') || p.slug.startsWith('quan-kaki')) return categories.find((c) => c.slug === 'quan-tay-kaki');
    if (p.slug.startsWith('quan-jeans')) return categories.find((c) => c.slug === 'quan-jeans-nam');
    if (p.slug.startsWith('ao-khoac') || p.slug.startsWith('ao-blazer') || p.slug.startsWith('ao-mang-to') || p.slug.startsWith('ao-phao') || p.slug.startsWith('ao-gile')) {
      return categories.find((c) => c.slug === 'ao-khoac-blazer');
    }
    return undefined;
  };

  const filteredProducts = useMemo(() => {
    return products.filter((p) => {
      const pCat = getProductCategory(p);
      const matchCat = selectedCategory === 'all' || p.categoryId === selectedCategory || pCat?.id === selectedCategory;
      const matchSearch =
        !searchQuery.trim() ||
        p.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        p.slug.toLowerCase().includes(searchQuery.toLowerCase());
      return matchCat && matchSearch;
    });
  }, [products, selectedCategory, searchQuery, categories]);

  return (
    <div className="flex-1 flex flex-col">
      <Header
        title="Quản lý Sản phẩm & Biến thể Tồn kho"
        subtitle="Theo dõi chi tiết số size, số lượng tồn kho từng size cho 125 sản phẩm MenShop"
        onRefresh={loadData}
      />

      <div className="p-8 space-y-6 flex-1">
        {/* Filters and Search Bar */}
        <div className="flex flex-col sm:flex-row gap-4 justify-between bg-slate-900/60 p-4 rounded-2xl border border-slate-800">
          <div className="flex items-center gap-3 flex-1 max-w-md bg-slate-950 px-3.5 py-2 rounded-xl border border-slate-800">
            <Search className="w-4 h-4 text-slate-400 shrink-0" />
            <input
              type="text"
              placeholder="Tìm kiếm sản phẩm theo tên, slug..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="bg-transparent text-xs text-white placeholder-slate-500 focus:outline-none w-full"
            />
          </div>

          <div className="flex items-center gap-2 overflow-x-auto pb-1 sm:pb-0">
            <Filter className="w-4 h-4 text-slate-400 ml-1 mr-1 shrink-0" />
            <button
              onClick={() => setSelectedCategory('all')}
              className={`px-3 py-1.5 rounded-xl text-xs font-semibold transition-all shrink-0 cursor-pointer ${
                selectedCategory === 'all'
                  ? 'bg-amber-500 text-slate-950 shadow-sm'
                  : 'bg-slate-800 text-slate-300 hover:bg-slate-700'
              }`}
            >
              Tất cả ({products.length})
            </button>
            {categories.map((c) => {
              const count = products.filter((p) => {
                const cat = getProductCategory(p);
                return p.categoryId === c.id || cat?.id === c.id;
              }).length;
              return (
                <button
                  key={c.id}
                  onClick={() => setSelectedCategory(c.id)}
                  className={`px-3 py-1.5 rounded-xl text-xs font-semibold transition-all shrink-0 cursor-pointer ${
                    selectedCategory === c.id
                      ? 'bg-amber-500 text-slate-950 shadow-sm'
                      : 'bg-slate-800 text-slate-300 hover:bg-slate-700'
                  }`}
                >
                  {c.name} ({count})
                </button>
              );
            })}
          </div>
        </div>

        {/* Product Table */}
        <div className="bg-slate-900/60 border border-slate-800 rounded-2xl overflow-hidden shadow-lg">
          <div className="p-4 border-b border-slate-800 flex items-center justify-between text-xs text-slate-400 font-medium">
            <span>Hiển thị {filteredProducts.length} sản phẩm</span>
            <span>Kho hàng thời trang nam</span>
          </div>

          {loading ? (
            <div className="py-20 text-center text-slate-500 text-sm">Đang tải danh mục sản phẩm...</div>
          ) : filteredProducts.length === 0 ? (
            <div className="py-20 text-center text-slate-500 text-sm">Không tìm thấy sản phẩm phù hợp</div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead>
                  <tr className="bg-slate-950/60 text-slate-400 font-semibold border-b border-slate-800">
                    <th className="py-3 px-4">Hình ảnh</th>
                    <th className="py-3 px-4">Tên sản phẩm</th>
                    <th className="py-3 px-4">Danh mục</th>
                    <th className="py-3 px-4">Đơn giá</th>
                    <th className="py-3 px-4">Biến thể & Tồn kho</th>
                    <th className="py-3 px-4 text-center">Hành động</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-800/60 text-slate-300">
                  {filteredProducts.map((p) => {
                    const cat = getProductCategory(p);
                    const totalStock = p.variants?.reduce((sum, v) => sum + v.stock, 0) || 100;
                    return (
                      <tr key={p.id} className="hover:bg-slate-800/40 transition-colors">
                        <td className="py-3 px-4">
                          <img
                            src={p.thumbnailUrl}
                            alt={p.name}
                            className="w-12 h-14 object-cover rounded-lg border border-slate-800 bg-slate-950"
                          />
                        </td>
                        <td className="py-3 px-4 max-w-xs">
                          <p className="font-semibold text-white line-clamp-1">{p.name}</p>
                          <p className="text-xs font-mono text-slate-400 line-clamp-1">{p.slug}</p>
                        </td>
                        <td className="py-3 px-4">
                          <span className="text-xs bg-slate-800 px-2 py-0.5 rounded text-slate-300 font-medium">
                            {cat?.name || 'Danh mục'}
                          </span>
                        </td>
                        <td className="py-3 px-4 font-bold text-amber-400 font-mono">
                          {p.price.toLocaleString('vi-VN')} đ
                        </td>
                        <td className="py-3 px-4">
                          <div className="flex items-center gap-1.5">
                            <span className="text-xs font-semibold text-slate-200">
                              {p.variants?.length ? `${p.variants.length} size (${p.variants.map((v) => v.size).join(', ')})` : '5 size (S, M, L, XL, XXL)'}
                            </span>
                            <span className="text-[11px] bg-emerald-500/10 text-emerald-400 px-1.5 py-0.5 rounded font-mono font-bold border border-emerald-500/20">
                              {totalStock} pcs
                            </span>
                          </div>
                        </td>
                        <td className="py-3 px-4 text-center">
                          <button
                            onClick={async () => {
                              const detail = await fetchProductDetail(p.id);
                              setSelectedProduct(detail || p);
                            }}
                            className="px-3 py-1.5 rounded-lg bg-slate-800 hover:bg-amber-500 hover:text-slate-950 text-slate-300 transition-all font-semibold text-xs flex items-center gap-1 mx-auto cursor-pointer"
                          >
                            <Eye className="w-3.5 h-3.5" /> Chi tiết sản phẩm
                          </button>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>

      {/* Product Detail Modal with Full Size Breakdown & Stock */}
      <ProductDetailModal
        product={selectedProduct}
        onClose={() => setSelectedProduct(null)}
        onStockAdjusted={loadData}
      />
    </div>
  );
}
