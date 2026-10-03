export interface CartItem {
  userId: string;
  variantId: string;
  quantity: number;
  productName: string;
  size: string;
  color: string;
  price: number;
  stock: number;
  thumbnailUrl: string | null;
  updatedAt: string;
}

export interface Cart {
  items: CartItem[];
  totalItems: number;
  subtotal: number;
}
