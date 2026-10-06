'use client';

import React from 'react';

export interface CircularProgressRingProps {
  value: number; // 0 to 100
  size?: number;
  strokeWidth?: number;
  title: string;
  subtitle: string;
  valueDisplay?: string;
  gradientFrom?: string;
  gradientTo?: string;
  badge?: string;
}

export function CircularProgressRing({
  value,
  size = 140,
  strokeWidth = 12,
  title,
  subtitle,
  valueDisplay,
  gradientFrom = '#f59e0b',
  gradientTo = '#fbbf24',
  badge,
}: CircularProgressRingProps) {
  const radius = (size - strokeWidth) / 2;
  const circumference = 2 * Math.PI * radius;
  const clampedValue = Math.min(100, Math.max(0, value));
  const strokeDashoffset = circumference - (clampedValue / 100) * circumference;
  const gradientId = `grad-${title.replace(/\s+/g, '-').toLowerCase()}`;

  return (
    <div className="flex flex-col items-center justify-between p-5 rounded-2xl bg-slate-900/60 border border-slate-800 hover:border-slate-700 transition-all duration-300 relative group">
      {badge && (
        <span className="absolute top-4 right-4 text-[10px] font-bold px-2 py-0.5 rounded-full bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
          {badge}
        </span>
      )}

      <div className="w-full text-left mb-3">
        <h4 className="text-xs font-semibold text-slate-400 uppercase tracking-wider">{title}</h4>
      </div>

      <div className="relative flex items-center justify-center my-2">
        <svg width={size} height={size} className="rotate-[-90deg] transition-all">
          <defs>
            <linearGradient id={gradientId} x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stopColor={gradientFrom} />
              <stop offset="100%" stopColor={gradientTo} />
            </linearGradient>
          </defs>

          {/* Background circle track */}
          <circle
            cx={size / 2}
            cy={size / 2}
            r={radius}
            stroke="currentColor"
            strokeWidth={strokeWidth}
            className="text-slate-800/80"
            fill="transparent"
          />

          {/* Animated Value circle */}
          <circle
            cx={size / 2}
            cy={size / 2}
            r={radius}
            stroke={`url(#${gradientId})`}
            strokeWidth={strokeWidth}
            strokeDasharray={circumference}
            strokeDashoffset={strokeDashoffset}
            strokeLinecap="round"
            fill="transparent"
            className="transition-all duration-1000 ease-out"
          />
        </svg>

        {/* Center Text */}
        <div className="absolute inset-0 flex flex-col items-center justify-center text-center px-2">
          <span className="text-xl sm:text-2xl font-extrabold text-white tracking-tight font-mono truncate max-w-full">
            {valueDisplay || `${Math.round(clampedValue)}%`}
          </span>
        </div>
      </div>

      <p className="text-xs text-slate-400 text-center mt-2 leading-relaxed">{subtitle}</p>
    </div>
  );
}
