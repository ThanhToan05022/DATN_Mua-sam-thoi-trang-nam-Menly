'use client';

import React from 'react';
import Link from 'next/link';
import { StatCard } from './StatCard';
import { OrderStatusBadge } from './Badge';
import { Order } from '../lib/types';
import { Shirt, ShoppingBag, TrendingUp, Boxes, ArrowRight } from 'lucide-react';

interface DashboardRecentOrdersProps {
  orders: Order[];
  productsCount: number;
  totalRevenue: number;
  loading: boolean;
}

export function DashboardRecentOrders({
  orders,
  productsCount,
  totalRevenue,
  loading,
}: DashboardRecentOrdersProps) {
  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
        <StatCard
          title="Tổng sản phẩm"
          value={productsCount > 0 ? productsCount : '125'}
          subtitle="Đều 25 sp x 5 danh mục"
          icon={Shirt}
          trend="100% Active"
          color="amber"
        />
        <StatCard
          title="Đơn đang xử lý"
          value={orders.filter((o) => o.status === 'processing').length}
          subtitle={`${orders.length} tổng đơn ghi nhận`}
          icon={ShoppingBag}
          trend="Realtime"
          color="blue"
        />
        <StatCard
          title="Doanh thu tạm tính"
          value={`${totalRevenue.toLocaleString('vi-VN')} đ`}
          subtitle="COD & VNPay Sandbox"
          icon={TrendingUp}
          trend="+18.5%"
          color="emerald"
        />
        <StatCard
          title="Tồn kho trung bình"
          value="42"
          subtitle="Sản phẩm / size (M, L, XL)"
          icon={Boxes}
          trend="375 SKU"
          color="purple"
        />
      </div>

      <div className="bg-slate-900/60 border border-slate-800 rounded-2xl p-6">
        <div className="flex items-center justify-between mb-5">
          <div>
            <h2 className="text-base font-bold text-white">Đơn hàng mới nhất</h2>
            <p className="text-xs text-slate-400 mt-0.5">
              Các đơn hàng phát sinh từ ứng dụng di động Flutter và website
            </p>
          </div>
          <Link
            href="/orders"
            className="text-xs text-amber-400 hover:text-amber-300 font-semibold flex items-center gap-1 transition-colors"
          >
            Xem tất cả <ArrowRight className="w-3.5 h-3.5" />
          </Link>
        </div>

        {loading ? (
          <div className="py-12 text-center text-slate-500 text-sm">Đang tải đơn hàng...</div>
        ) : orders.length === 0 ? (
          <div className="py-12 text-center text-slate-500 text-sm">Chưa có đơn hàng nào</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead>
                <tr className="border-b border-slate-800 text-xs text-slate-400 uppercase tracking-wider font-semibold">
                  <th className="pb-3">Mã đơn</th>
                  <th className="pb-3">Khách hàng</th>
                  <th className="pb-3">Phương thức</th>
                  <th className="pb-3">Tổng tiền</th>
                  <th className="pb-3">Trạng thái</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800/60 text-slate-300">
                {orders.slice(0, 5).map((ord) => (
                  <tr key={ord.id} className="hover:bg-slate-800/40 transition-colors">
                    <td className="py-3 font-mono font-semibold text-amber-400 text-xs">
                      {ord.code}
                    </td>
                    <td className="py-3">
                      <p className="font-medium text-white">{ord.shippingAddress.name}</p>
                      <p className="text-xs text-slate-400">{ord.shippingAddress.phone}</p>
                    </td>
                    <td className="py-3 uppercase text-xs font-semibold text-slate-300">
                      {ord.paymentMethod}
                    </td>
                    <td className="py-3 font-semibold text-white">
                      {ord.total.toLocaleString('vi-VN')} đ
                    </td>
                    <td className="py-3">
                      <OrderStatusBadge status={ord.status} />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
