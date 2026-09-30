'use client';

import { useState, useEffect, useCallback } from 'react';
import { Header } from '../../components/Header';
import { InventoryProductsTable } from '../../components/InventoryProductsTable';
import { InventoryRestockForm } from '../../components/InventoryRestockForm';
import { InventoryMovementsTable } from '../../components/InventoryMovementsTable';
import {
  fetchInventoryMovements,
  fetchAdminProducts,
  fetchCategories,
} from '../../lib/api';
import { InventoryMovement, Product, Category } from '../../lib/types';

export default function InventoryPage() {
  const [movements, setMovements] = useState<InventoryMovement[]>([]);
  const [products, setProducts] = useState<Product[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedVariantId, setSelectedVariantId] = useState('');

  const loadData = useCallback(async () => {
    setLoading(true);
    try {
      const [movs, prods, cats] = await Promise.all([
        fetchInventoryMovements(),
        fetchAdminProducts({ limit: 400 }),
        fetchCategories(),
      ]);
      setMovements(movs);
      setProducts(prods.items || []);
      setCategories(cats || []);
      if (
        prods.items &&
        prods.items.length > 0 &&
        prods.items[0].variants &&
        prods.items[0].variants.length > 0
      ) {
        setSelectedVariantId(prods.items[0].variants[0].id);
      }
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadData();
  }, [loadData]);

  const reloadMovementsAndProducts = async () => {
    const [updatedMovs, updatedProds] = await Promise.all([
      fetchInventoryMovements(),
      fetchAdminProducts({ limit: 400 }),
    ]);
    setMovements(updatedMovs);
    setProducts(updatedProds.items || []);
  };

  return (
    <div className="flex-1 flex flex-col">
      <Header
        title="Quản lý Kho Hàng & Tồn Kho Toàn Bộ Sản Phẩm"
        subtitle="Theo dõi toàn bộ 125 sản phẩm (25 sản phẩm / danh mục), số lượng tồn kho theo từng kích cỡ và hiệu chỉnh xuất nhập tồn"
        onRefresh={loadData}
      />

      <div className="p-8 space-y-8 flex-1">
        {/* Quick restock and policy cards */}
        <InventoryRestockForm
          products={products}
          selectedVariantId={selectedVariantId}
          onVariantChange={setSelectedVariantId}
          onSuccess={reloadMovementsAndProducts}
        />

        {/* 1. HIỂN THỊ TOÀN BỘ SẢN PHẨM & SỐ LƯỢNG ĐANG CÓ */}
        <InventoryProductsTable
          products={products}
          categories={categories}
          loading={loading}
          onSelectVariantToAdjust={(variantId) => {
            setSelectedVariantId(variantId);
            window.scrollTo({ top: 0, behavior: 'smooth' });
          }}
        />

        {/* 2. LỊCH SỬ BIẾN ĐỘNG KHO */}
        <InventoryMovementsTable movements={movements} loading={loading} />
      </div>
    </div>
  );
}
