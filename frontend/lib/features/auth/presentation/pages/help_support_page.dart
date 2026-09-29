import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Trợ giúp & Hỗ trợ'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.support_agent_rounded, color: Colors.white, size: 48),
                const SizedBox(height: 12),
                const Text('Xin chào! Chúng tôi có thể giúp gì?',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Text('Đội ngũ hỗ trợ sẵn sàng giúp đỡ bạn',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13), textAlign: TextAlign.center),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Contact options
          const Text('Liên hệ với chúng tôi',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _contactCard(
            icon: Icons.phone_rounded,
            label: 'Hotline',
            value: '1900 xxxx',
            subtitle: 'Thứ 2 - Thứ 7, 8:00 - 21:00',
            color: AppTheme.success,
            onTap: () => _launchUrl('tel:1900xxxx'),
          ),
          const SizedBox(height: 10),
          _contactCard(
            icon: Icons.email_rounded,
            label: 'Email',
            value: 'support@menly.vn',
            subtitle: 'Phản hồi trong vòng 24 giờ',
            color: AppTheme.info,
            onTap: () => _launchUrl('mailto:support@menly.vn'),
          ),
          const SizedBox(height: 10),
          _contactCard(
            icon: Icons.chat_rounded,
            label: 'Zalo',
            value: 'Menly Official',
            subtitle: 'Chat trực tiếp với nhân viên',
            color: const Color(0xFF0068FF),
            onTap: () => _launchUrl('https://zalo.me/0123456789'),
          ),
          const SizedBox(height: 24),

          // FAQ
          const Text('Câu hỏi thường gặp',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
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
          const SizedBox(height: 24),

          // App info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.surface2),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MENLY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 1)),
                        Text('Phiên bản 1.0.0', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: AppTheme.surface2),
                const SizedBox(height: 8),
                const Text('© 2026 Menly - Thời trang nam cao cấp.\nMọi quyền được bảo lưu.',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 11), textAlign: TextAlign.center),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _contactCard({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.surface2),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textMuted, size: 14),
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
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _expanded ? AppTheme.primary.withOpacity(0.3) : AppTheme.surface2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(widget.question,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textMuted, size: 20),
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 10),
              const Divider(color: AppTheme.surface2, height: 1),
              const SizedBox(height: 10),
              Text(widget.answer,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.5)),
            ],
          ],
        ),
      ),
    );
  }
}
