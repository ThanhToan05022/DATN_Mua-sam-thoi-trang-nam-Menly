'use client';

import React from 'react';
import { ProductVariant } from '../lib/types';

export function getColorHex(colorName?: string): string {
  if (!colorName) return '#94a3b8';
  const c = colorName.toLowerCase().trim();
  if (c.includes('đen') || c.includes('black')) return '#1e293b';
  if (c.includes('trắng') || c.includes('white')) return '#f8fafc';
  if (c.includes('xám') || c.includes('ghi') || c.includes('grey') || c.includes('gray')) return '#64748b';
  if (c.includes('đỏ') || c.includes('red')) return '#ef4444';
  if (c.includes('navy') || c.includes('xanh than')) return '#1e3a8a';
  if (c.includes('xanh lam') || c.includes('xanh dương') || c.includes('blue')) return '#3b82f6';
  if (c.includes('xanh lá') || c.includes('rêu') || c.includes('green')) return '#10b981';
  if (c.includes('vàng') || c.includes('yellow')) return '#f59e0b';
  if (c.includes('cam') || c.includes('orange')) return '#f97316';
  if (c.includes('hồng') || c.includes('pink')) return '#ec4899';
  if (c.includes('tím') || c.includes('purple')) return '#8b5cf6';
  if (c.includes('nâu') || c.includes('brown')) return '#78350f';
  if (c.includes('be') || c.includes('beige') || c.includes('kem')) return '#d4d4d8';
  return '#38bdf8';
}

export interface CompactVariantDisplayProps {
  variants?: ProductVariant[];
  showStockCount?: boolean;
  sizePrefix?: string;
  colorPrefix?: string;
  className?: string;
}

export function CompactVariantDisplay({
  variants = [],
  showStockCount = false,
  sizePrefix = 'Size:',
  colorPrefix = 'Màu:',
  className = '',
}: CompactVariantDisplayProps) {
  // If no variants provided, show default size pills
  if (!variants || variants.length === 0) {
    const defaultSizes = ['S', 'M', 'L', 'XL', 'XXL'];
    return (
      <div className={`flex flex-col gap-1.5 ${className}`}>
        <div className="flex items-center gap-1.5 flex-wrap">
          <span className="text-[10px] font-semibold text-slate-400 uppercase tracking-wider shrink-0">
            {sizePrefix}
          </span>
          <div className="flex items-center gap-1 flex-wrap">
            {defaultSizes.map((s) => (
              <span
                key={s}
                className="px-1.5 py-0.5 rounded-md bg-slate-900 border border-slate-700/80 text-[11px] font-mono font-bold text-amber-400 shadow-xs"
              >
                {s}
              </span>
            ))}
          </div>
        </div>
      </div>
    );
  }

  // Aggregate unique sizes and their total stock
  const uniqueSizes: { size: string; stock: number }[] = [];
  const seenSizes = new Set<string>();
  for (const v of variants) {
    const s = (v.size || '').trim();
    if (!s) continue;
    if (!seenSizes.has(s)) {
      seenSizes.add(s);
      uniqueSizes.push({ size: s, stock: v.stock || 0 });
    } else {
      const existing = uniqueSizes.find((item) => item.size === s);
      if (existing) existing.stock += v.stock || 0;
    }
  }

  // Aggregate unique colors and their total stock
  const uniqueColors: { color: string; stock: number }[] = [];
  const seenColors = new Set<string>();
  for (const v of variants) {
    const c = (v.color || '').trim();
    if (!c) continue;
    if (!seenColors.has(c)) {
      seenColors.add(c);
      uniqueColors.push({ color: c, stock: v.stock || 0 });
    } else {
      const existing = uniqueColors.find((item) => item.color === c);
      if (existing) existing.stock += v.stock || 0;
    }
  }

  return (
    <div className={`flex flex-col gap-1.5 ${className}`}>
      {/* Size row on top (Bên trên là Size) */}
      <div className="flex items-center gap-1.5 flex-wrap">
        <span className="text-[10px] font-semibold text-slate-400 uppercase tracking-wider shrink-0">
          {sizePrefix}
        </span>
        <div className="flex items-center gap-1 flex-wrap">
          {uniqueSizes.map((s) => (
            <span
              key={s.size}
              className="inline-flex items-center gap-1 px-1.5 py-0.5 rounded-md bg-slate-900 border border-slate-700/80 text-[11px] font-mono shadow-xs"
            >
              <strong className="text-amber-400 font-bold">{s.size}</strong>
              {showStockCount && (
                <span className="text-white text-[10px] font-bold">({s.stock})</span>
              )}
            </span>
          ))}
        </div>
      </div>

      {/* Color row below (Bên dưới là Màu) */}
      {uniqueColors.length > 0 && (
        <div className="flex items-center gap-1.5 flex-wrap">
          <span className="text-[10px] font-semibold text-slate-400 uppercase tracking-wider shrink-0">
            {colorPrefix}
          </span>
          <div className="flex items-center gap-1 flex-wrap">
            {uniqueColors.map((c) => (
              <span
                key={c.color}
                className="inline-flex items-center gap-1.5 px-1.5 py-0.5 rounded-md bg-slate-950/80 border border-slate-800 text-[11px] text-slate-300 font-medium shadow-xs"
              >
                <span
                  className="w-2 h-2 rounded-full border border-white/20 shrink-0"
                  style={{ backgroundColor: getColorHex(c.color) }}
                />
                <span>{c.color}</span>
                {showStockCount && (
                  <span className="text-slate-400 text-[10px] font-mono">({c.stock})</span>
                )}
              </span>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
