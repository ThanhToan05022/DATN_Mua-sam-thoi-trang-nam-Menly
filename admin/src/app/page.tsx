'use client';

import { useState, useEffect, useCallback, useMemo } from 'react';
import { Header } from '../components/Header';
import { DonutSegment } from '../components/CircularCharts';
import { BiAnalyticsDashboard } from '../components/BiAnalyticsDashboard';
import { DashboardCircularSection } from '../components/DashboardCircularSection';
import { DashboardDateFilter, DateFilterPreset } from '../components/DashboardDateFilter';
import {
  fetchAdminOrders,
  fetchCategories,
  fetchInventoryMovements,
  fetchAdminProducts,
} from '../lib/api';
import { Order, Category, InventoryMovement, Product } from '../lib/types';
import { Sparkles } from 'lucide-react';

function toLocalDateString(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

export default function DashboardPage() {
  const [categories, setCategories] = useState<Category[]>([]);
  const [orders, setOrders] = useState<Order[]>([]);
  const [, setMovements] = useState<InventoryMovement[]>([]);
  const [products, setProducts] = useState<Product[]>([]);

  // Date filter state
  const [preset, setPreset] = useState<DateFilterPreset>('all');
  const [customDay, setCustomDay] = useState('');
  const [fromDay, setFromDay] = useState('');
  const [toDay, setToDay] = useState('');

  const loadData = useCallback(async () => {
    try {
      const [cats, ords, movs, prods] = await Promise.all([
        fetchCategories(),
        fetchAdminOrders(),
        fetchInventoryMovements(),
        fetchAdminProducts({ limit: 125 }),
      ]);
      setCategories(cats);
      setOrders(ords);
      setMovements(movs);
      setProducts(prods.items || []);
    } catch (err) {
      console.error('Error loading dashboard data:', err);
    }
  }, []);

  useEffect(() => {
    loadData();
  }, [loadData]);

  // Realtime Polling (every 5 seconds)
  useEffect(() => {
    const interval = setInterval(() => {
      loadData();
    }, 5000);
    return () => clearInterval(interval);
  }, [loadData]);

  const safeOrders = useMemo(() => (Array.isArray(orders) ? orders : []), [orders]);

  // Filter orders according to date criteria
  const filteredOrders = useMemo(() => {
    if (preset === 'all') return safeOrders;

    const todayStr = toLocalDateString(new Date());

    const yesterdayObj = new Date();
    yesterdayObj.setDate(yesterdayObj.getDate() - 1);
    const yesterdayStr = toLocalDateString(yesterdayObj);

    const sevenDaysObj = new Date();
    sevenDaysObj.setDate(sevenDaysObj.getDate() - 7);
    const sevenDaysAgoStr = toLocalDateString(sevenDaysObj);

    const thirtyDaysObj = new Date();
    thirtyDaysObj.setDate(thirtyDaysObj.getDate() - 30);
    const thirtyDaysAgoStr = toLocalDateString(thirtyDaysObj);

    return safeOrders.filter((o) => {
      const orderDateStr = toLocalDateString(new Date(o.createdAt));
      if (preset === 'today') return orderDateStr === todayStr;
      if (preset === 'yesterday') return orderDateStr === yesterdayStr;
      if (preset === '7days') return orderDateStr >= sevenDaysAgoStr && orderDateStr <= todayStr;
      if (preset === '30days') return orderDateStr >= thirtyDaysAgoStr && orderDateStr <= todayStr;
      if (preset === 'custom_day') return customDay ? orderDateStr === customDay : true;
      if (preset === 'custom_range') {
        if (fromDay && orderDateStr < fromDay) return false;
        if (toDay && orderDateStr > toDay) return false;
        return true;
      }
      return true;
    });
  }, [safeOrders, preset, customDay, fromDay, toDay]);

  const totalOrdersCount = filteredOrders.length;
  const completedOrProcessing = filteredOrders.filter(
    (o) => o.status === 'completed' || o.status === 'shipping' || o.status === 'processing'
  ).length;
  const orderFulfillmentRate = totalOrdersCount > 0 ? Math.round((completedOrProcessing / totalOrdersCount) * 100) : 0;

  const totalRevenue = filteredOrders
    .filter((o) => o.status !== 'cancelled')
    .reduce((acc, o) => acc + o.total, 0);

  const dateLabel = useMemo(() => {
    if (preset === 'today') return 'Hôm nay';
    if (preset === 'yesterday') return 'Hôm qua';
    if (preset === '7days') return '7 ngày qua';
    if (preset === '30days') return '30 ngày qua';
    if (preset === 'custom_day' && customDay) {
      return `Ngày ${customDay.split('-').reverse().join('/')}`;
    }
    if (preset === 'custom_range' && (fromDay || toDay)) {
      const f = fromDay ? fromDay.split('-').reverse().join('/') : '...';
      const t = toDay ? toDay.split('-').reverse().join('/') : '...';
      return `${f} - ${t}`;
    }
    return 'Tất cả các ngày';
  }, [preset, customDay, fromDay, toDay]);

  // Category donut segments (5 categories x 25 items)
  const categoryColors = ['#f59e0b', '#3b82f6', '#10b981', '#6366f1', '#a855f7'];
  const donutSegments: DonutSegment[] = categories.map((cat, idx) => ({
    id: cat.id,
    label: cat.name,
    value: 25,
    count: 25,
    color: categoryColors[idx % categoryColors.length],
  }));

  const finalDonutSegments: DonutSegment[] =
    donutSegments.length > 0
      ? donutSegments
      : [
          { id: 'c1', label: 'Áo Sơ Mi Nam', value: 25, count: 25, color: '#f59e0b' },
          { id: 'c2', label: 'Áo Polo & T-Shirt', value: 25, count: 25, color: '#3b82f6' },
          { id: 'c3', label: 'Quần Tây & Kaki', value: 25, count: 25, color: '#10b981' },
          { id: 'c4', label: 'Quần Jeans Nam', value: 25, count: 25, color: '#6366f1' },
          { id: 'c5', label: 'Áo Khoác & Blazer', value: 25, count: 25, color: '#a855f7' },
        ];

  return (
    <div className="flex-1 flex flex-col">
      <Header
        title="Bảng điều khiển Tổng quan"
        subtitle="Hệ thống giám sát mua bán & vận hành"
        onRefresh={() => loadData()}
      />

      <div className="p-8 space-y-8 flex-1">
        {/* 1. DATE FILTER TOOLBAR */}
        <DashboardDateFilter
          preset={preset}
          customDay={customDay}
          fromDay={fromDay}
          toDay={toDay}
          onPresetChange={setPreset}
          onCustomDayChange={(day) => {
            setCustomDay(day);
            setPreset('custom_day');
          }}
          onRangeChange={(from, to) => {
            setFromDay(from);
            setToDay(to);
            setPreset('custom_range');
          }}
          onReset={() => {
            setPreset('all');
            setCustomDay('');
            setFromDay('');
            setToDay('');
          }}
          ordersCount={totalOrdersCount}
          revenue={totalRevenue}
        />

        {/* 2. BI ANALYTICS DASHBOARD SECTION */}
        <div className="space-y-3">
          <div className="flex items-center gap-2">
            <Sparkles className="w-4 h-4 text-cyan-400" />
            <h2 className="text-base font-bold text-white tracking-tight">
              Phân tích Hoạt động Mua bán & Hàng hoá ({dateLabel})
            </h2>
          </div>

          <BiAnalyticsDashboard orders={filteredOrders} products={products} categories={categories} />
        </div>

        {/* 3. CIRCULAR DASHBOARD GAUGES & RINGS SECTION */}
        <DashboardCircularSection
          orderFulfillmentRate={orderFulfillmentRate}
          completedOrProcessing={completedOrProcessing}
          totalOrdersCount={totalOrdersCount}
          totalRevenue={totalRevenue}
          finalDonutSegments={finalDonutSegments}
          dateLabel={dateLabel}
        />
      </div>
    </div>
  );
}
