import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class OrderSuccessPage extends StatefulWidget {
  const OrderSuccessPage({super.key});
  @override
  State<OrderSuccessPage> createState() => _OrderSuccessPageState();
}

class _OrderSuccessPageState extends State<OrderSuccessPage> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    Future.delayed(const Duration(milliseconds: 200), () => _ctrl.forward());
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Animated checkmark
              ScaleTransition(
                scale: _scaleAnim,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Center(
                    child: Container(
                      width: 110, height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        boxShadow: [BoxShadow(color: AppTheme.success.withOpacity(0.4), blurRadius: 28, spreadRadius: 4)],
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 56),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(children: const [
                  Text('Đặt hàng thành công!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, height: 1.2)),
                  SizedBox(height: 12),
                  Text('Cảm ơn bạn đã mua sắm tại Menly.\nĐơn hàng đang được xử lý và sẽ\ngiao đến bạn sớm nhất có thể.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 15, height: 1.7)),
                ]),
              ),
              const SizedBox(height: 48),

              // Info cards
              Row(children: [
                _InfoCard(icon: Icons.local_shipping_rounded, title: 'Giao hàng', subtitle: '2–3 ngày'),
                const SizedBox(width: 12),
                _InfoCard(icon: Icons.support_agent_rounded, title: 'Hỗ trợ', subtitle: '24/7'),
                const SizedBox(width: 12),
                _InfoCard(icon: Icons.verified_rounded, title: 'Chính hãng', subtitle: '100%'),
              ]),
              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: () => context.go('/'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Tiếp tục mua sắm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black)),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go('/profile'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  side: BorderSide(color: AppTheme.border2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Xem đơn hàng của tôi', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _InfoCard({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(children: [
        Icon(icon, color: AppTheme.primary, size: 24),
        const SizedBox(height: 6),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
        Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
      ]),
    ),
  );
}
