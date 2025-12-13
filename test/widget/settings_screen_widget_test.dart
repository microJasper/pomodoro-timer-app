import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_timer_app/screens/settings_screen.dart';

void main() {
  group('⚙️ Settings Screen Widget Tests', () {
    testWidgets('SettingsScreen should render', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SettingsScreen()),
      );
      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });
}
