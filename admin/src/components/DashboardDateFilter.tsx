'use client';

import React from 'react';
import { Calendar, Filter, RotateCcw } from 'lucide-react';

export type DateFilterPreset = 'all' | 'today' | 'yesterday' | '7days' | '30days' | 'custom_day' | 'custom_range';

interface DashboardDateFilterProps {
  preset: DateFilterPreset;
  customDay: string;
  fromDay: string;
  toDay: string;
  onPresetChange: (preset: DateFilterPreset) => void;
  onCustomDayChange: (day: string) => void;
  onRangeChange: (from: string, to: string) => void;
  onReset: () => void;
  ordersCount: number;
  revenue: number;
}

export function DashboardDateFilter({
  preset,
  customDay,
  fromDay,
  toDay,
  onPresetChange,
  onCustomDayChange,
  onRangeChange,
  onReset,
  ordersCount,
  revenue,
}: DashboardDateFilterProps) {
  const formattedRevenue = `${new Intl.NumberFormat('vi-VN').format(revenue)} ₫`;

  const presetButtons: { label: string; value: DateFilterPreset }[] = [
    { label: 'Tất cả', value: 'all' },
    { label: 'Hôm nay', value: 'today' },
    { label: 'Hôm qua', value: 'yesterday' },
    { label: '7 ngày qua', value: '7days' },
    { label: '30 ngày qua', value: '30days' },
  ];

  return (
    <div className="bg-slate-900/60 border border-slate-800 rounded-2xl p-5 space-y-4 shadow-lg">
      <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
        {/* Title & Presets */}
        <div className="flex flex-wrap items-center gap-2">
          <div className="flex items-center gap-2 text-slate-300 font-semibold text-xs mr-2">
            <Filter className="w-4 h-4 text-amber-400" />
            <span>Lọc ngày:</span>
          </div>

          {presetButtons.map((btn) => (
            <button
              key={btn.value}
              type="button"
              onClick={() => onPresetChange(btn.value)}
              className={`px-3 py-1.5 rounded-xl text-xs font-medium transition-all cursor-pointer ${
                preset === btn.value
                  ? 'bg-amber-500 text-slate-950 font-bold shadow-md shadow-amber-500/20'
                  : 'bg-slate-950/80 text-slate-400 hover:text-white hover:bg-slate-800 border border-slate-800'
              }`}
            >
              {btn.label}
            </button>
          ))}
        </div>

        {/* Live Filter Result Summary */}
        <div className="flex items-center gap-3 bg-slate-950/90 border border-slate-800/80 px-4 py-2 rounded-xl text-xs">
          <span className="text-slate-400">Kết quả lọc:</span>
          <span className="font-bold text-amber-400 font-mono">{ordersCount} đơn</span>
          <span className="text-slate-600">|</span>
          <span className="font-bold text-emerald-400 font-mono">{formattedRevenue}</span>
        </div>
      </div>

      {/* Custom Date Pickers */}
      <div className="pt-3 border-t border-slate-800/60 flex flex-wrap items-center gap-4 text-xs">
        {/* Single specific date picker */}
        <div className="flex items-center gap-2">
          <span className="text-slate-400 flex items-center gap-1.5 font-medium">
            <Calendar className="w-3.5 h-3.5 text-cyan-400" />
            Chọn ngày cụ thể:
          </span>
          <input
            type="date"
            value={customDay}
            onChange={(e) => onCustomDayChange(e.target.value)}
            className={`px-2.5 py-1.5 rounded-xl bg-slate-950 border text-white font-mono text-xs focus:outline-none focus:border-amber-500 ${
              preset === 'custom_day' ? 'border-amber-500 text-amber-300' : 'border-slate-800'
            }`}
          />
        </div>

        {/* Date range picker */}
        <div className="flex items-center gap-2">
          <span className="text-slate-400 font-medium">Khoảng ngày:</span>
          <input
            type="date"
            value={fromDay}
            onChange={(e) => onRangeChange(e.target.value, toDay)}
            className={`px-2 py-1.5 rounded-xl bg-slate-950 border text-white font-mono text-xs focus:outline-none focus:border-amber-500 ${
              preset === 'custom_range' ? 'border-amber-500' : 'border-slate-800'
            }`}
          />
          <span className="text-slate-500">-</span>
          <input
            type="date"
            value={toDay}
            onChange={(e) => onRangeChange(fromDay, e.target.value)}
            className={`px-2 py-1.5 rounded-xl bg-slate-950 border text-white font-mono text-xs focus:outline-none focus:border-amber-500 ${
              preset === 'custom_range' ? 'border-amber-500' : 'border-slate-800'
            }`}
          />
        </div>

        {/* Reset button if not all */}
        {preset !== 'all' && (
          <button
            type="button"
            onClick={onReset}
            className="flex items-center gap-1 px-2.5 py-1 rounded-lg text-slate-400 hover:text-white bg-slate-800/60 hover:bg-slate-800 transition-colors ml-auto cursor-pointer"
            title="Xem tất cả ngày"
          >
            <RotateCcw className="w-3 h-3" />
            <span>Mặc định (Tất cả)</span>
          </button>
        )}
      </div>
    </div>
  );
}
