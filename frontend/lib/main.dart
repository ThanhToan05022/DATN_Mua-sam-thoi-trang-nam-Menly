import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/address/presentation/providers/address_provider.dart';
import 'features/product/presentation/providers/product_provider.dart';
import 'features/wishlist/presentation/providers/wishlist_provider.dart';
import 'features/wishlist/presentation/pages/wishlist_page.dart';
import 'features/cart/data/cart_model.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/product/presentation/pages/product_list_page.dart';
import 'features/product/presentation/pages/product_detail_page.dart';
import 'features/cart/presentation/pages/cart_page.dart';
import 'features/order/presentation/pages/checkout_page.dart';
import 'features/order/presentation/pages/order_list_page.dart';
import 'features/order/presentation/pages/order_detail_page.dart';
import 'features/order/presentation/pages/admin_order_management_page.dart';
import 'features/order/presentation/pages/order_success_page.dart';
import 'features/order/presentation/providers/order_provider.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/auth/presentation/pages/profile_page.dart';
import 'features/auth/presentation/pages/change_password_page.dart';
import 'features/auth/presentation/pages/shipping_address_page.dart';
import 'features/auth/presentation/pages/notifications_page.dart';
import 'features/auth/presentation/pages/help_support_page.dart';
import 'features/order/presentation/pages/my_orders_page.dart';
import 'features/splash/presentation/pages/splash_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  } catch (e) {
    debugPrint(
      'Supabase initialization notice (offline or local fallback): $e',
    );
  }

  runApp(const MenlyApp());
}

final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    // Splash screen
    GoRoute(path: '/splash', builder: (ctx, s) => const SplashPage()),

    // Auth routes — ngoài shell (không có bottom nav)
    GoRoute(
      path: '/login',
      builder: (ctx, s) =>
          LoginPage(redirect: s.uri.queryParameters['redirect']),
    ),
    GoRoute(
      path: '/register',
      builder: (ctx, s) =>
          RegisterPage(redirect: s.uri.queryParameters['redirect']),
    ),

    ShellRoute(
      builder: (ctx, state, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (ctx, s) => const HomePage()),
        GoRoute(
          path: '/products',
          builder: (ctx, s) {
            final catId =
                (s.extra as String?) ?? s.uri.queryParameters['categoryId'];
            return ProductListPage(
              key: ValueKey(catId ?? 'all'),
              initialCategoryId: catId,
            );
          },
        ),
        GoRoute(
          path: '/products/:id',
          builder: (ctx, s) =>
              ProductDetailPage(productId: s.pathParameters['id']!),
        ),
        GoRoute(path: '/cart', builder: (ctx, s) => const CartPage()),
        GoRoute(path: '/wishlist', builder: (ctx, s) => const WishlistPage()),
        GoRoute(path: '/checkout', builder: (ctx, s) => const CheckoutPage()),
        GoRoute(
          path: '/order-success',
          builder: (ctx, s) => OrderSuccessPage(
            orderCode: s.uri.queryParameters['code'],
            total: int.tryParse(s.uri.queryParameters['total'] ?? ''),
          ),
        ),
        GoRoute(path: '/orders', builder: (ctx, s) => const OrderListPage()),
        GoRoute(
          path: '/admin/orders',
          builder: (ctx, s) => const AdminOrderManagementPage(),
        ),
        GoRoute(path: '/profile', builder: (ctx, s) => const ProfilePage()),
        GoRoute(path: '/my-orders', builder: (ctx, s) => const MyOrdersPage()),
        GoRoute(path: '/shipping-address', builder: (ctx, s) => const ShippingAddressPage()),
        GoRoute(
          path: '/order-detail/:id',
          builder: (ctx, s) => OrderDetailPage(orderId: s.pathParameters['id'] ?? ''),
        ),
        GoRoute(path: '/change-password', builder: (ctx, s) => const ChangePasswordPage()),
        GoRoute(path: '/notifications', builder: (ctx, s) => const NotificationsPage()),
        GoRoute(path: '/help-support', builder: (ctx, s) => const HelpSupportPage()),
      ],
    ),
  ],
);

class MenlyApp extends StatelessWidget {
  const MenlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
      ],
      child: MaterialApp.router(
        title: 'Menly - Thời trang nam',
        theme: AppTheme.dark,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/products')) return 1;
    if (location.startsWith('/wishlist')) return 2;
    if (location.startsWith('/cart')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onTap(int i, BuildContext ctx) {
    switch (i) {
      case 0:
        ctx.go('/');
        break;
      case 1:
        ctx.go('/products');
        break;
      case 2:
        ctx.go('/wishlist');
        break;
      case 3:
        ctx.go('/cart');
        break;
      case 4:
        ctx.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartProvider>().totalItems;
    final favCount = context.watch<WishlistProvider>().favoriteCount;
    final currentIdx = _calculateSelectedIndex(context);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppTheme.border, width: 0.8),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIdx,
          onTap: (i) => _onTap(i, context),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppTheme.surface,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: AppTheme.textMuted,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Trang chủ',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded),
              label: 'Sản phẩm',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: favCount > 0,
                label: Text('$favCount'),
                backgroundColor: Colors.redAccent,
                textColor: Colors.white,
                child: const Icon(Icons.favorite_rounded),
              ),
              label: 'Yêu thích',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: cartCount > 0,
                label: Text('$cartCount'),
                backgroundColor: AppTheme.primary,
                textColor: Colors.black,
                child: const Icon(Icons.shopping_bag_rounded),
              ),
              label: 'Giỏ hàng',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Cá nhân',
            ),
          ],
        ),
      ),
    );
  }
}
