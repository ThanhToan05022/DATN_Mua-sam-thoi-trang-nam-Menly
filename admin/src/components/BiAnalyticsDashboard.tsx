'use client';

import React from 'react';
import { Order, Product, Category } from '../lib/types';
import { BiTopMetrics } from './BiTopMetrics';

interface BiDashboardProps {
  orders: Order[];
  products: Product[];
  categories: Category[];
}

export function BiAnalyticsDashboard({ orders, products, categories }: BiDashboardProps) {
  return (
    <div className="space-y-5 bg-[#120822] p-6 rounded-3xl border border-[#2b164f] shadow-2xl text-white">
      {/* 1. TOP SECTION: Quick Stats & Top 5 Selling Products */}
      <BiTopMetrics orders={orders} products={products} categories={categories} />
    </div>
  );
}
