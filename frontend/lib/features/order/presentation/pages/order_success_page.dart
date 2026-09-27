import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class OrderSuccessPage extends StatelessWidget {
  const OrderSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.success, width: 2),
                ),
                child: const Icon(Icons.check_rounded, color: AppTheme.success, size: 56),
              ),
              const SizedBox(height: 24),
              const Text('Đặt hàng thành công!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
              const SizedBox(height: 12),
              const Text('Cảm ơn bạn đã mua sắm tại Menly.\nĐơn hàng của bạn đang được xử lý.',
                  textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5)),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Tiếp tục mua sắm'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/products'),
                child: const Text('Xem sản phẩm khác', style: TextStyle(color: AppTheme.primary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
