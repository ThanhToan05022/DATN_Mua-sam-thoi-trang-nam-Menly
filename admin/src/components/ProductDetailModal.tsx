'use client';

import React, { useState } from 'react';
import { Product, ProductVariant } from '../lib/types';
import { adjustInventory } from '../lib/api';
import { Boxes, Sparkles, SlidersHorizontal } from 'lucide-react';

interface ProductDetailModalProps {
  product: Product | null;
  onClose: () => void;
  onStockAdjusted?: () => void;
}

export function ProductDetailModal({ product, onClose, onStockAdjusted }: ProductDetailModalProps) {
  const [selectedSize, setSelectedSize] = useState<string | null>(null);
  const [adjustingVariant, setAdjustingVariant] = useState<ProductVariant | null>(null);
  const [deltaAmount, setDeltaAmount] = useState<number>(10);
  const [adjustReason, setAdjustReason] = useState<'admin_restock' | 'admin_correction'>('admin_restock');
  const [loading, setLoading] = useState(false);
  const [feedback, setFeedback] = useState<{ text: string; success: boolean } | null>(null);

  if (!product) return null;

  const variants: ProductVariant[] = product.variants?.length
    ? product.variants
    : [
        { id: 'v-w-m', productId: product.id, size: 'M', color: 'Trắng', sku: `SKU-${product.id.slice(0, 4)}-W-M`, stock: 35 },
        { id: 'v-b-m', productId: product.id, size: 'M', color: 'Đen', sku: `SKU-${product.id.slice(0, 4)}-B-M`, stock: 30 },
        { id: 'v-w-l', productId: product.id, size: 'L', color: 'Trắng', sku: `SKU-${product.id.slice(0, 4)}-W-L`, stock: 40 },
        { id: 'v-b-l', productId: product.id, size: 'L', color: 'Đen', sku: `SKU-${product.id.slice(0, 4)}-B-L`, stock: 45 },
        { id: 'v-w-xl', productId: product.id, size: 'XL', color: 'Trắng', sku: `SKU-${product.id.slice(0, 4)}-W-XL`, stock: 25 },
        { id: 'v-b-xl', productId: product.id, size: 'XL', color: 'Đen', sku: `SKU-${product.id.slice(0, 4)}-B-XL`, stock: 20 },
      ];

  const totalStock = variants.reduce((sum, v) => sum + v.stock, 0);
  const totalSizesCount = variants.length;
  const filteredVariants = selectedSize ? variants.filter((v) => v.size === selectedSize) : variants;

  const handleAdjustSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!adjustingVariant) return;
    setLoading(true);
    setFeedback(null);
    try {
      await adjustInventory(adjustingVariant.id, deltaAmount, adjustReason);
      setFeedback({ text: `Đã cập nhật tồn kho size ${adjustingVariant.size} thành công!`, success: true });
      adjustingVariant.stock = Math.max(0, adjustingVariant.stock + deltaAmount);
      setTimeout(() => {
        setAdjustingVariant(null);
        if (onStockAdjusted) onStockAdjusted();
      }, 1000);
    } catch (err: unknown) {
      setFeedback({ text: err instanceof Error ? err.message : 'Lỗi chỉnh kho', success: false });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/80 backdrop-blur-md">
      <div className="bg-[#150b29] border border-[#3b1a6a] rounded-3xl w-full max-w-2xl max-h-[90vh] overflow-y-auto shadow-2xl text-white p-6 space-y-5">
        {/* Header */}
        <div className="flex items-center justify-between border-b border-[#2d1554] pb-3">
          <div className="flex items-center gap-2">
            <span className="w-2.5 h-2.5 rounded-full bg-cyan-400"></span>
            <h3 className="text-base font-bold text-white">Chi tiết Sản phẩm & Tồn kho Size</h3>
          </div>
          <button onClick={onClose} className="w-8 h-8 rounded-full bg-[#241242] text-slate-400 hover:text-white">✕</button>
        </div>

        {/* Product Basic Info Card */}
        <div className="flex flex-col sm:flex-row gap-4 bg-[#1e0f39]/80 border border-[#371b63] p-4 rounded-2xl">
          <img src={product.thumbnailUrl || undefined} alt={product.name} className="w-20 h-28 object-cover rounded-xl border border-[#3b1a6a] shrink-0" />
          <div className="space-y-1.5 flex-1 min-w-0">
            <h4 className="text-sm font-bold text-white line-clamp-1">{product.name}</h4>
            <div className="flex items-center gap-3 text-xs">
              <span className="font-mono text-cyan-400 font-bold">{product.price.toLocaleString('vi-VN')} đ</span>
              <span className="bg-[#2a134d] px-2 py-0.5 rounded text-slate-300 font-mono text-[10px]">ID: {product.id.slice(0, 16)}...</span>
            </div>
            <p className="text-xs text-slate-400 line-clamp-2">{product.description || 'Chất liệu thời trang cao cấp, form tôn dáng nam tính.'}</p>
          </div>
        </div>


        {/* Interactive Size Pill Selector */}
        <div className="space-y-2">
          <div className="flex items-center justify-between text-xs font-semibold text-slate-300">
            <span className="flex items-center gap-1.5"><SlidersHorizontal className="w-3.5 h-3.5 text-cyan-400" /> Chọn Size:</span>
            {selectedSize && <button onClick={() => setSelectedSize(null)} className="text-[11px] text-cyan-400 hover:underline">Tất cả ({totalSizesCount})</button>}
          </div>
          <div className="flex flex-wrap gap-2">
            {variants.map((v) => (
              <button
                key={v.id}
                onClick={() => setSelectedSize(selectedSize === v.size ? null : v.size)}
                className={`px-3 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 border transition-all ${
                  selectedSize === v.size ? 'bg-cyan-500 text-slate-950 border-cyan-400 shadow-md' : 'bg-[#1b0d34] text-slate-300 border-[#3b1a6a]'
                }`}
              >
                <span>Size {v.size}</span>
                <span className={`px-1 py-0.5 rounded text-[10px] font-mono ${selectedSize === v.size ? 'bg-slate-950 text-cyan-400' : 'bg-[#2b1452] text-emerald-400'}`}>
                  {v.stock}
                </span>
              </button>
            ))}
          </div>
        </div>

        {/* Variants Breakdown Table */}
        <div className="space-y-2">
          <h5 className="text-xs font-semibold text-slate-300 uppercase tracking-wider flex items-center gap-1.5">
            <Boxes className="w-3.5 h-3.5 text-cyan-400" /> Chi tiết tồn kho từng Size
          </h5>
          <div className="border border-[#321759] rounded-2xl overflow-hidden divide-y divide-[#2d1554]">
            {filteredVariants.map((v) => (
              <div key={v.id} className="p-3 bg-[#1b0d34]/90 flex items-center justify-between gap-3">
                <div className="flex items-center gap-2.5">
                  <span className="w-8 h-8 rounded-lg bg-gradient-to-tr from-cyan-500 to-blue-600 text-slate-950 font-black text-xs flex items-center justify-center">
                    {v.size}
                  </span>
                  <div>
                    <div className="font-mono text-xs font-bold text-white">{v.sku}</div>
                    <div className="text-[10px] text-slate-400">Màu: {v.color || 'Tiêu chuẩn'}</div>
                  </div>
                </div>

                <div className="flex items-center gap-3">
                  <span className={`text-xs font-bold font-mono px-2 py-0.5 rounded border ${
                    v.stock > 20 ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/30' : 'bg-amber-500/10 text-amber-400 border-amber-500/30'
                  }`}>
                    {v.stock} cái
                  </span>
                  <button
                    onClick={() => { setAdjustingVariant(v); setDeltaAmount(10); setFeedback(null); }}
                    className="px-2.5 py-1 rounded-lg bg-[#28134d] hover:bg-cyan-500 hover:text-slate-950 text-slate-300 text-xs font-bold border border-[#3b1a6a]"
                  >
                    Chỉnh kho
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Quick Stock Adjust Form Inline */}
        {adjustingVariant && (
          <form onSubmit={handleAdjustSubmit} className="p-3.5 rounded-2xl bg-[#1b0d34] border border-cyan-500/40 space-y-2.5">
            <div className="flex items-center justify-between">
              <h6 className="font-bold text-xs text-cyan-400 uppercase flex items-center gap-1.5">
                <Sparkles className="w-3.5 h-3.5" /> Chỉnh kho Size {adjustingVariant.size} ({adjustingVariant.sku})
              </h6>
              <button type="button" onClick={() => setAdjustingVariant(null)} className="text-xs text-slate-400">Hủy</button>
            </div>
            <div className="grid grid-cols-2 gap-2">
              <div>
                <label className="text-[10px] text-slate-300">Số lượng thay đổi (+/-)</label>
                <input
                  type="number"
                  required
                  value={deltaAmount}
                  onChange={(e) => setDeltaAmount(Number(e.target.value))}
                  className="w-full mt-0.5 px-2.5 py-1.5 bg-slate-950 border border-[#3b1a6a] rounded-lg text-xs text-white font-mono"
                />
              </div>
              <div>
                <label className="text-[10px] text-slate-300">Lý do</label>
                <select
                  value={adjustReason}
                  onChange={(e) => setAdjustReason(e.target.value as 'admin_restock' | 'admin_correction')}
                  className="w-full mt-0.5 px-2.5 py-1.5 bg-slate-950 border border-[#3b1a6a] rounded-lg text-xs text-white"
                >
                  <option value="admin_restock">Nhập thêm hàng</option>
                  <option value="admin_correction">Hiệu chỉnh kiểm kê</option>
                </select>
              </div>
            </div>
            {feedback && (
              <div className={`p-2 rounded-lg text-xs ${feedback.success ? 'bg-emerald-500/10 text-emerald-300' : 'bg-rose-500/10 text-rose-300'}`}>
                {feedback.text}
              </div>
            )}
            <button
              type="submit"
              disabled={loading}
              className="w-full py-2 rounded-xl bg-gradient-to-r from-cyan-500 to-blue-600 text-slate-950 font-bold text-xs shadow-md"
            >
              {loading ? 'Đang lưu...' : `Xác nhận điều chỉnh Size ${adjustingVariant.size}`}
            </button>
          </form>
        )}
      </div>
    </div>
  );
}
