'use client';

import React, { useState } from 'react';
import { Order } from '../lib/types';

interface BiBottomChartsProps {
  orders?: Order[];
}

export function BiBottomCharts({ orders = [] }: BiBottomChartsProps) {
  const [activeTab, setActiveTab] = useState<'returns' | 'payment'>('returns');

  const cancelledOrders = orders.filter((o) => o.status === 'cancelled');
  const returnRate = orders.length > 0 ? ((cancelledOrders.length / orders.length) * 100).toFixed(1) : '0.0';

  const codOrders = orders.filter((o) => o.paymentMethod === 'cod');
  const vnpayOrders = orders.filter((o) => o.paymentMethod === 'vnpay');
  const totalPaid = codOrders.length + vnpayOrders.length;
  const codPercent = totalPaid > 0 ? Math.round((codOrders.length / totalPaid) * 100) : 0;
  const vnpayPercent = totalPaid > 0 ? 100 - codPercent : 0;

  const hasOrders = orders.length > 0;

  const monthlyBase = [
    { label: 'T1', total: 119, c1: 45, c2: 38, c3: 36 }, { label: 'T2', total: 75, c1: 28, c2: 25, c3: 22 },
    { label: 'T3', total: 71, c1: 26, c2: 24, c3: 21 }, { label: 'T4', total: 95, c1: 35, c2: 32, c3: 28 },
    { label: 'T5', total: 116, c1: 42, c2: 38, c3: 36 }, { label: 'T6', total: 69, c1: 25, c2: 24, c3: 20 },
    { label: 'T7', total: 107, c1: 40, c2: 35, c3: 32 }, { label: 'T8', total: 79, c1: 30, c2: 26, c3: 23 },
    { label: 'T9', total: 72, c1: 28, c2: 24, c3: 20 }, { label: 'T10', total: 83, c1: 32, c2: 27, c3: 24 },
    { label: 'T11', total: 81, c1: 30, c2: 28, c3: 23 }, { label: 'T12', total: 52, c1: 20, c2: 18, c3: 14 },
    { label: 'T1', total: 86, c1: 34, c2: 28, c3: 24 }, { label: 'T2', total: 126, c1: 48, c2: 42, c3: 36 },
    { label: 'T3', total: 72, c1: 27, c2: 25, c3: 20 }, { label: 'T4', total: 92, c1: 36, c2: 30, c3: 26 },
    { label: 'T5', total: 80, c1: 30, c2: 26, c3: 24 }, { label: 'T6', total: 74, c1: 28, c2: 24, c3: 22 },
    { label: 'T7', total: 90, c1: 35, c2: 30, c3: 25 }, { label: 'T8', total: 87, c1: 33, c2: 29, c3: 25 },
    { label: 'T9', total: 76, c1: 29, c2: 25, c3: 22 }, { label: 'T10', total: 115, c1: 44, c2: 38, c3: 33 },
  ];

  const monthlyData = monthlyBase.map((d) => (hasOrders ? d : { ...d, total: 0, c1: 0, c2: 0, c3: 0 }));

  return (
    <div className="grid grid-cols-1 lg:grid-cols-12 gap-5">
      {/* Bottom-Left Card: Donut Breakdown */}
      <div className="lg:col-span-5 bg-[#1c0d36]/90 border border-[#371b63] rounded-2xl p-6">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-sm font-semibold text-slate-300 flex items-center gap-2">
            <span className="w-2 h-2 rounded-full bg-pink-400"></span>
            Tỷ lệ đổi trả & Kênh thanh toán
          </h3>
          <div className="flex gap-1 text-[11px] bg-[#120822] p-1 rounded-lg border border-[#371b63]">
            <button
              onClick={() => setActiveTab('returns')}
              className={`px-2 py-0.5 rounded cursor-pointer ${
                activeTab === 'returns' ? 'bg-violet-600 text-white font-bold' : 'text-slate-400'
              }`}
            >
              Đổi trả
            </button>
            <button
              onClick={() => setActiveTab('payment')}
              className={`px-2 py-0.5 rounded cursor-pointer ${
                activeTab === 'payment' ? 'bg-violet-600 text-white font-bold' : 'text-slate-400'
              }`}
            >
              Kênh bán
            </button>
          </div>
        </div>

        <div className="flex flex-col sm:flex-row items-center justify-around gap-6 pt-2">
          {/* Donut graphic */}
          <div className="relative w-44 h-44 flex items-center justify-center">
            <svg viewBox="0 0 100 100" className="w-full h-full -rotate-90">
              <circle cx="50" cy="50" r="38" fill="none" stroke="#2a144d" strokeWidth="18" />
              {hasOrders && (
                <>
                  <circle
                    cx="50"
                    cy="50"
                    r="38"
                    fill="none"
                    stroke="#7c3aed"
                    strokeWidth="18"
                    strokeDasharray="72 238"
                    strokeDashoffset="0"
                  />
                  <circle
                    cx="50"
                    cy="50"
                    r="38"
                    fill="none"
                    stroke="#a855f7"
                    strokeWidth="18"
                    strokeDasharray="84 238"
                    strokeDashoffset="-72"
                  />
                  <circle
                    cx="50"
                    cy="50"
                    r="38"
                    fill="none"
                    stroke="#ec4899"
                    strokeWidth="18"
                    strokeDasharray="82 238"
                    strokeDashoffset="-156"
                  />
                </>
              )}
            </svg>
            <div className="absolute inset-0 flex flex-col items-center justify-center text-center">
              <span className="text-2xl font-black text-white">{returnRate}%</span>
              <span className="text-[10px] text-slate-400 font-medium">Tỷ lệ hoàn hủy</span>
            </div>
          </div>

          {/* Legend list */}
          <div className="space-y-3 text-xs w-full sm:w-auto">
            {activeTab === 'returns' ? (
              <>
                <div className="flex items-center justify-between gap-4">
                  <span className="flex items-center gap-2 text-slate-300">
                    <span className="w-2.5 h-2.5 rounded-full bg-pink-500"></span>
                    Dịch vụ khách hàng
                  </span>
                  <span className="font-mono font-bold text-white">{hasOrders ? '30%' : '0%'}</span>
                </div>
                <div className="flex items-center justify-between gap-4">
                  <span className="flex items-center gap-2 text-slate-300">
                    <span className="w-2.5 h-2.5 rounded-full bg-purple-400"></span>
                    Máy móc / Lỗi vải
                  </span>
                  <span className="font-mono font-bold text-white">{hasOrders ? '35%' : '0%'}</span>
                </div>
                <div className="flex items-center justify-between gap-4">
                  <span className="flex items-center gap-2 text-slate-300">
                    <span className="w-2.5 h-2.5 rounded-full bg-violet-600"></span>
                    Thiếu phụ kiện size
                  </span>
                  <span className="font-mono font-bold text-white">{hasOrders ? '35%' : '0%'}</span>
                </div>
              </>
            ) : (
              <>
                <div className="flex items-center justify-between gap-4">
                  <span className="flex items-center gap-2 text-slate-300">
                    <span className="w-2.5 h-2.5 rounded-full bg-cyan-400"></span>
                    Thanh toán COD
                  </span>
                  <span className="font-mono font-bold text-white">{codPercent}%</span>
                </div>
                <div className="flex items-center justify-between gap-4">
                  <span className="flex items-center gap-2 text-slate-300">
                    <span className="w-2.5 h-2.5 rounded-full bg-violet-500"></span>
                    Thanh toán VNPay
                  </span>
                  <span className="font-mono font-bold text-white">{vnpayPercent}%</span>
                </div>
              </>
            )}
          </div>
        </div>
      </div>

      {/* Bottom-Right Card: Stacked Bar Chart */}
      <div className="lg:col-span-7 bg-[#1c0d36]/90 border border-[#371b63] rounded-2xl p-6 flex flex-col justify-between">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-sm font-semibold text-slate-300 flex items-center gap-2">
            <span className="w-2 h-2 rounded-full bg-cyan-400"></span>
            Biến động đơn hàng & giao dịch theo tháng
          </h3>
          <div className="flex items-center gap-3 text-[10px] text-slate-400">
            <span className="flex items-center gap-1">
              <span className="w-2 h-2 rounded-xs bg-violet-600"></span> Tầng 1
            </span>
            <span className="flex items-center gap-1">
              <span className="w-2 h-2 rounded-xs bg-cyan-500"></span> Tầng 2
            </span>
            <span className="flex items-center gap-1">
              <span className="w-2 h-2 rounded-xs bg-pink-400"></span> Tầng 3
            </span>
          </div>
        </div>

        {/* 22 Stacked Bars */}
        <div className="h-44 flex items-end justify-between gap-1 pt-6 pb-2 border-b border-[#371b63]">
          {monthlyData.map((d, idx) => {
            const maxTotal = 135;
            const barHeight = hasOrders ? (d.total / maxTotal) * 130 : 4;
            const h1 = hasOrders && d.total > 0 ? (d.c1 / d.total) * barHeight : 2;
            const h2 = hasOrders && d.total > 0 ? (d.c2 / d.total) * barHeight : 1;
            const h3 = hasOrders && d.total > 0 ? (d.c3 / d.total) * barHeight : 1;

            return (
              <div key={idx} className="flex-1 flex flex-col items-center group relative h-full justify-end">
                <span className="text-[9px] font-mono text-slate-400 mb-1 opacity-80 group-hover:text-white transition-colors">
                  {d.total}
                </span>
                <div
                  style={{ height: `${barHeight}px` }}
                  className="w-full max-w-[14px] rounded-t-xs overflow-hidden flex flex-col justify-end"
                >
                  <div style={{ height: `${h3}px` }} className={hasOrders ? 'bg-pink-400/90 w-full' : 'bg-slate-700/40 w-full'} />
                  <div style={{ height: `${h2}px` }} className={hasOrders ? 'bg-cyan-500/90 w-full' : 'bg-slate-700/40 w-full'} />
                  <div style={{ height: `${h1}px` }} className={hasOrders ? 'bg-violet-600/90 w-full' : 'bg-slate-700/40 w-full'} />
                </div>
              </div>
            );
          })}
        </div>

        {/* Months axis labels */}
        <div className="flex justify-between text-[8px] font-mono text-slate-500 mt-2">
          <span>T1 2025</span>
          <span>T2</span>
          <span>T3</span>
          <span>T4</span>
          <span>T5</span>
          <span>T6</span>
          <span>T7</span>
          <span>T8</span>
          <span>T9</span>
          <span>T10</span>
          <span>T11</span>
          <span>T12</span>
          <span>T1 2026</span>
          <span>T2</span>
          <span>T3</span>
          <span>T4</span>
          <span>T5</span>
          <span>T6</span>
          <span>T7</span>
          <span>T8</span>
          <span>T9</span>
          <span>T10</span>
        </div>
      </div>
    </div>
  );
}
