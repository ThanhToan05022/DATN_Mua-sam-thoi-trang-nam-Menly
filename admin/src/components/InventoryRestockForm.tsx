'use client';

import React, { useState } from 'react';
import { PlusCircle, CheckCircle2, AlertCircle } from 'lucide-react';
import { Product } from '../lib/types';
import { adjustInventory } from '../lib/api';

interface InventoryRestockFormProps {
  products: Product[];
  selectedVariantId: string;
  onVariantChange: (variantId: string) => void;
  onSuccess: () => void;
}

export function InventoryRestockForm({
  products,
  selectedVariantId,
  onVariantChange,
  onSuccess,
}: InventoryRestockFormProps) {
  const [delta, setDelta] = useState(20);
  const [reason, setReason] = useState<'admin_restock' | 'admin_correction'>('admin_restock');
  const [note, setNote] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [message, setMessage] = useState<{ text: string; type: 'success' | 'error' } | null>(null);

  const allVariants = products.flatMap((p) =>
    (p.variants || []).map((v) => ({
      ...v,
      productName: p.name,
    }))
  );

  async function handleAdjust(e: React.FormEvent) {
    e.preventDefault();
    if (!selectedVariantId) return;
    setSubmitting(true);
    setMessage(null);
    try {
      await adjustInventory(selectedVariantId, delta, reason, note);
      setMessage({ text: 'Đã cập nhật số lượng tồn kho thành công!', type: 'success' });
      setNote('');
      onSuccess();
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Lỗi khi nhập kho';
      setMessage({ text: msg, type: 'error' });
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="bg-slate-900/60 border border-slate-800 rounded-2xl p-6">
      <div className="flex items-center gap-2 mb-4">
        <PlusCircle className="w-5 h-5 text-amber-400" />
        <h3 className="font-bold text-base text-white">Nhập / Hiệu chỉnh Tồn Kho</h3>
      </div>

      {message && (
        <div
          className={`p-3 mb-4 rounded-xl text-xs font-semibold flex items-center gap-2 ${
            message.type === 'success'
              ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/30'
              : 'bg-rose-500/10 text-rose-400 border border-rose-500/30'
          }`}
        >
          {message.type === 'success' ? <CheckCircle2 className="w-4 h-4 shrink-0" /> : <AlertCircle className="w-4 h-4 shrink-0" />}
          <span>{message.text}</span>
        </div>
      )}

      <form onSubmit={handleAdjust} className="space-y-4 text-xs">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <div className="lg:col-span-2">
            <label className="text-slate-300 font-semibold block mb-1.5">Chọn Biến thể / SKU</label>
            <select
              value={selectedVariantId}
              onChange={(e) => onVariantChange(e.target.value)}
              className="w-full px-3 py-2 bg-slate-950 border border-slate-800 rounded-xl text-white text-xs truncate focus:outline-none focus:border-amber-500"
            >
              {allVariants.map((v) => (
                <option key={v.id} value={v.id}>
                  {v.productName} — [Size: {v.size} | Màu: {v.color || 'Tiêu chuẩn'}] (Tồn: {v.stock})
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="text-slate-300 font-semibold block mb-1.5">Số lượng (+/-)</label>
            <input
              type="number"
              value={delta}
              onChange={(e) => setDelta(Number(e.target.value))}
              className="w-full px-3 py-2 bg-slate-950 border border-slate-800 rounded-xl text-white text-xs font-mono font-bold focus:outline-none focus:border-amber-500"
            />
          </div>

          <div>
            <label className="text-slate-300 font-semibold block mb-1.5">Lý do</label>
            <select
              value={reason}
              onChange={(e) => setReason(e.target.value as 'admin_restock' | 'admin_correction')}
              className="w-full px-3 py-2 bg-slate-950 border border-slate-800 rounded-xl text-white text-xs focus:outline-none focus:border-amber-500"
            >
              <option value="admin_restock">Nhập kho mới</option>
              <option value="admin_correction">Hiệu chỉnh kiểm kê</option>
            </select>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 items-end">
          <div className="md:col-span-2">
            <label className="text-slate-300 font-semibold block mb-1.5">Ghi chú</label>
            <input
              type="text"
              placeholder="VD: Hóa đơn nhập đợt 2..."
              value={note}
              onChange={(e) => setNote(e.target.value)}
              className="w-full px-3 py-2 bg-slate-950 border border-slate-800 rounded-xl text-white text-xs placeholder:text-slate-500 focus:outline-none focus:border-amber-500"
            />
          </div>

          <div>
            <button
              type="submit"
              disabled={submitting}
              className="w-full py-2.5 bg-amber-500 text-slate-950 rounded-xl font-bold hover:bg-amber-400 transition-colors cursor-pointer disabled:opacity-50 text-xs shadow-md shadow-amber-500/20"
            >
              {submitting ? 'Đang cập nhật...' : 'Xác nhận thay đổi kho'}
            </button>
          </div>
        </div>
      </form>
    </div>
  );
}
