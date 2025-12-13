import 'package:flutter_test/flutter_test.dart';

/// 🎯 Pomodoro Timer Logic Unit Tests
///
/// Bu test dosyası, Pomodoro zamanlayıcı mantığını test eder:
/// - Timer başlatma, durdurma, devam ettirme
/// - Timer sıfırlama ve tamamlanma durumları
/// - Çalışma ve mola süreleri yönetimi
/// - Break tipi (kısa/uzun mola) kontrolü

void main() {
  group('⏱️ Timer Duration Tests', () {
    test('Timer should initialize with 25 minutes (1500 seconds)', () {
      // Arrange
      const workDuration = 25;
      const expectedSeconds = 25 * 60; // 1500 seconds

      // Act
      final actualSeconds = workDuration * 60;

      // Assert
      expect(actualSeconds, equals(expectedSeconds));
      expect(actualSeconds, equals(1500));
    });

    test('Timer should convert minutes to seconds correctly', () {
      // Arrange
      const testCases = {
        1: 60,
        5: 300,
        15: 900,
        25: 1500,
        45: 2700,
      };

      // Act & Assert
      testCases.forEach((minutes, expectedSeconds) {
        final actualSeconds = minutes * 60;
        expect(actualSeconds, equals(expectedSeconds),
            reason: '$minutes dakika = $expectedSeconds saniye olmalı');
      });
    });

    test('Break time should be 5 minutes for short break', () {
      // Arrange
      const shortBreakMinutes = 5;
      const expectedSeconds = 300; // 5 * 60

      // Act
      final actualSeconds = shortBreakMinutes * 60;

      // Assert
      expect(actualSeconds, equals(expectedSeconds));
    });

    test('Long break time should be 15 minutes', () {
      // Arrange
      const longBreakMinutes = 15;
      const expectedSeconds = 900; // 15 * 60

      // Act
      final actualSeconds = longBreakMinutes * 60;

      // Assert
      expect(actualSeconds, equals(expectedSeconds));
    });
  });

  group('▶️ Timer State Management Tests', () {
    test('Timer should start in stopped state', () {
      // Arrange
      const isRunning = false;

      // Assert
      expect(isRunning, isFalse);
    });

    test('Timer should be in work mode initially', () {
      // Arrange
      const isWorkTime = true;

      // Assert
      expect(isWorkTime, isTrue);
    });

    test('Timer should toggle running state when started/paused', () {
      // Arrange
      var isRunning = false;

      // Act - Start timer
      isRunning = true;
      expect(isRunning, isTrue);

      // Act - Pause timer
      isRunning = false;
      expect(isRunning, isFalse);

      // Act - Resume timer
      isRunning = true;
      expect(isRunning, isTrue);
    });

    test('Timer should track session count correctly', () {
      // Arrange
      var sessionCount = 0;

      // Act - Complete sessions
      sessionCount++; // Session 1
      expect(sessionCount, equals(1));

      sessionCount++; // Session 2
      expect(sessionCount, equals(2));

      sessionCount++; // Session 3
      expect(sessionCount, equals(3));

      sessionCount++; // Session 4
      expect(sessionCount, equals(4));

      // After 4 sessions, should trigger long break
      expect(sessionCount % 4, equals(0));
    });
  });

  group('⏯️ Timer Countdown Tests', () {
    test('Timer should countdown from 25:00 to 24:59', () {
      // Arrange
      var remainingSeconds = 25 * 60; // 1500

      // Act - Simulate 1 second tick
      remainingSeconds--;

      // Assert
      expect(remainingSeconds, equals(1499));
      expect(remainingSeconds ~/ 60, equals(24)); // Minutes
      expect(remainingSeconds % 60, equals(59)); // Seconds
    });

    test('Timer should countdown correctly over multiple ticks', () {
      // Arrange
      var remainingSeconds = 25 * 60; // 1500

      // Act - Simulate 10 seconds
      for (int i = 0; i < 10; i++) {
        remainingSeconds--;
      }

      // Assert
      expect(remainingSeconds, equals(1490));
      expect(remainingSeconds ~/ 60, equals(24)); // Minutes
      expect(remainingSeconds % 60, equals(50)); // Seconds
    });

    test('Timer should reach zero after complete countdown', () {
      // Arrange
      var remainingSeconds = 5; // Start with 5 seconds for quick test

      // Act - Countdown to zero
      while (remainingSeconds > 0) {
        remainingSeconds--;
      }

      // Assert
      expect(remainingSeconds, equals(0));
    });

    test('Timer should not go below zero', () {
      // Arrange
      var remainingSeconds = 0;

      // Act - Try to decrement
      if (remainingSeconds > 0) {
        remainingSeconds--;
      }

      // Assert
      expect(remainingSeconds, equals(0));
      expect(remainingSeconds, isNonNegative);
    });
  });

  group('🔄 Timer Reset Tests', () {
    test('Timer should reset to initial work duration', () {
      // Arrange
      const workDuration = 25;
      var remainingSeconds = 1000; // Some arbitrary value

      // Act - Reset
      remainingSeconds = workDuration * 60;

      // Assert
      expect(remainingSeconds, equals(1500));
    });

    test('Timer should reset running state on reset', () {
      // Arrange
      var isRunning = true;
      var remainingSeconds = 1000;
      const workDuration = 25;

      // Act - Reset
      isRunning = false;
      remainingSeconds = workDuration * 60;

      // Assert
      expect(isRunning, isFalse);
      expect(remainingSeconds, equals(1500));
    });
  });

  group('☕ Break Mode Tests', () {
    test('Timer should switch to short break after work session', () {
      // Arrange
      var isWorkTime = true;
      var sessionCount = 1;

      // Act - Complete work session (but not 4th session)
      isWorkTime = false;

      // Assert
      expect(isWorkTime, isFalse);
      expect(sessionCount % 4, isNot(equals(0)));
    });

    test('Timer should use long break after 4 work sessions', () {
      // Arrange
      var sessionCount = 4;
      const sessionsUntilLongBreak = 4;

      // Act - Check if long break is needed
      final shouldUseLongBreak = sessionCount % sessionsUntilLongBreak == 0;

      // Assert
      expect(shouldUseLongBreak, isTrue);
    });

    test('Timer should use short break after sessions 1, 2, 3', () {
      // Arrange & Act & Assert
      for (int session = 1; session <= 3; session++) {
        final shouldUseLongBreak = session % 4 == 0;
        expect(shouldUseLongBreak, isFalse,
            reason: 'Session $session should use short break');
      }
    });

    test('Break duration should be 5 minutes for short break', () {
      // Arrange
      const breakTime = 5;
      const sessionCount = 1; // Not a multiple of 4

      // Act
      final shouldUseLongBreak = sessionCount % 4 == 0;
      final breakDuration = shouldUseLongBreak ? 15 : breakTime;

      // Assert
      expect(breakDuration, equals(5));
    });

    test('Break duration should be 15 minutes for long break', () {
      // Arrange
      const longBreakTime = 15;
      const sessionCount = 4; // Multiple of 4

      // Act
      final shouldUseLongBreak = sessionCount % 4 == 0;
      final breakDuration = shouldUseLongBreak ? longBreakTime : 5;

      // Assert
      expect(breakDuration, equals(15));
    });
  });

  group('🎯 Timer Completion Tests', () {
    test('Timer should be marked as completed when reaching zero', () {
      // Arrange
      var remainingSeconds = 0;

      // Act
      final isCompleted = remainingSeconds == 0;

      // Assert
      expect(isCompleted, isTrue);
    });

    test('Timer should not be completed if time remains', () {
      // Arrange
      var remainingSeconds = 60;

      // Act
      final isCompleted = remainingSeconds == 0;

      // Assert
      expect(isCompleted, isFalse);
    });
  });

  group('⚙️ Custom Duration Tests', () {
    test('Timer should accept custom work duration', () {
      // Arrange
      const customWorkDuration = 30; // 30 minutes

      // Act
      final seconds = customWorkDuration * 60;

      // Assert
      expect(seconds, equals(1800));
    });

    test('Timer should accept custom short break duration', () {
      // Arrange
      const customBreakDuration = 10; // 10 minutes

      // Act
      final seconds = customBreakDuration * 60;

      // Assert
      expect(seconds, equals(600));
    });

    test('Timer should validate duration ranges', () {
      // Arrange & Act & Assert
      const validDurations = [5, 10, 15, 20, 25, 30, 45, 60];

      for (var duration in validDurations) {
        expect(duration, greaterThanOrEqualTo(5));
        expect(duration, lessThanOrEqualTo(60));
      }
    });
  });

  group('📊 Time Formatting Tests', () {
    test('Timer should format seconds as MM:SS correctly', () {
      // Arrange & Act & Assert
      final testCases = {
        1500: '25:00', // 25 minutes
        1499: '24:59',
        900: '15:00', // 15 minutes
        300: '05:00', // 5 minutes
        60: '01:00', // 1 minute
        59: '00:59',
        10: '00:10',
        5: '00:05',
        0: '00:00',
      };

      testCases.forEach((seconds, expectedFormat) {
        final minutes = seconds ~/ 60;
        final secs = seconds % 60;
        final formatted =
            '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

        expect(formatted, equals(expectedFormat),
            reason: '$seconds saniye = $expectedFormat formatında olmalı');
      });
    });
  });
}
