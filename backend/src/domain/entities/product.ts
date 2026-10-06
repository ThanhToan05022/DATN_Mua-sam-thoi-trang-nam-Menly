export interface ProductSummary {
  id: string;
  name: string;
  slug: string;
  price: number;
  thumbnailUrl: string | null;
  createdAt: string;
}

export interface ProductVariant {
  id: string;
  productId: string;
  size: string;
  color: string;
  sku: string;
  stock: number;
}

export interface ProductImage {
  id: string;
  productId: string;
  url: string;
  sortOrder: number;
}

export interface ProductDetail {
  id: string;
  categoryId: string;
  name: string;
  slug: string;
  description: string | null;
  price: number;
  thumbnailUrl: string | null;
  isActive: boolean;
  createdAt: string;
  variants: ProductVariant[];
  images: ProductImage[];
}
