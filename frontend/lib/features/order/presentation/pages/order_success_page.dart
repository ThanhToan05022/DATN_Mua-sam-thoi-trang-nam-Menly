import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_buttons.dart';

class OrderSuccessPage extends StatefulWidget {
  final String? orderCode;
  final int? total;
  const OrderSuccessPage({super.key, this.orderCode, this.total});
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

  String _fmt(int? val) {
    if (val == null) return '';
    final s = val.toStringAsFixed(0);
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return '${b.toString()}đ';
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        boxShadow: [BoxShadow(color: c.success.withValues(alpha: 0.4), blurRadius: 28, spreadRadius: 4)],
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 52),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(children: [
                  Text('Đặt hàng thành công!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: c.textPrimary, fontSize: 24, fontWeight: FontWeight.w900, height: 1.2)),
                  const SizedBox(height: 8),
                  Text('Cảm ơn bạn đã mua sắm tại Menly.\nĐơn hàng đang được xử lý và sẽ\ngiao đến bạn sớm nhất có thể.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: c.textSecondary, fontSize: 14, height: 1.6)),
                  if (widget.orderCode != null && widget.orderCode!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: c.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        border: Border.all(color: c.secondary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.receipt_long_rounded, color: c.secondary, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('MÃ ĐƠN HÀNG', style: TextStyle(color: c.textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                                const SizedBox(height: 2),
                                Text(widget.orderCode!, style: TextStyle(color: c.textPrimary, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.copy_rounded, color: c.secondary, size: 20),
                            tooltip: 'Sao chép mã đơn',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: widget.orderCode!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Đã sao chép mã đơn hàng'), duration: Duration(seconds: 2)),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (widget.total != null && widget.total! > 0) ...[
                    const SizedBox(height: 8),
                    Text('Tổng thanh toán: ${_fmt(widget.total)}',
                        style: TextStyle(color: c.secondary, fontSize: 14, fontWeight: FontWeight.w700)),
                  ],
                ]),
              ),
              const SizedBox(height: 32),

              // Info cards
              Row(children: const [
                _InfoCard(icon: Icons.local_shipping_rounded, title: 'Giao hàng', subtitle: '2–3 ngày'),
                SizedBox(width: 12),
                _InfoCard(icon: Icons.support_agent_rounded, title: 'Hỗ trợ', subtitle: '24/7'),
                SizedBox(width: 12),
                _InfoCard(icon: Icons.verified_rounded, title: 'Chính hãng', subtitle: '100%'),
              ]),
              const SizedBox(height: 32),

              PrimaryButton(
                label: 'Tiếp tục mua sắm',
                onPressed: () => context.go('/'),
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: 'Xem đơn hàng của tôi',
                onPressed: () => context.go('/orders'),
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
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: c.border.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: c.shadow,
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(children: [
          Icon(icon, color: c.secondary, size: 24),
          const SizedBox(height: 6),
          Text(title, style: TextStyle(color: c.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
          Text(subtitle, style: TextStyle(color: c.textMuted, fontSize: 11)),
        ]),
      ),
    );
  }
}
