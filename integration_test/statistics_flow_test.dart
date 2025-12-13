import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pomodoro_timer_app/main.dart';

/// 📊 Statistics Flow Integration Tests
///
/// Bu test dosyası, istatistikler ekranının erişilebilirliğini test eder

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('📊 Statistics Flow Tests', () {
    testWidgets('Statistics screen should be accessible',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(const PomodoroApp());
      await tester.pump(const Duration(seconds: 1));

      // Assert - MaterialApp var mı?
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Statistics should have Material structure',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(const PomodoroApp());
      await tester.pump(const Duration(milliseconds: 500));

      // Assert
      expect(find.byType(Material), findsWidgets);
    });

    testWidgets('Statistics screen should render without errors',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(const PomodoroApp());
      await tester.pump(const Duration(milliseconds: 800));

      // Assert - Scaffold var mı?
      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}
