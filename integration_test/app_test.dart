import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pomodoro_timer_app/main.dart';

/// 🚀 App Integration Tests
///
/// Bu test dosyası, uygulamanın temel başlatma testlerini içerir

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('🚀 App Launch Tests', () {
    testWidgets('App should launch successfully', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(const PomodoroApp());
      await tester.pump();

      // Assert - MaterialApp var mı?
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('App should have Material structure',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(const PomodoroApp());
      await tester.pump();

      // Assert
      expect(find.byType(Material), findsWidgets);
    });

    testWidgets('App should render without errors',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(const PomodoroApp());
      await tester.pump(const Duration(milliseconds: 500));

      // Assert - Scaffold var mı?
      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}
