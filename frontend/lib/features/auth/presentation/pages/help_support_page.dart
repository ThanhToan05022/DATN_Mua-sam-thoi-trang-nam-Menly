import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/pressable.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: const Text('Trợ giúp & Hỗ trợ'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: c.primary,
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            ),
            child: Column(
              children: [
                Icon(Icons.support_agent_rounded, color: c.onPrimary, size: 48),
                const SizedBox(height: AppSpacing.md),
                Text('Xin chào! Chúng tôi có thể giúp gì?',
                    style: TextStyle(color: c.onPrimary, fontSize: 18, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.xs),
                Text('Đội ngũ hỗ trợ sẵn sàng giúp đỡ bạn',
                    style: TextStyle(color: c.onPrimary.withValues(alpha: 0.8), fontSize: 13), textAlign: TextAlign.center),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Contact options
          Text('Liên hệ với chúng tôi',
              style: TextStyle(color: c.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.md),
          _contactCard(
            context,
            icon: Icons.phone_rounded,
            label: 'Hotline',
            value: '1900 xxxx',
            subtitle: 'Thứ 2 - Thứ 7, 8:00 - 21:00',
            color: c.success,
            onTap: () => _launchUrl('tel:1900xxxx'),
          ),
          const SizedBox(height: AppSpacing.md),
          _contactCard(
            context,
            icon: Icons.email_rounded,
            label: 'Email',
            value: 'support@menly.vn',
            subtitle: 'Phản hồi trong vòng 24 giờ',
            color: c.secondary,
            onTap: () => _launchUrl('mailto:support@menly.vn'),
          ),
          const SizedBox(height: AppSpacing.md),
          _contactCard(
            context,
            icon: Icons.chat_rounded,
            label: 'Zalo',
            value: 'Menly Official',
            subtitle: 'Chat trực tiếp với nhân viên',
            color: const Color(0xFF0068FF),
            onTap: () => _launchUrl('https://zalo.me/0123456789'),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // FAQ
          Text('Câu hỏi thường gặp',
              style: TextStyle(color: c.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.md),
          _faqItem(
            question: 'Làm sao để đặt hàng?',
            answer: 'Bạn chọn sản phẩm → thêm vào giỏ hàng → vào giỏ hàng → bấm Thanh toán → điền thông tin giao hàng → xác nhận đặt hàng.',
          ),
          _faqItem(
            question: 'Phí vận chuyển là bao nhiêu?',
            answer: 'Phí vận chuyển: miễn phí cho đơn hàng trên 500.000đ. Đơn hàng dưới 500.000đ sẽ tính phí 30.000đ.',
          ),
          _faqItem(
            question: 'Chính sách đổi trả như thế nào?',
            answer: 'Menly hỗ trợ đổi trả trong vòng 7 ngày kể từ khi nhận hàng. Sản phẩm đổi trả phải còn nguyên tem mác, chưa qua sử dụng.',
          ),
          _faqItem(
            question: 'Thời gian giao hàng mất bao lâu?',
            answer: 'Nội thành HCM/HN: 1-2 ngày. Các tỉnh thành khác: 3-5 ngày. Đơn hàng trước 14:00 sẽ được giao trong ngày (nội thành).',
          ),
          _faqItem(
            question: 'Có hỗ trợ thanh toán online không?',
            answer: 'Có, Menly hỗ trợ thanh toán qua VNPay (ATM, Visa, MasterCard, QR Code) và thanh toán khi nhận hàng (COD).',
          ),
          const SizedBox(height: AppSpacing.xxl),

          // App info
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: c.border.withValues(alpha: 0.6)),
              boxShadow: [
                BoxShadow(
                    color: c.shadow, blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: c.primary,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: Icon(Icons.shopping_bag_rounded, color: c.onPrimary, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MENLY', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 1)),
                        Text('Phiên bản 1.0.0', style: TextStyle(color: c.textMuted, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Divider(color: c.border.withValues(alpha: 0.6)),
                const SizedBox(height: AppSpacing.sm),
                Text('© 2026 Menly - Thời trang nam cao cấp.\nMọi quyền được bảo lưu.',
                    style: TextStyle(color: c.textMuted, fontSize: 11), textAlign: TextAlign.center),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _contactCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final c = AppColors.of(context);
    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: c.border.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
                color: c.shadow, blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: c.textMuted, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(value, style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: c.textMuted, fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: c.textMuted, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _faqItem({required String question, required String answer}) {
    return _FAQExpandable(question: question, answer: answer);
  }

  static Future<void> _launchUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      // Silently fail if can't launch
    }
  }
}

class _FAQExpandable extends StatefulWidget {
  final String question;
  final String answer;
  const _FAQExpandable({required this.question, required this.answer});
  @override
  State<_FAQExpandable> createState() => _FAQExpandableState();
}

class _FAQExpandableState extends State<_FAQExpandable> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Pressable(
      onTap: () => setState(() => _expanded = !_expanded),
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: _expanded ? c.secondary.withValues(alpha: 0.3) : c.border.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
                color: c.shadow, blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(widget.question,
                      style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down_rounded, color: c.textMuted, size: 20),
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 10),
              Divider(color: c.surfaceVariant, height: 1),
              const SizedBox(height: 10),
              Text(widget.answer,
                  style: TextStyle(color: c.textSecondary, fontSize: 12, height: 1.5)),
            ],
          ],
        ),
      ),
    );
  }
}
