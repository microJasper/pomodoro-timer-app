import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_timer_app/screens/statistics_screen.dart';

void main() {
  group('�� Statistics Screen Widget Tests', () {
    testWidgets('StatisticsScreen should render', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: StatisticsScreen()),
      );
      expect(find.byType(StatisticsScreen), findsOneWidget);
    });
  });
}
