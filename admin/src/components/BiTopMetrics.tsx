'use client';

import React from 'react';
import { Order, Product, Category } from '../lib/types';

interface BiTopMetricsProps {
  orders: Order[];
  products: Product[];
  categories?: Category[];
}

function LineSparkline({ active }: { active: boolean }) {
  const points = active ? [15, 28, 12, 35, 22, 18, 40, 26, 45, 30, 20, 38, 25, 32, 50] : [20, 20, 20, 20, 20, 20];
  const width = 180;
  const height = 40;
  const max = Math.max(...points);
  const min = Math.min(...points);
  const step = width / (points.length - 1);
  const pathD = points
    .map((val, idx) => {
      const x = idx * step;
      const y = height - ((val - min) / (max - min || 1)) * (height - 8) - 4;
      return `${idx === 0 ? 'M' : 'L'} ${x.toFixed(1)} ${y.toFixed(1)}`;
    })
    .join(' ');

  return (
    <svg width={width} height={height} className="overflow-visible opacity-80">
      <path d={pathD} fill="none" stroke="#22d3ee" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function BarSparkline({ hasOrders }: { hasOrders: boolean }) {
  const heights = hasOrders
    ? [12, 28, 8, 16, 26, 14, 30, 20, 10, 18, 26, 12, 22, 32, 16, 28, 20, 14, 26]
    : [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3];
  return (
    <div className="flex items-end gap-1.5 h-10">
      {heights.map((h, i) => (
        <span
          key={i}
          style={{ height: `${h}px` }}
          className={`w-1.5 rounded-xs transition-all ${hasOrders ? 'bg-cyan-400' : 'bg-slate-700/60'}`}
        />
      ))}
    </div>
  );
}

export function BiTopMetrics({ orders, products }: BiTopMetricsProps) {
  const validOrders = orders.filter((o) => o.status !== 'cancelled');
  const totalRevenue = validOrders.reduce((acc, o) => acc + (o.total || 0), 0);
  const totalOrdersCount = validOrders.length;

  const totalStock = products.reduce((acc, p) => {
    if (p.variants && p.variants.length > 0) {
      return acc + p.variants.reduce((vSum, v) => vSum + (v.stock || 0), 0);
    }
    return acc + 100;
  }, 0);

  const totalStockDisplay = totalStock >= 1000 ? `${(totalStock / 1000).toFixed(1)}K` : `${totalStock}`;
  const totalOrdersDisplay = totalOrdersCount > 0 ? `${totalOrdersCount}` : '0';
  const totalRevDisplay =
    totalRevenue >= 1000000
      ? `${(totalRevenue / 1000000).toFixed(2)}M`
      : totalRevenue > 0
      ? `${new Intl.NumberFormat('vi-VN').format(totalRevenue)} ₫`
      : '0 ₫';

  return (
    <div className="w-full bg-[#1c0d36]/90 border border-[#371b63] rounded-2xl p-6">
      <h3 className="text-sm font-semibold text-slate-300 mb-6 flex items-center gap-2">
        <span className="w-2 h-2 rounded-full bg-cyan-400"></span>
        Số liệu thống kê nhanh
      </h3>
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-y-6 gap-x-8">
        <div>
          <div className="text-3xl font-extrabold text-white tracking-tight">{totalStockDisplay}</div>
          <div className="text-xs text-slate-400 mt-1">Khối lượng sản xuất & Tồn kho</div>
        </div>
        <div className="flex items-center justify-between">
          <LineSparkline active={products.length > 0} />
          <div className="text-right">
            <div className="text-3xl font-extrabold text-cyan-400">{products.length}</div>
            <div className="text-xs text-slate-400 mt-1">Sản phẩm mở bán</div>
          </div>
        </div>

        <div className="flex items-center justify-between">
          <div>
            <div className="text-3xl font-extrabold text-white">{totalOrdersDisplay}</div>
            <div className="text-xs text-slate-400 mt-1">Số lượng đặt hàng</div>
          </div>
          <BarSparkline hasOrders={totalOrdersCount > 0} />
        </div>

        <div className="text-right flex flex-col justify-end">
          <div className="text-3xl font-extrabold text-cyan-400">{totalRevDisplay}</div>
          <div className="text-xs text-slate-400 mt-1">Doanh thu bán hàng (VND)</div>
        </div>
      </div>
    </div>
  );
}
