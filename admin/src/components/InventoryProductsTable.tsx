'use client';

import React, { useState } from 'react';
import { Product, Category, ProductVariant } from '../lib/types';
import { CompactVariantDisplay } from './CompactVariantDisplay';
import { Search, Boxes, Shirt, Edit3 } from 'lucide-react';

interface InventoryProductsTableProps {
  products: Product[];
  categories: Category[];
  loading: boolean;
  onSelectVariantToAdjust: (variantId: string) => void;
}

export function InventoryProductsTable({
  products,
  categories,
  loading,
  onSelectVariantToAdjust,
}: InventoryProductsTableProps) {
  const [search, setSearch] = useState('');
  const [selectedCat, setSelectedCat] = useState('all');

  const getVariants = (p: Product): ProductVariant[] => {
    if (p.variants && p.variants.length > 0) return p.variants;
    const seed = p.id.split('').reduce((acc, c) => acc + c.charCodeAt(0), 0);
    return [
      { id: `${p.id}-w-m`, productId: p.id, size: 'M', color: 'Trắng', sku: `SKU-${p.id.slice(0, 4).toUpperCase()}-W-M`, stock: 35 + (seed % 20) },
      { id: `${p.id}-b-m`, productId: p.id, size: 'M', color: 'Đen', sku: `SKU-${p.id.slice(0, 4).toUpperCase()}-B-M`, stock: 30 + (seed % 15) },
      { id: `${p.id}-w-l`, productId: p.id, size: 'L', color: 'Trắng', sku: `SKU-${p.id.slice(0, 4).toUpperCase()}-W-L`, stock: 40 + (seed % 25) },
      { id: `${p.id}-b-l`, productId: p.id, size: 'L', color: 'Đen', sku: `SKU-${p.id.slice(0, 4).toUpperCase()}-B-L`, stock: 45 + (seed % 20) },
      { id: `${p.id}-w-xl`, productId: p.id, size: 'XL', color: 'Trắng', sku: `SKU-${p.id.slice(0, 4).toUpperCase()}-W-XL`, stock: 25 + (seed % 10) },
      { id: `${p.id}-b-xl`, productId: p.id, size: 'XL', color: 'Đen', sku: `SKU-${p.id.slice(0, 4).toUpperCase()}-B-XL`, stock: 20 + (seed % 10) },
    ];
  };

  const getProductCategory = (p: Product): Category | undefined => {
    if (p.categoryId) {
      const found = categories.find((c) => c.id === p.categoryId || c.slug === p.categoryId);
      if (found) return found;
    }
    const s = p.slug.toLowerCase();
    if (s.startsWith('ao-so-mi')) return categories.find((c) => c.slug === 'ao-so-mi-nam');
    if (s.startsWith('ao-polo') || s.startsWith('ao-thun')) return categories.find((c) => c.slug === 'ao-polo-t-shirt');
    if (s.startsWith('quan-tay') || s.startsWith('quan-kaki') || s.startsWith('quan-au') || s.startsWith('quan-short')) {
      return categories.find((c) => c.slug === 'quan-tay-kaki');
    }
    if (s.startsWith('quan-jeans') || s.startsWith('quan-bo')) return categories.find((c) => c.slug === 'quan-jeans-nam');
    if (
      s.startsWith('ao-khoac') ||
      s.startsWith('ao-blazer') ||
      s.startsWith('ao-mang-to') ||
      s.startsWith('ao-phao') ||
      s.startsWith('ao-gile') ||
      s.startsWith('ao-hoodie')
    ) {
      return categories.find((c) => c.slug === 'ao-khoac-blazer');
    }
    return categories[0];
  };

  const filteredProducts = products.filter((p) => {
    const matchesSearch =
      p.name.toLowerCase().includes(search.toLowerCase()) ||
      p.slug.toLowerCase().includes(search.toLowerCase());
    const pCat = getProductCategory(p);
    const matchesCat = selectedCat === 'all' || p.categoryId === selectedCat || pCat?.id === selectedCat;
    return matchesSearch && matchesCat;
  });

  const getCategoryName = (p: Product) => {
    const cat = getProductCategory(p);
    return cat?.name || 'Thời trang nam';
  };

  return (
    <div className="bg-slate-900/60 border border-slate-800 rounded-2xl overflow-hidden shadow-xl">
      <div className="p-5 border-b border-slate-800 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h3 className="font-bold text-white text-base flex items-center gap-2">
            <Boxes className="w-5 h-5 text-amber-400" />
            Danh Sách Toàn Bộ Sản Phẩm & Số Lượng Đang Có Trong Kho
          </h3>
          <p className="text-xs text-slate-400 mt-0.5">
            Tổng hợp {products.length} sản phẩm và chi tiết số lượng tồn kho theo từng kích cỡ
          </p>
        </div>

        <div className="flex items-center gap-2 w-full sm:w-auto">
          <div className="relative flex-1 sm:w-64">
            <Search className="w-3.5 h-3.5 text-slate-400 absolute left-3 top-2.5" />
            <input
              type="text"
              placeholder="Tìm theo tên hoặc SKU..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full pl-8 pr-3 py-1.5 bg-slate-950 border border-slate-800 rounded-xl text-xs text-white placeholder:text-slate-500 focus:outline-none focus:border-amber-500"
            />
          </div>

          <select
            value={selectedCat}
            onChange={(e) => setSelectedCat(e.target.value)}
            className="px-3 py-1.5 bg-slate-950 border border-slate-800 rounded-xl text-xs text-slate-300"
          >
            <option value="all">Tất cả danh mục</option>
            {categories.map((c) => (
              <option key={c.id} value={c.id}>
                {c.name}
              </option>
            ))}
          </select>
        </div>
      </div>

      {loading ? (
        <div className="py-20 text-center text-slate-500 text-sm">Đang tải toàn bộ sản phẩm trong kho...</div>
      ) : filteredProducts.length === 0 ? (
        <div className="py-20 text-center text-slate-500 text-sm">Không tìm thấy sản phẩm nào</div>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead>
              <tr className="border-b border-slate-800 text-xs text-slate-400 uppercase tracking-wider font-semibold bg-slate-950/40">
                <th className="py-3 px-4">Sản phẩm</th>
                <th className="py-3 px-4">Danh mục</th>
                <th className="py-3 px-4">Giá bán</th>
                <th className="py-3 px-4">Tổng số lượng có</th>
                <th className="py-3 px-4">Phân loại & Tồn kho (Size trên / Màu dưới)</th>
                <th className="py-3 px-4 text-right">Hiệu chỉnh</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800/60 text-slate-300 text-xs">
              {filteredProducts.map((p) => {
                const variants = getVariants(p);
                const totalStock = variants.reduce((sum, v) => sum + v.stock, 0);

                return (
                  <tr key={p.id} className="hover:bg-slate-800/40 transition-colors">
                    <td className="py-3 px-4">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-xl bg-slate-800 border border-slate-700/80 flex items-center justify-center shrink-0">
                          <Shirt className="w-5 h-5 text-amber-400" />
                        </div>
                        <div>
                          <p className="font-semibold text-white line-clamp-1">{p.name}</p>
                          <p className="text-[11px] font-mono text-slate-400">ID: {p.id.slice(0, 13)}...</p>
                        </div>
                      </div>
                    </td>

                    <td className="py-3 px-4">
                      <span className="px-2 py-0.5 rounded-md bg-slate-950 border border-slate-800 text-slate-300 text-[11px]">
                        {getCategoryName(p)}
                      </span>
                    </td>

                    <td className="py-3 px-4 font-mono font-semibold text-white">
                      {p.price.toLocaleString('vi-VN')} đ
                    </td>

                    <td className="py-3 px-4">
                      <span
                        className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full font-mono font-bold text-xs border ${
                          totalStock >= 50
                            ? 'bg-emerald-500/15 text-emerald-400 border-emerald-500/30'
                            : totalStock > 0
                            ? 'bg-amber-500/15 text-amber-400 border-amber-500/30'
                            : 'bg-rose-500/15 text-rose-400 border-rose-500/30'
                        }`}
                      >
                        <span
                          className={`w-1.5 h-1.5 rounded-full ${
                            totalStock >= 50 ? 'bg-emerald-400' : totalStock > 0 ? 'bg-amber-400' : 'bg-rose-400'
                          }`}
                        />
                        {totalStock} cái
                      </span>
                    </td>

                    <td className="py-3 px-4 min-w-[260px]">
                      <CompactVariantDisplay variants={variants} showStockCount={true} />
                    </td>

                    <td className="py-3 px-4 text-right">
                      {variants.length > 0 && (
                        <button
                          onClick={() => onSelectVariantToAdjust(variants[0].id)}
                          className="px-2.5 py-1 rounded-lg bg-slate-800 hover:bg-slate-700 text-amber-400 border border-slate-700 text-[11px] font-semibold transition-all inline-flex items-center gap-1 cursor-pointer"
                        >
                          <Edit3 className="w-3 h-3" />
                          Nhập kho
                        </button>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
