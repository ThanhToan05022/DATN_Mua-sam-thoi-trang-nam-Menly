import type { Product, Category } from './types';

export const INITIAL_CATEGORIES: Category[] = [
  {
    id: 'cat-001',
    name: 'Áo',
    slug: 'ao',
    description: 'Các loại áo thời trang nam',
    imageUrl: null,
  },
  {
    id: 'cat-002',
    name: 'Quần',
    slug: 'quan',
    description: 'Các loại quần thời trang nam',
    imageUrl: null,
  },
  {
    id: 'cat-003',
    name: 'Phụ kiện',
    slug: 'phu-kien',
    description: 'Phụ kiện thời trang nam',
    imageUrl: null,
  },
];

export const INITIAL_PRODUCTS: Product[] = [
  {
    id: 'prod-001',
    categoryId: 'cat-001',
    name: 'Áo Polo Classic',
    slug: 'ao-polo-classic',
    description: 'Áo polo nam phong cách classic',
    price: 350000,
    thumbnailUrl: null,
    isActive: true,
    createdAt: new Date().toISOString(),
    variants: [
      { id: 'v-001-s', productId: 'prod-001', size: 'S', color: 'Trắng', sku: 'POLO-S-TG', stock: 10 },
      { id: 'v-001-m', productId: 'prod-001', size: 'M', color: 'Trắng', sku: 'POLO-M-TG', stock: 15 },
      { id: 'v-001-l', productId: 'prod-001', size: 'L', color: 'Trắng', sku: 'POLO-L-TG', stock: 12 },
    ],
  },
  {
    id: 'prod-002',
    categoryId: 'cat-002',
    name: 'Quần Jeans Slim Fit',
    slug: 'quan-jeans-slim-fit',
    description: 'Quần jeans nam slim fit cao cấp',
    price: 550000,
    thumbnailUrl: null,
    isActive: true,
    createdAt: new Date().toISOString(),
    variants: [
      { id: 'v-002-28', productId: 'prod-002', size: '28', color: 'Xanh', sku: 'JEAN-28-X', stock: 8 },
      { id: 'v-002-30', productId: 'prod-002', size: '30', color: 'Xanh', sku: 'JEAN-30-X', stock: 20 },
      { id: 'v-002-32', productId: 'prod-002', size: '32', color: 'Xanh', sku: 'JEAN-32-X', stock: 15 },
    ],
  },
];
