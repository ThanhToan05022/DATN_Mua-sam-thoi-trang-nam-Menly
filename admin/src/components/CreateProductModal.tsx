'use client';

import { useEffect, useState } from 'react';
import type { FormEvent } from 'react';
import { Plus, Trash2, X } from 'lucide-react';
import { createAdminProduct } from '../lib/api';
import type { Category, Product } from '../lib/types';

interface CreateProductModalProps {
  categories: Category[];
  onClose: () => void;
  onCreated: (product: Product) => void;
}

interface VariantDraft {
  size: string;
  color: string;
  sku: string;
  stock: string;
}

const fieldClass = 'w-full rounded-xl border border-slate-700 bg-slate-950 px-3 py-2.5 text-sm text-white placeholder:text-slate-500 focus:border-amber-500 focus:outline-none';

export function CreateProductModal({ categories, onClose, onCreated }: CreateProductModalProps) {
  const [categoryId, setCategoryId] = useState('');
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [price, setPrice] = useState('');
  const [thumbnailUrl, setThumbnailUrl] = useState('');
  const [variants, setVariants] = useState<VariantDraft[]>([
    { size: 'M', color: 'Đen', sku: '', stock: '0' },
  ]);
  const [isActive, setIsActive] = useState(true);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!categoryId && categories.length > 0) setCategoryId(categories[0].id);
  }, [categories, categoryId]);

  const setVariant = (index: number, key: keyof VariantDraft, value: string) => {
    setVariants((current) => current.map((variant, i) => i === index ? { ...variant, [key]: value } : variant));
  };

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setError(null);

    if (!categoryId) {
      setError('Vui lòng chọn danh mục cho sản phẩm.');
      return;
    }

    const normalizedVariants = variants.map((variant) => ({
      size: variant.size.trim(),
      color: variant.color.trim(),
      sku: variant.sku.trim(),
      stock: Number(variant.stock),
    }));
    const variantKeys = normalizedVariants.map((variant) => `${variant.size.toLowerCase()}|${variant.color.toLowerCase()}`);
    if (new Set(variantKeys).size !== variantKeys.length) {
      setError('Các biến thể không được trùng cặp size và màu.');
      return;
    }

    setLoading(true);
    try {
      const imageUrl = thumbnailUrl.trim() || null;
      const product = await createAdminProduct({
        categoryId,
        name: name.trim(),
        description: description.trim() || null,
        price: Number(price),
        thumbnailUrl: imageUrl,
        images: imageUrl ? [imageUrl] : [],
        isActive,
        variants: normalizedVariants,
      });
      onCreated(product);
      onClose();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Không thể tạo sản phẩm.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/80 p-4 backdrop-blur-sm">
      <section className="max-h-[92vh] w-full max-w-3xl overflow-y-auto rounded-3xl border border-slate-700 bg-slate-900 p-6 text-white shadow-2xl">
        <div className="mb-6 flex items-start justify-between border-b border-slate-800 pb-4">
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.18em] text-amber-400">Danh mục sản phẩm</p>
            <h2 className="mt-1 text-xl font-bold">Thêm sản phẩm mới</h2>
            <p className="mt-1 text-sm text-slate-400">Nhập thông tin sản phẩm và ít nhất một biến thể.</p>
          </div>
          <button type="button" onClick={onClose} aria-label="Đóng" className="rounded-xl p-2 text-slate-400 hover:bg-slate-800 hover:text-white">
            <X className="h-5 w-5" />
          </button>
        </div>

        {error && <div role="alert" className="mb-5 rounded-xl border border-rose-500/30 bg-rose-500/10 px-4 py-3 text-sm text-rose-300">{error}</div>}

        <form onSubmit={handleSubmit} className="space-y-5">
          <div className="grid gap-4 md:grid-cols-2">
            <label className="space-y-1.5 text-sm font-medium text-slate-300">
              Tên sản phẩm <span className="text-rose-400">*</span>
              <input className={fieldClass} value={name} onChange={(event) => setName(event.target.value)} minLength={2} maxLength={150} required placeholder="Ví dụ: Áo sơ mi Oxford" />
            </label>
            <label className="space-y-1.5 text-sm font-medium text-slate-300">
              Danh mục <span className="text-rose-400">*</span>
              <select className={fieldClass} value={categoryId} onChange={(event) => setCategoryId(event.target.value)} required>
                <option value="" disabled>Chọn danh mục</option>
                {categories.map((category) => <option key={category.id} value={category.id}>{category.name}</option>)}
              </select>
            </label>
            <label className="space-y-1.5 text-sm font-medium text-slate-300">
              Giá bán (₫) <span className="text-rose-400">*</span>
              <input className={fieldClass} type="number" min="0" step="1" value={price} onChange={(event) => setPrice(event.target.value)} required placeholder="350000" />
            </label>
            <label className="space-y-1.5 text-sm font-medium text-slate-300">
              Ảnh đại diện (URL)
              <input className={fieldClass} type="url" value={thumbnailUrl} onChange={(event) => setThumbnailUrl(event.target.value)} placeholder="https://..." />
            </label>
          </div>

          {thumbnailUrl.trim() && (
            <div className="flex items-center gap-3 rounded-xl border border-slate-800 bg-slate-950/60 p-3">
              <img src={thumbnailUrl} alt="Xem trước ảnh sản phẩm" className="h-16 w-16 rounded-lg border border-slate-700 object-cover" />
              <span className="break-all text-xs text-slate-400">Ảnh xem trước</span>
            </div>
          )}

          <label className="block space-y-1.5 text-sm font-medium text-slate-300">
            Mô tả
            <textarea className={`${fieldClass} min-h-24 resize-y`} value={description} onChange={(event) => setDescription(event.target.value)} maxLength={5000} placeholder="Mô tả chất liệu, kiểu dáng và đặc điểm sản phẩm..." />
          </label>

          <div className="space-y-3">
            <div className="flex items-center justify-between gap-3">
              <div>
                <h3 className="text-sm font-bold text-white">Biến thể và tồn kho</h3>
                <p className="text-xs text-slate-400">Mỗi cặp size và màu là một biến thể riêng.</p>
              </div>
              <button type="button" onClick={() => setVariants((current) => [...current, { size: '', color: '', sku: '', stock: '0' }])} className="inline-flex items-center gap-1.5 rounded-lg border border-amber-500/30 bg-amber-500/10 px-3 py-2 text-xs font-semibold text-amber-300 hover:bg-amber-500/20">
                <Plus className="h-3.5 w-3.5" /> Thêm biến thể
              </button>
            </div>

            {variants.map((variant, index) => (
              <div key={index} className="grid gap-3 rounded-xl border border-slate-800 bg-slate-950/50 p-3 md:grid-cols-[1fr_1fr_1.3fr_0.7fr_auto]">
                <input className={fieldClass} aria-label={`Size biến thể ${index + 1}`} value={variant.size} onChange={(event) => setVariant(index, 'size', event.target.value)} required maxLength={30} placeholder="Size" />
                <input className={fieldClass} aria-label={`Màu biến thể ${index + 1}`} value={variant.color} onChange={(event) => setVariant(index, 'color', event.target.value)} required maxLength={60} placeholder="Màu" />
                <input className={fieldClass} aria-label={`SKU biến thể ${index + 1}`} value={variant.sku} onChange={(event) => setVariant(index, 'sku', event.target.value)} maxLength={100} placeholder="SKU (tự tạo nếu bỏ trống)" />
                <input className={fieldClass} aria-label={`Tồn kho biến thể ${index + 1}`} type="number" min="0" step="1" value={variant.stock} onChange={(event) => setVariant(index, 'stock', event.target.value)} required />
                <button type="button" aria-label={`Xóa biến thể ${index + 1}`} disabled={variants.length === 1} onClick={() => setVariants((current) => current.filter((_, i) => i !== index))} className="flex items-center justify-center rounded-lg px-2 text-slate-500 hover:bg-rose-500/10 hover:text-rose-300 disabled:cursor-not-allowed disabled:opacity-30">
                  <Trash2 className="h-4 w-4" />
                </button>
              </div>
            ))}
          </div>

          <label className="flex items-center gap-2 text-sm text-slate-300">
            <input type="checkbox" checked={isActive} onChange={(event) => setIsActive(event.target.checked)} className="h-4 w-4 accent-amber-500" />
            Hiển thị sản phẩm ngay sau khi tạo
          </label>

          <div className="flex justify-end gap-3 border-t border-slate-800 pt-4">
            <button type="button" onClick={onClose} disabled={loading} className="rounded-xl border border-slate-700 px-4 py-2.5 text-sm font-semibold text-slate-300 hover:bg-slate-800 disabled:opacity-50">Hủy</button>
            <button type="submit" disabled={loading || categories.length === 0} className="rounded-xl bg-amber-500 px-5 py-2.5 text-sm font-bold text-slate-950 hover:bg-amber-400 disabled:cursor-not-allowed disabled:opacity-50">
              {loading ? 'Đang lưu...' : 'Tạo sản phẩm'}
            </button>
          </div>
        </form>
      </section>
    </div>
  );
}
