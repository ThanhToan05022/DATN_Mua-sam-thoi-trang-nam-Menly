'use client';

import React from 'react';

export interface RadialGaugeProps {
  value: number; // 0 to 100
  title: string;
  subtitle: string;
  statusText?: string;
  size?: number;
}

export function RadialGauge({
  value,
  title,
  subtitle,
  statusText = 'An toàn',
  size = 180,
}: RadialGaugeProps) {
  const strokeWidth = 14;
  const radius = (size - strokeWidth) / 2;
  const semiCircumference = Math.PI * radius;
  const clampedValue = Math.min(100, Math.max(0, value));
  const strokeDashoffset = semiCircumference - (clampedValue / 100) * semiCircumference;

  return (
    <div className="p-6 rounded-2xl bg-slate-900/60 border border-slate-800 hover:border-slate-700 transition-all duration-300 flex flex-col items-center text-center">
      <div className="w-full text-left mb-2">
        <h3 className="font-bold text-white text-base">{title}</h3>
        <p className="text-xs text-slate-400 mt-0.5">{subtitle}</p>
      </div>

      <div className="relative my-2">
        <svg
          width={size}
          height={size / 2 + strokeWidth}
          viewBox={`0 0 ${size} ${size / 2 + strokeWidth}`}
          className="overflow-visible"
        >
          <defs>
            <linearGradient id="gauge-grad" x1="0%" y1="0%" x2="100%" y2="0%">
              <stop offset="0%" stopColor="#10b981" />
              <stop offset="70%" stopColor="#f59e0b" />
              <stop offset="100%" stopColor="#ef4444" />
            </linearGradient>
          </defs>

          {/* Background Arc */}
          <path
            d={`M ${strokeWidth / 2} ${size / 2} A ${radius} ${radius} 0 0 1 ${size - strokeWidth / 2} ${size / 2}`}
            fill="none"
            stroke="currentColor"
            strokeWidth={strokeWidth}
            className="text-slate-800/80"
            strokeLinecap="round"
          />

          {/* Animated Value Arc */}
          <path
            d={`M ${strokeWidth / 2} ${size / 2} A ${radius} ${radius} 0 0 1 ${size - strokeWidth / 2} ${size / 2}`}
            fill="none"
            stroke="url(#gauge-grad)"
            strokeWidth={strokeWidth}
            strokeDasharray={semiCircumference}
            strokeDashoffset={strokeDashoffset}
            strokeLinecap="round"
            className="transition-all duration-1000 ease-out"
          />
        </svg>

        <div className="absolute inset-x-0 bottom-1 flex flex-col items-center">
          <span className="text-3xl font-extrabold text-white font-mono tracking-tight">
            {Math.round(clampedValue)}%
          </span>
          <span className="text-[11px] font-bold text-emerald-400 mt-0.5 uppercase tracking-wider">
            {statusText}
          </span>
        </div>
      </div>

      <div className="w-full grid grid-cols-2 gap-2 mt-4 pt-4 border-t border-slate-800/80 text-xs">
        <div className="p-2 rounded-lg bg-slate-950/60 border border-slate-800/80">
          <span className="text-slate-400 text-[11px]">Tồn khả dụng</span>
          <p className="font-bold text-emerald-400 font-mono text-sm mt-0.5">368 / 375 SKU</p>
        </div>
        <div className="p-2 rounded-lg bg-slate-950/60 border border-slate-800/80">
          <span className="text-slate-400 text-[11px]">Cảnh báo thiếu</span>
          <p className="font-bold text-amber-400 font-mono text-sm mt-0.5">7 SKU (&lt;30)</p>
        </div>
      </div>
    </div>
  );
}
