import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pomodoro_timer_app/main.dart';

/// ⏱️ Timer Flow Integration Tests
///
/// Bu test dosyası, timer ekranı ve işlevselliğini test eder

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('⏱️ Timer Flow Tests', () {
    testWidgets('Timer screen should load successfully',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(const PomodoroApp());
      await tester.pump(const Duration(seconds: 1));

      // Assert - Scaffold var mı?
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('Timer screen should have Material structure',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(const PomodoroApp());
      await tester.pump(const Duration(milliseconds: 500));

      // Assert
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Timer screen should render without layout errors',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(const PomodoroApp());
      await tester.pump(const Duration(milliseconds: 800));

      // Assert - Widget tree rendered
      expect(find.byType(Material), findsWidgets);
    });
  });
}
