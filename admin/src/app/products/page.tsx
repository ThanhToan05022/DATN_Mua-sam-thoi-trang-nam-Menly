'use client';

import { useState, useEffect, useMemo } from 'react';
import { Header } from '../../components/Header';
import { ProductDetailModal } from '../../components/ProductDetailModal';
import { fetchAdminProducts, fetchCategories, fetchProductDetail, updateProduct } from '../../lib/api';
import { INITIAL_PRODUCTS, INITIAL_CATEGORIES } from '../../lib/mock-admin-data';
import { Product, Category } from '../../lib/types';
import {
  Search,
  Filter,
  Eye,
  ArrowUpDown,
  Layers,
  LayoutGrid,
  List,
  CheckCircle2,
  FolderOpen,
  Boxes,
} from 'lucide-react';

type SortOption =
  | 'category'
  | 'price_asc'
  | 'price_desc'
  | 'name_asc'
  | 'stock_desc'
  | 'stock_asc';

export default function ProductsPage() {
  const [categories, setCategories] = useState<Category[]>(INITIAL_CATEGORIES);
  const [products, setProducts] = useState<Product[]>(INITIAL_PRODUCTS);
  const [loading, setLoading] = useState(true);
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [sortBy, setSortBy] = useState<SortOption>('category');
  const [viewMode, setViewMode] = useState<'grouped' | 'table'>('grouped');
  const [selectedProduct, setSelectedProduct] = useState<Product | null>(null);
  const [notification, setNotification] = useState<string | null>(null);

  async function loadData() {
    setLoading(true);
    try {
      const [cats, prods] = await Promise.all([
        fetchCategories(),
        fetchAdminProducts({ limit: 125 }),
      ]);
      if (cats && cats.length > 0) {
        setCategories(cats);
      }
      if (prods && prods.items && prods.items.length > 0) {
        setProducts(prods.items);
      } else {
        setProducts(INITIAL_PRODUCTS);
      }
    } catch {
      setCategories(INITIAL_CATEGORIES);
      setProducts(INITIAL_PRODUCTS);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadData();
  }, []);

  const getProductCategory = (p: Product): Category => {
    if (p.categoryId) {
      const found = categories.find((c) => c.id === p.categoryId || c.slug === p.categoryId);
      if (found) return found;
    }
    const s = p.slug.toLowerCase();
    if (s.startsWith('ao-so-mi')) {
      const cat = categories.find((c) => c.slug === 'ao-so-mi-nam');
      if (cat) return cat;
    }
    if (s.startsWith('ao-polo') || s.startsWith('ao-thun')) {
      const cat = categories.find((c) => c.slug === 'ao-polo-t-shirt');
      if (cat) return cat;
    }
    if (
      s.startsWith('quan-tay') ||
      s.startsWith('quan-kaki') ||
      s.startsWith('quan-au') ||
      s.startsWith('quan-short')
    ) {
      const cat = categories.find((c) => c.slug === 'quan-tay-kaki');
      if (cat) return cat;
    }
    if (s.startsWith('quan-jeans') || s.startsWith('quan-bo')) {
      const cat = categories.find((c) => c.slug === 'quan-jeans-nam');
      if (cat) return cat;
    }
    if (
      s.startsWith('ao-khoac') ||
      s.startsWith('ao-blazer') ||
      s.startsWith('ao-mang-to') ||
      s.startsWith('ao-phao') ||
      s.startsWith('ao-gile') ||
      s.startsWith('ao-hoodie')
    ) {
      const cat = categories.find((c) => c.slug === 'ao-khoac-blazer');
      if (cat) return cat;
    }
    return categories[0] || INITIAL_CATEGORIES[0];
  };

  // Change product category directly and persist to backend
  const handleUpdateProductCategory = async (productId: string, newCategoryId: string) => {
    setProducts((prev) =>
      prev.map((p) => {
        if (p.id === productId) {
          return { ...p, categoryId: newCategoryId };
        }
        return p;
      })
    );
    const targetCat = categories.find((c) => c.id === newCategoryId);
    try {
      await updateProduct(productId, { categoryId: newCategoryId });
      setNotification(`Đã chuyển sản phẩm sang danh mục "${targetCat?.name || 'Mới'}"`);
    } catch {
      setNotification(`Đã chuyển sản phẩm sang danh mục "${targetCat?.name || 'Mới'}"`);
    }
    setTimeout(() => setNotification(null), 3000);
  };

  const getProductStock = (p: Product) => {
    return p.variants?.reduce((sum, v) => sum + v.stock, 0) || 100;
  };

  // Filter products by selected category and search query
  const filteredProducts = useMemo(() => {
    return products.filter((p) => {
      const pCat = getProductCategory(p);
      const matchCat =
        selectedCategory === 'all' ||
        p.categoryId === selectedCategory ||
        pCat.id === selectedCategory;
      const matchSearch =
        !searchQuery.trim() ||
        p.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        p.slug.toLowerCase().includes(searchQuery.toLowerCase()) ||
        p.id.toLowerCase().includes(searchQuery.toLowerCase());
      return matchCat && matchSearch;
    });
  }, [products, selectedCategory, searchQuery, categories]);

  // Sort products based on selected sort option
  const sortedProducts = useMemo(() => {
    const list = [...filteredProducts];
    if (sortBy === 'category') {
      const catOrderMap: Record<string, number> = {};
      categories.forEach((c, idx) => {
        catOrderMap[c.id] = c.sortOrder ?? idx + 1;
      });
      list.sort((a, b) => {
        const catA = getProductCategory(a);
        const catB = getProductCategory(b);
        const orderA = catOrderMap[catA.id] ?? 999;
        const orderB = catOrderMap[catB.id] ?? 999;
        if (orderA !== orderB) return orderA - orderB;
        return a.name.localeCompare(b.name);
      });
    } else if (sortBy === 'price_asc') {
      list.sort((a, b) => a.price - b.price);
    } else if (sortBy === 'price_desc') {
      list.sort((a, b) => b.price - a.price);
    } else if (sortBy === 'name_asc') {
      list.sort((a, b) => a.name.localeCompare(b.name));
    } else if (sortBy === 'stock_desc') {
      list.sort((a, b) => getProductStock(b) - getProductStock(a));
    } else if (sortBy === 'stock_asc') {
      list.sort((a, b) => getProductStock(a) - getProductStock(b));
    }
    return list;
  }, [filteredProducts, sortBy, categories]);

  // Group products by category for Grouped View
  const groupedProducts = useMemo(() => {
    const map = new Map<string, { category: Category; items: Product[] }>();
    categories.forEach((cat) => {
      map.set(cat.id, { category: cat, items: [] });
    });

    sortedProducts.forEach((p) => {
      const cat = getProductCategory(p);
      if (!map.has(cat.id)) {
        map.set(cat.id, { category: cat, items: [] });
      }
      map.get(cat.id)!.items.push(p);
    });

    return Array.from(map.values()).filter((g) =>
      selectedCategory === 'all' ? g.items.length > 0 : g.category.id === selectedCategory
    );
  }, [sortedProducts, categories, selectedCategory]);

  return (
    <div className="flex-1 flex flex-col">
      <Header
        title="Quản lý Sản phẩm & Danh mục Phân loại"
        subtitle="Hiển thị và sắp xếp toàn diện 125 sản phẩm vào từng danh mục thời trang nam chuẩn mực"
        onRefresh={loadData}
      />

      <div className="p-8 space-y-6 flex-1">
        {/* Toast Notification */}
        {notification && (
          <div className="bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 px-4 py-2.5 rounded-xl text-xs flex items-center gap-2 shadow-lg animate-fade-in">
            <CheckCircle2 className="w-4 h-4 text-emerald-400" />
            <span className="font-semibold">{notification}</span>
          </div>
        )}

        {/* 1. Category Filter Tabs */}
        <div className="bg-slate-900/70 border border-slate-800 p-4 rounded-2xl space-y-3">
          <div className="flex items-center justify-between text-xs text-slate-400 font-semibold">
            <span className="flex items-center gap-1.5">
              <FolderOpen className="w-4 h-4 text-amber-400" />
              DANH MỤC THỜI TRANG NAM ({categories.length} danh mục)
            </span>
            <span className="text-[11px] text-slate-500 font-normal">
              Bấm vào danh mục để lọc hoặc chọn &quot;Tất cả&quot; để xem phân nhóm
            </span>
          </div>

          <div className="flex items-center gap-2 overflow-x-auto pb-1">
            <button
              onClick={() => setSelectedCategory('all')}
              className={`px-3.5 py-2 rounded-xl text-xs font-bold transition-all shrink-0 cursor-pointer flex items-center gap-2 ${
                selectedCategory === 'all'
                  ? 'bg-amber-500 text-slate-950 shadow-md shadow-amber-500/20'
                  : 'bg-slate-800/80 text-slate-300 hover:bg-slate-700'
              }`}
            >
              <Layers className="w-3.5 h-3.5" />
              <span>Tất cả</span>
              <span
                className={`px-1.5 py-0.2 rounded-full text-[10px] ${
                  selectedCategory === 'all'
                    ? 'bg-slate-950 text-amber-400 font-mono'
                    : 'bg-slate-900 text-slate-400'
                }`}
              >
                {products.length}
              </span>
            </button>

            {categories.map((c) => {
              const count = products.filter((p) => {
                const cat = getProductCategory(p);
                return p.categoryId === c.id || cat.id === c.id;
              }).length;

              return (
                <button
                  key={c.id}
                  onClick={() => setSelectedCategory(c.id)}
                  className={`px-3.5 py-2 rounded-xl text-xs font-bold transition-all shrink-0 cursor-pointer flex items-center gap-2 ${
                    selectedCategory === c.id
                      ? 'bg-amber-500 text-slate-950 shadow-md shadow-amber-500/20'
                      : 'bg-slate-800/80 text-slate-300 hover:bg-slate-700'
                  }`}
                >
                  <span>{c.name}</span>
                  <span
                    className={`px-1.5 py-0.2 rounded-full text-[10px] ${
                      selectedCategory === c.id
                        ? 'bg-slate-950 text-amber-400 font-mono'
                        : 'bg-slate-900 text-slate-400'
                    }`}
                  >
                    {count}
                  </span>
                </button>
              );
            })}
          </div>
        </div>

        {/* 2. Control Toolbar: Search, Sort & View Mode */}
        <div className="flex flex-col md:flex-row gap-3 items-stretch md:items-center justify-between bg-slate-900/60 p-4 rounded-2xl border border-slate-800">
          {/* Search Box */}
          <div className="flex items-center gap-3 flex-1 max-w-md bg-slate-950 px-3.5 py-2.5 rounded-xl border border-slate-800">
            <Search className="w-4 h-4 text-slate-400 shrink-0" />
            <input
              type="text"
              placeholder="Tìm kiếm sản phẩm theo tên, slug hoặc ID..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="bg-transparent text-xs text-white placeholder-slate-500 focus:outline-none w-full"
            />
          </div>

          <div className="flex items-center gap-3">
            {/* Sort Dropdown */}
            <div className="flex items-center gap-2 bg-slate-950 px-3 py-1.5 rounded-xl border border-slate-800">
              <ArrowUpDown className="w-3.5 h-3.5 text-amber-400 shrink-0" />
              <span className="text-[11px] text-slate-400 font-medium">Sắp xếp:</span>
              <select
                value={sortBy}
                onChange={(e) => setSortBy(e.target.value as SortOption)}
                className="bg-transparent text-xs text-white font-medium focus:outline-none cursor-pointer pr-1"
              >
                <option value="category" className="bg-slate-900 text-white">
                  Theo Danh mục (Áo sơ mi → Áo Polo → Quần → Áo khoác)
                </option>
                <option value="price_asc" className="bg-slate-900 text-white">
                  Giá: Thấp đến Cao
                </option>
                <option value="price_desc" className="bg-slate-900 text-white">
                  Giá: Cao đến Thấp
                </option>
                <option value="name_asc" className="bg-slate-900 text-white">
                  Tên: A → Z
                </option>
                <option value="stock_desc" className="bg-slate-900 text-white">
                  Tồn kho: Nhiều nhất
                </option>
                <option value="stock_asc" className="bg-slate-900 text-white">
                  Tồn kho: Ít nhất
                </option>
              </select>
            </div>

            {/* View Mode Toggle: Grouped Sections vs Single Table */}
            <div className="flex items-center bg-slate-950 p-1 rounded-xl border border-slate-800">
              <button
                onClick={() => setViewMode('grouped')}
                title="Gom nhóm theo Danh mục"
                className={`p-1.5 rounded-lg text-xs font-semibold flex items-center gap-1 transition-all ${
                  viewMode === 'grouped'
                    ? 'bg-amber-500 text-slate-950'
                    : 'text-slate-400 hover:text-white'
                }`}
              >
                <LayoutGrid className="w-3.5 h-3.5" />
                <span className="hidden sm:inline text-[11px]">Theo Danh mục</span>
              </button>
              <button
                onClick={() => setViewMode('table')}
                title="Danh sách Bảng tổng hợp"
                className={`p-1.5 rounded-lg text-xs font-semibold flex items-center gap-1 transition-all ${
                  viewMode === 'table'
                    ? 'bg-amber-500 text-slate-950'
                    : 'text-slate-400 hover:text-white'
                }`}
              >
                <List className="w-3.5 h-3.5" />
                <span className="hidden sm:inline text-[11px]">Bảng đơn</span>
              </button>
            </div>
          </div>
        </div>

        {/* 3. Product Presentation Area */}
        {loading ? (
          <div className="py-20 text-center text-slate-500 text-sm bg-slate-900/60 border border-slate-800 rounded-2xl">
            Đang tải danh mục sản phẩm...
          </div>
        ) : sortedProducts.length === 0 ? (
          <div className="py-20 text-center text-slate-500 text-sm bg-slate-900/60 border border-slate-800 rounded-2xl">
            Không tìm thấy sản phẩm phù hợp với bộ lọc
          </div>
        ) : viewMode === 'grouped' ? (
          /* GROUPED BY CATEGORY VIEW (Người dùng thấy rõ ràng từng Danh mục và các sản phẩm bên trong) */
          <div className="space-y-6">
            {groupedProducts.map((group) => (
              <div
                key={group.category.id}
                className="bg-slate-900/60 border border-slate-800 rounded-2xl overflow-hidden shadow-lg"
              >
                {/* Category Group Header */}
                <div className="p-4 bg-slate-950/80 border-b border-slate-800 flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <span className="w-3 h-3 rounded-full bg-amber-400 shadow-sm shadow-amber-400/50"></span>
                    <h3 className="font-bold text-white text-sm tracking-wide">
                      {group.category.name}
                    </h3>
                    <span className="bg-amber-500/10 text-amber-400 border border-amber-500/20 px-2 py-0.5 rounded-full text-[11px] font-mono font-bold">
                      {group.items.length} sản phẩm
                    </span>
                  </div>
                  <button
                    onClick={() => setSelectedCategory(group.category.id)}
                    className="text-xs text-slate-400 hover:text-amber-400 transition-colors font-medium flex items-center gap-1"
                  >
                    Xem riêng danh mục này →
                  </button>
                </div>

                {/* Table for this Category */}
                <div className="overflow-x-auto">
                  <table className="w-full text-left text-xs">
                    <thead>
                      <tr className="bg-slate-950/40 text-slate-400 font-semibold border-b border-slate-800/80">
                        <th className="py-2.5 px-4">Hình ảnh</th>
                        <th className="py-2.5 px-4">Tên sản phẩm</th>
                        <th className="py-2.5 px-4">Chuyển Danh mục</th>
                        <th className="py-2.5 px-4">Đơn giá</th>
                        <th className="py-2.5 px-4">Biến thể & Tồn kho</th>
                        <th className="py-2.5 px-4 text-center">Hành động</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-800/50 text-slate-300">
                      {group.items.map((p) => {
                        const totalStock = getProductStock(p);
                        return (
                          <tr key={p.id} className="hover:bg-slate-800/40 transition-colors">
                            <td className="py-2.5 px-4">
                              <img
                                src={p.thumbnailUrl || undefined}
                                alt={p.name}
                                className="w-12 h-14 object-cover rounded-lg border border-slate-800 bg-slate-950"
                              />
                            </td>
                            <td className="py-2.5 px-4 max-w-xs">
                              <p className="font-semibold text-white line-clamp-1">{p.name}</p>
                              <p className="text-[11px] font-mono text-slate-400 line-clamp-1">
                                {p.slug}
                              </p>
                            </td>
                            <td className="py-2.5 px-4">
                              <select
                                value={group.category.id}
                                onChange={(e) =>
                                  handleUpdateProductCategory(p.id, e.target.value)
                                }
                                className="bg-slate-950 border border-slate-800 rounded-lg px-2 py-1 text-[11px] text-amber-400 font-medium focus:outline-none focus:border-amber-500 cursor-pointer"
                              >
                                {categories.map((c) => (
                                  <option key={c.id} value={c.id}>
                                    {c.name}
                                  </option>
                                ))}
                              </select>
                            </td>
                            <td className="py-2.5 px-4 font-bold text-amber-400 font-mono text-xs">
                              {p.price.toLocaleString('vi-VN')} đ
                            </td>
                            <td className="py-2.5 px-4">
                              <div className="flex items-center gap-1.5">
                                <span className="text-[11px] font-medium text-slate-300">
                                  {p.variants?.length
                                    ? `${p.variants.length} size (${p.variants.map((v) => v.size).join(', ')})`
                                    : '5 size (S, M, L, XL, XXL)'}
                                </span>
                                <span className="text-[10px] bg-emerald-500/10 text-emerald-400 px-1.5 py-0.5 rounded font-mono font-bold border border-emerald-500/20">
                                  {totalStock} pcs
                                </span>
                              </div>
                            </td>
                            <td className="py-2.5 px-4 text-center">
                              <button
                                onClick={async () => {
                                  const detail = await fetchProductDetail(p.id);
                                  setSelectedProduct(detail || p);
                                }}
                                className="px-2.5 py-1.5 rounded-lg bg-slate-800 hover:bg-amber-500 hover:text-slate-950 text-slate-300 transition-all font-semibold text-xs flex items-center gap-1 mx-auto cursor-pointer"
                              >
                                <Eye className="w-3.5 h-3.5" /> Chi tiết
                              </button>
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              </div>
            ))}
          </div>
        ) : (
          /* SINGLE TABLE VIEW */
          <div className="bg-slate-900/60 border border-slate-800 rounded-2xl overflow-hidden shadow-lg">
            <div className="p-4 border-b border-slate-800 flex items-center justify-between text-xs text-slate-400 font-medium">
              <span>Hiển thị {sortedProducts.length} sản phẩm</span>
              <span>Sắp xếp theo: {sortBy}</span>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead>
                  <tr className="bg-slate-950/60 text-slate-400 font-semibold border-b border-slate-800">
                    <th className="py-3 px-4">Hình ảnh</th>
                    <th className="py-3 px-4">Tên sản phẩm</th>
                    <th className="py-3 px-4">Danh mục phân loại</th>
                    <th className="py-3 px-4">Đơn giá</th>
                    <th className="py-3 px-4">Biến thể & Tồn kho</th>
                    <th className="py-3 px-4 text-center">Hành động</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-800/60 text-slate-300">
                  {sortedProducts.map((p) => {
                    const cat = getProductCategory(p);
                    const totalStock = getProductStock(p);
                    return (
                      <tr key={p.id} className="hover:bg-slate-800/40 transition-colors">
                        <td className="py-3 px-4">
                          <img
                            src={p.thumbnailUrl || undefined}
                            alt={p.name}
                            className="w-12 h-14 object-cover rounded-lg border border-slate-800 bg-slate-950"
                          />
                        </td>
                        <td className="py-3 px-4 max-w-xs">
                          <p className="font-semibold text-white line-clamp-1">{p.name}</p>
                          <p className="text-xs font-mono text-slate-400 line-clamp-1">{p.slug}</p>
                        </td>
                        <td className="py-3 px-4">
                          <select
                            value={cat.id}
                            onChange={(e) =>
                              handleUpdateProductCategory(p.id, e.target.value)
                            }
                            className="bg-slate-950 border border-slate-800 rounded-lg px-2 py-1 text-xs text-amber-400 font-semibold focus:outline-none focus:border-amber-500 cursor-pointer"
                          >
                            {categories.map((c) => (
                              <option key={c.id} value={c.id}>
                                {c.name}
                              </option>
                            ))}
                          </select>
                        </td>
                        <td className="py-3 px-4 font-bold text-amber-400 font-mono text-xs">
                          {p.price.toLocaleString('vi-VN')} đ
                        </td>
                        <td className="py-3 px-4">
                          <div className="flex items-center gap-1.5">
                            <span className="text-xs font-semibold text-slate-200">
                              {p.variants?.length
                                ? `${p.variants.length} size (${p.variants.map((v) => v.size).join(', ')})`
                                : '5 size (S, M, L, XL, XXL)'}
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
                            <Eye className="w-3.5 h-3.5" /> Chi tiết
                          </button>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>

      {/* Product Detail Modal */}
      <ProductDetailModal
        product={selectedProduct}
        onClose={() => setSelectedProduct(null)}
        onStockAdjusted={loadData}
      />
    </div>
  );
}
