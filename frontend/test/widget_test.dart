import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/theme_controller.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    final themeController = ThemeController();
    await tester.pumpWidget(MenlyApp(themeController: themeController));
    expect(find.byType(MenlyApp), findsOneWidget);
  });
}
