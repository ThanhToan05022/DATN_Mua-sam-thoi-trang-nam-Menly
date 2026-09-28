import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/cart/data/cart_model.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/product/presentation/pages/product_list_page.dart';
import 'features/product/presentation/pages/product_detail_page.dart';
import 'features/cart/presentation/pages/cart_page.dart';
import 'features/order/presentation/pages/checkout_page.dart';
import 'features/order/presentation/pages/order_success_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/auth/presentation/pages/profile_page.dart';
import 'features/splash/presentation/pages/splash_page.dart';

void main() {
  runApp(const MenlyApp());
}

final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    // Splash screen
    GoRoute(path: '/splash', builder: (ctx, s) => const SplashPage()),

    // Auth routes — ngoài shell (không có bottom nav)
    GoRoute(path: '/login', builder: (ctx, s) => const LoginPage()),
    GoRoute(path: '/register', builder: (ctx, s) => const RegisterPage()),


    ShellRoute(
      builder: (ctx, state, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (ctx, s) => const HomePage()),
        GoRoute(
          path: '/products',
          builder: (ctx, s) {
            final catId = (s.extra as String?) ?? s.uri.queryParameters['categoryId'];
            return ProductListPage(
              key: ValueKey(catId ?? 'all'),
              initialCategoryId: catId,
            );
          },
        ),
        GoRoute(
          path: '/products/:id',
          builder: (ctx, s) => ProductDetailPage(productId: s.pathParameters['id']!),
        ),
        GoRoute(path: '/cart', builder: (ctx, s) => const CartPage()),
        GoRoute(path: '/checkout', builder: (ctx, s) => const CheckoutPage()),
        GoRoute(path: '/order-success', builder: (ctx, s) => const OrderSuccessPage()),
        GoRoute(path: '/profile', builder: (ctx, s) => const ProfilePage()),
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
        ChangeNotifierProvider(create: (_) => CartProvider()),
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
    if (location.startsWith('/cart')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onTap(int i, BuildContext ctx) {
    switch (i) {
      case 0: ctx.go('/'); break;
      case 1: ctx.go('/products'); break;
      case 2: ctx.go('/cart'); break;
      case 3: ctx.go('/profile'); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartProvider>().totalItems;
    final currentIdx = _calculateSelectedIndex(context);
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIdx,
        onTap: (i) => _onTap(i, context),
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Trang chủ'),
          const BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Sản phẩm'),
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
          const BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Tài khoản'),
        ],
      ),
    );
  }
}
