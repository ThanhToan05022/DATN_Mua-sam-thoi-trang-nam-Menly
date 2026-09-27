'use client';

import React from 'react';
import { ReasonBadge } from './Badge';
import { InventoryMovement } from '../lib/types';
import { Clock, ArrowUpRight, ArrowDownRight } from 'lucide-react';

interface InventoryMovementsTableProps {
  movements: InventoryMovement[];
  loading: boolean;
}

export function InventoryMovementsTable({ movements, loading }: InventoryMovementsTableProps) {
  return (
    <div className="bg-slate-900/60 border border-slate-800 rounded-2xl overflow-hidden shadow-xl">
      <div className="p-4 border-b border-slate-800 flex items-center justify-between text-xs text-slate-400 font-medium">
        <span className="flex items-center gap-1.5 font-bold text-white text-sm">
          <Clock className="w-4 h-4 text-amber-400" />
          Lịch sử Biến động Kho (Inventory Movements)
        </span>
        <span>Ghi nhận thời gian thực</span>
      </div>

      {loading ? (
        <div className="py-20 text-center text-slate-500 text-sm">Đang tải lịch sử kho...</div>
      ) : movements.length === 0 ? (
        <div className="py-20 text-center text-slate-500 text-sm">Chưa có lịch sử biến động nào</div>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead>
              <tr className="border-b border-slate-800 text-xs text-slate-400 uppercase tracking-wider font-semibold bg-slate-950/40">
                <th className="py-3 px-4">Thời gian</th>
                <th className="py-3 px-4">Sản phẩm / SKU</th>
                <th className="py-3 px-4">Thay đổi (+/-)</th>
                <th className="py-3 px-4">Lý do</th>
                <th className="py-3 px-4">Ghi chú</th>
                <th className="py-3 px-4">Người thực hiện</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800/60 text-slate-300">
              {movements.map((m) => (
                <tr key={m.id} className="hover:bg-slate-800/40 transition-colors text-xs">
                  <td className="py-3 px-4 font-mono text-slate-400 whitespace-nowrap">
                    {new Date(m.createdAt).toLocaleString('vi-VN')}
                  </td>
                  <td className="py-3 px-4 font-semibold text-white">
                    {m.productName || m.sku || m.variantId}
                  </td>
                  <td className="py-3 px-4">
                    <span
                      className={`font-bold font-mono px-2 py-0.5 rounded flex items-center gap-1 w-fit ${
                        m.delta > 0
                          ? 'text-emerald-400 bg-emerald-500/10'
                          : 'text-rose-400 bg-rose-500/10'
                      }`}
                    >
                      {m.delta > 0 ? (
                        <ArrowUpRight className="w-3.5 h-3.5" />
                      ) : (
                        <ArrowDownRight className="w-3.5 h-3.5" />
                      )}
                      {m.delta > 0 ? `+${m.delta}` : m.delta}
                    </span>
                  </td>
                  <td className="py-3 px-4">
                    <ReasonBadge reason={m.reason} />
                  </td>
                  <td className="py-3 px-4 text-slate-400 max-w-xs truncate">
                    {m.note || 'Không có'}
                  </td>
                  <td className="py-3 px-4 font-mono text-slate-400">
                    {m.actorId || 'system'}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
