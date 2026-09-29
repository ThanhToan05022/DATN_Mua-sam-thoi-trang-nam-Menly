import { env } from './config/env.js';
import { createSupabaseClient } from './infrastructure/supabase/client.js';
import { LruCache } from './infrastructure/cache/lru.js';
import { VnpayGateway } from './infrastructure/vnpay/vnpay.gateway.js';

import { CategoryModel } from './models/category.model.js';
import { ProductModel } from './models/product.model.js';
import { CartModel } from './models/cart.model.js';
import { OrderModel, DEFAULT_MOCK_ORDERS } from './models/order.model.js';
import { PaymentModel } from './models/payment.model.js';
import { AdminModel } from './models/admin.model.js';
import { AuthModel } from './models/auth.model.js';
import { UserModel } from './models/user.model.js';
import { WishlistModel } from './models/wishlist.model.js';

import { CategoryViewModel } from './viewmodels/category.viewmodel.js';
import { ProductViewModel } from './viewmodels/product.viewmodel.js';
import { CartViewModel } from './viewmodels/cart.viewmodel.js';
import { OrderViewModel } from './viewmodels/order.viewmodel.js';
import { PaymentViewModel } from './viewmodels/payment.viewmodel.js';
import { AdminViewModel } from './viewmodels/admin.viewmodel.js';
import { AuthViewModel } from './viewmodels/auth.viewmodel.js';
import { UserViewModel } from './viewmodels/user.viewmodel.js';
import { WishlistViewModel } from './viewmodels/wishlist.viewmodel.js';

import { ProductSummary, Category, Page } from './models/types.js';

// 1. Supabase Client
const useSupabase =
  process.env.NODE_ENV !== 'test' &&
  !env.USE_MOCK_DB &&
  Boolean(env.SUPABASE_SERVICE_ROLE_KEY);

export const supabase = useSupabase
  ? createSupabaseClient(env.SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY)
  : undefined;

// 2. Gateways & In-memory Caches
export const vnpayGateway = new VnpayGateway({
  tmnCode: env.VNPAY_TMN_CODE,
  hashSecret: env.VNPAY_HASH_SECRET,
  payUrl: env.VNPAY_PAY_URL,
  returnUrl: env.VNPAY_RETURN_URL,
});

export const productCache = new LruCache<Page<ProductSummary>>(100, 30_000);
export const categoryCache = new LruCache<Category[]>(20, 300_000);

// 3. Models (Data Access Layer - M in MVVM)
export const categoryModel = new CategoryModel(supabase);
export const productModel = new ProductModel(supabase);
export const cartModel = new CartModel(supabase);
export const orderModel = new OrderModel(supabase, DEFAULT_MOCK_ORDERS);
export const paymentModel = new PaymentModel(supabase);
export const adminModel = new AdminModel(supabase);
export const userModel = new UserModel(supabase);
export const authModel = new AuthModel(supabase, userModel);
export const wishlistModel = new WishlistModel(supabase, productModel);

// 4. ViewModels (Business Logic & State - VM in MVVM)
export const viewModels = {
  category: new CategoryViewModel(categoryModel, categoryCache),
  product: new ProductViewModel(productModel, productCache),
  cart: new CartViewModel(cartModel),
  order: new OrderViewModel(orderModel, cartModel),
  payment: new PaymentViewModel(orderModel, paymentModel, vnpayGateway),
  admin: new AdminViewModel(adminModel, orderModel),
  auth: new AuthViewModel(authModel),
  user: new UserViewModel(userModel),
  wishlist: new WishlistViewModel(wishlistModel),
};

// Compatibility adapter for useCases
export const useCases = {
  listProducts: { execute: (q: any) => viewModels.product.listProducts(q) },
  getProduct: { execute: (id: string) => viewModels.product.getProductDetail(id) },
  listCategories: { execute: () => viewModels.category.getCategories() },
  getCart: { execute: (uid: string) => viewModels.cart.getCart(uid) },
  upsertCartItem: { execute: (i: any) => viewModels.cart.updateItem(i.userId, i.variantId, i.quantity) },
  removeCartItem: { execute: (uid: string, vid: string) => viewModels.cart.removeItem(uid, vid) },
  createOrder: { execute: (r: any) => viewModels.order.createOrder(r) },
  getOrder: { execute: (id: string, uid: string, adm: boolean) => viewModels.order.getOrder(id, uid, adm) },
  listMyOrders: { execute: (i: any) => viewModels.order.listMyOrders(i.userId, i.limit, i.cursor) },
  trackOrder: { execute: (c: string, p: string) => viewModels.order.trackOrder(c, p) },
  createPayment: { execute: (i: any) => viewModels.payment.createPaymentUrl(i) },
  handleIpn: { execute: (q: any) => viewModels.payment.handleIpn(q) },
  adjustStock: { execute: (i: any) => viewModels.admin.adjustStock(i.variantId, i.delta, i.reason, i.note, i.adminId) },
  updateOrderStatus: { execute: (i: any) => viewModels.admin.updateOrderStatus(i.orderId, i.status, i.note, i.adminId) },
  listAdminOrders: { execute: (i: any) => viewModels.admin.listOrders(i.limit, i.status, i.cursor) },
  setUserRole: { execute: (uid: string, r: any) => viewModels.admin.setUserRole(uid, r) },
  listMovements: { execute: (vid?: string, l?: number) => viewModels.admin.listMovements(vid, l) },
  listAudit: { execute: (l?: number) => viewModels.admin.listAudit(l) },
};
