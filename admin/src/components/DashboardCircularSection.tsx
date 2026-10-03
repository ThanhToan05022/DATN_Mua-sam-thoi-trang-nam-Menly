'use client';

import React from 'react';
import { Sparkles } from 'lucide-react';
import { CircularProgressRing, DonutChart, DonutSegment } from './CircularCharts';

interface DashboardCircularSectionProps {
  orderFulfillmentRate: number;
  completedOrProcessing: number;
  totalOrdersCount: number;
  totalRevenue: number;
  finalDonutSegments: DonutSegment[];
  dateLabel?: string;
}

export function DashboardCircularSection({
  orderFulfillmentRate,
  completedOrProcessing,
  totalOrdersCount,
  totalRevenue,
  finalDonutSegments,
  dateLabel,
}: DashboardCircularSectionProps) {
  const fullRevenueVnd = `${new Intl.NumberFormat('vi-VN').format(totalRevenue)} ₫`;

  return (
    <div className="space-y-6">
      {/* 2 Circular Rings: Tỷ lệ Xử lý Đơn & Doanh thu */}
      <div>
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <Sparkles className="w-4 h-4 text-amber-400" />
            <h2 className="text-base font-bold text-white tracking-tight">
              Chỉ số Xử lý Đơn & Doanh thu {dateLabel ? `(${dateLabel})` : ''}
            </h2>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
          <CircularProgressRing
            value={orderFulfillmentRate}
            size={140}
            strokeWidth={12}
            title="Tỷ lệ Xử lý Đơn"
            subtitle={
              totalOrdersCount > 0
                ? `${completedOrProcessing}/${totalOrdersCount} đơn đã xử lý / hoàn tất`
                : '0/0 đơn hàng'
            }
            gradientFrom="#3b82f6"
            gradientTo="#6366f1"
          />

          <CircularProgressRing
            value={totalRevenue > 0 ? 100 : 0}
            size={140}
            strokeWidth={12}
            title={dateLabel ? `Doanh thu (${dateLabel})` : 'Doanh thu Ngày'}
            subtitle={`Tổng thực thu: ${fullRevenueVnd}`}
            valueDisplay={fullRevenueVnd}
            gradientFrom="#f59e0b"
            gradientTo="#fbbf24"
          />
        </div>
      </div>

      {/* Cơ cấu danh mục (Donut Chart) */}
      <div>
        <DonutChart
          title="Phân bổ Cơ cấu Danh mục (Donut Chart)"
          subtitle="Tỷ trọng 400 sản phẩm phân bổ đều qua 5 danh mục thời trang nam cao cấp"
          segments={finalDonutSegments}
          totalLabel="400 SP"
          size={190}
          thickness={24}
        />
      </div>
    </div>
  );
}
