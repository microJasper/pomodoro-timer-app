import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_timer_app/models/pomodoro_session.dart';

/// 🎯 Statistics Service Unit Tests
///
/// Bu test dosyası, istatistik hesaplamalarının mantığını test eder:
/// - Toplam çalışma süresi hesaplamaları
/// - Kategori bazında dağılım
/// - En verimli saat bulma
/// - Günlük/haftalık istatistikler
/// - Verimlilik skorları
///
/// NOT: Bu testler statistics service mantığını simüle eder.
/// Gerçek service entegrasyon testleri ayrı yazılmalıdır.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('⏱️ Total Study Time Calculation Tests', () {
    test('Should calculate total study time for completed sessions', () {
      // Arrange
      final now = DateTime.now();
      final sessions = [
        PomodoroSession(
          categoryName: 'Matematik',
          startTime: now,
          endTime: now.add(Duration(minutes: 25)),
          duration: 25,
          pomodoroType: 'work',
          completed: true,
        ),
        PomodoroSession(
          categoryName: 'Fizik',
          startTime: now,
          endTime: now.add(Duration(minutes: 25)),
          duration: 25,
          pomodoroType: 'work',
          completed: true,
        ),
        PomodoroSession(
          categoryName: 'Kimya',
          startTime: now,
          endTime: now.add(Duration(minutes: 15)),
          duration: 15,
          pomodoroType: 'work',
          completed: false, // Not completed
        ),
      ];

      // Act
      final totalMinutes = sessions
          .where((s) => s.completed)
          .fold<int>(0, (sum, s) => sum + s.duration);

      // Assert
      expect(totalMinutes, equals(50)); // 25 + 25 = 50
    });

    test('Should return zero for empty sessions list', () {
      // Arrange
      final List<PomodoroSession> sessions = [];

      // Act
      final totalMinutes = sessions.fold<int>(0, (sum, s) => sum + s.duration);

      // Assert
      expect(totalMinutes, equals(0));
    });

    test('Should calculate daily average correctly', () {
      // Arrange
      const totalMinutes = 175; // 7 gün toplamı
      const dayCount = 7;

      // Act
      final average = totalMinutes / dayCount;

      // Assert
      expect(average, equals(25.0)); // 25 dakika ortalama
    });
  });

  group('📊 Category Distribution Tests', () {
    test('Should calculate category distribution correctly', () {
      // Arrange
      final now = DateTime.now();
      final sessions = [
        PomodoroSession(
          categoryName: 'Matematik',
          startTime: now,
          endTime: now.add(Duration(minutes: 25)),
          duration: 25,
          pomodoroType: 'work',
          completed: true,
        ),
        PomodoroSession(
          categoryName: 'Matematik',
          startTime: now,
          endTime: now.add(Duration(minutes: 25)),
          duration: 25,
          pomodoroType: 'work',
          completed: true,
        ),
        PomodoroSession(
          categoryName: 'Fizik',
          startTime: now,
          endTime: now.add(Duration(minutes: 25)),
          duration: 25,
          pomodoroType: 'work',
          completed: true,
        ),
        PomodoroSession(
          categoryName: 'Kimya',
          startTime: now,
          endTime: now.add(Duration(minutes: 15)),
          duration: 15,
          pomodoroType: 'work',
          completed: true,
        ),
      ];

      // Act
      final distribution = <String, int>{};
      for (var session in sessions.where((s) => s.completed)) {
        distribution[session.categoryName] =
            (distribution[session.categoryName] ?? 0) + session.duration;
      }

      // Assert
      expect(distribution['Matematik'], equals(50)); // 25 + 25
      expect(distribution['Fizik'], equals(25));
      expect(distribution['Kimya'], equals(15));
    });

    test('Should sort category distribution by duration descending', () {
      // Arrange
      final distribution = {
        'Fizik': 25,
        'Matematik': 75,
        'Kimya': 50,
      };

      // Act
      final sortedEntries = distribution.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final sortedMap = Map.fromEntries(sortedEntries);

      // Assert
      final keys = sortedMap.keys.toList();
      expect(keys[0], equals('Matematik')); // En yüksek
      expect(keys[1], equals('Kimya'));
      expect(keys[2], equals('Fizik')); // En düşük
    });

    test('Should count sessions per category', () {
      // Arrange
      final now = DateTime.now();
      final sessions = [
        PomodoroSession(
          categoryName: 'Matematik',
          startTime: now,
          endTime: now.add(Duration(minutes: 25)),
          duration: 25,
          pomodoroType: 'work',
          completed: true,
        ),
        PomodoroSession(
          categoryName: 'Matematik',
          startTime: now,
          endTime: now.add(Duration(minutes: 25)),
          duration: 25,
          pomodoroType: 'work',
          completed: true,
        ),
        PomodoroSession(
          categoryName: 'Matematik',
          startTime: now,
          endTime: now.add(Duration(minutes: 25)),
          duration: 25,
          pomodoroType: 'work',
          completed: true,
        ),
      ];

      // Act
      final counts = <String, int>{};
      for (var session in sessions.where((s) => s.completed)) {
        counts[session.categoryName] = (counts[session.categoryName] ?? 0) + 1;
      }

      // Assert
      expect(counts['Matematik'], equals(3));
    });
  });

  group('🕐 Most Productive Hour Tests', () {
    test('Should find most productive hour correctly', () {
      // Arrange
      final sessions = [
        PomodoroSession(
          categoryName: 'Test',
          startTime: DateTime(2025, 12, 10, 9, 0), // 09:00
          endTime: DateTime(2025, 12, 10, 9, 25),
          duration: 25,
          pomodoroType: 'work',
          completed: true,
        ),
        PomodoroSession(
          categoryName: 'Test',
          startTime: DateTime(2025, 12, 10, 9, 30), // 09:30
          endTime: DateTime(2025, 12, 10, 9, 55),
          duration: 25,
          pomodoroType: 'work',
          completed: true,
        ),
        PomodoroSession(
          categoryName: 'Test',
          startTime: DateTime(2025, 12, 10, 14, 0), // 14:00
          endTime: DateTime(2025, 12, 10, 14, 25),
          duration: 25,
          pomodoroType: 'work',
          completed: true,
        ),
      ];

      // Act
      final hourCounts = <int, int>{};
      for (var session in sessions.where((s) => s.completed)) {
        final hour = session.hourOfDay;
        hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
      }

      int mostProductiveHour = 0;
      int maxCount = 0;
      hourCounts.forEach((hour, count) {
        if (count > maxCount) {
          maxCount = count;
          mostProductiveHour = hour;
        }
      });

      // Assert
      expect(mostProductiveHour, equals(9)); // 9:00 has 2 sessions
      expect(maxCount, equals(2));
    });

    test('Should handle sessions across different hours', () {
      // Arrange
      final sessions = [
        PomodoroSession(
          categoryName: 'Morning',
          startTime: DateTime(2025, 12, 10, 6, 0),
          endTime: DateTime(2025, 12, 10, 6, 25),
          duration: 25,
          pomodoroType: 'work',
          completed: true,
        ),
        PomodoroSession(
          categoryName: 'Afternoon',
          startTime: DateTime(2025, 12, 10, 15, 0),
          endTime: DateTime(2025, 12, 10, 15, 25),
          duration: 25,
          pomodoroType: 'work',
          completed: true,
        ),
        PomodoroSession(
          categoryName: 'Evening',
          startTime: DateTime(2025, 12, 10, 21, 0),
          endTime: DateTime(2025, 12, 10, 21, 25),
          duration: 25,
          pomodoroType: 'work',
          completed: true,
        ),
      ];

      // Act
      final hours = sessions.map((s) => s.hourOfDay).toSet();

      // Assert
      expect(hours, hasLength(3));
      expect(hours, contains(6));
      expect(hours, contains(15));
      expect(hours, contains(21));
    });
  });

  group('📈 Productivity Score Tests', () {
    test('Should calculate productivity score correctly', () {
      // Arrange
      final now = DateTime.now();
      final sessions = [
        PomodoroSession(
          categoryName: 'Test',
          startTime: now,
          endTime: now.add(Duration(minutes: 25)),
          duration: 25,
          pomodoroType: 'work',
          completed: true,
        ),
        PomodoroSession(
          categoryName: 'Test',
          startTime: now,
          endTime: now.add(Duration(minutes: 25)),
          duration: 25,
          pomodoroType: 'work',
          completed: true,
        ),
        PomodoroSession(
          categoryName: 'Test',
          startTime: now,
          endTime: now.add(Duration(minutes: 25)),
          duration: 25,
          pomodoroType: 'work',
          completed: true,
        ),
        PomodoroSession(
          categoryName: 'Test',
          startTime: now,
          endTime: now.add(Duration(minutes: 15)),
          duration: 15,
          pomodoroType: 'work',
          completed: false,
        ),
      ];

      // Act
      final completedCount = sessions.where((s) => s.completed).length;
      final totalCount = sessions.length;
      final score = (completedCount / totalCount) * 100;

      // Assert
      expect(score, equals(75.0)); // 3/4 = 75%
    });

    test('Should return 100% for all completed sessions', () {
      // Arrange
      final now = DateTime.now();
      final sessions = [
        PomodoroSession(
          categoryName: 'Test',
          startTime: now,
          endTime: now.add(Duration(minutes: 25)),
          duration: 25,
          pomodoroType: 'work',
          completed: true,
        ),
        PomodoroSession(
          categoryName: 'Test',
          startTime: now,
          endTime: now.add(Duration(minutes: 25)),
          duration: 25,
          pomodoroType: 'work',
          completed: true,
        ),
      ];

      // Act
      final completedCount = sessions.where((s) => s.completed).length;
      final totalCount = sessions.length;
      final score = (completedCount / totalCount) * 100;

      // Assert
      expect(score, equals(100.0));
    });

    test('Should return 0% for no completed sessions', () {
      // Arrange
      final now = DateTime.now();
      final sessions = [
        PomodoroSession(
          categoryName: 'Test',
          startTime: now,
          endTime: now.add(Duration(minutes: 15)),
          duration: 15,
          pomodoroType: 'work',
          completed: false,
          interrupted: true,
        ),
      ];

      // Act
      final completedCount = sessions.where((s) => s.completed).length;
      final totalCount = sessions.length;
      final score = totalCount > 0 ? (completedCount / totalCount) * 100 : 0.0;

      // Assert
      expect(score, equals(0.0));
    });
  });

  group('🔥 Study Streak Tests', () {
    test('Should identify consecutive study days', () {
      // Arrange
      final today = DateTime.now();
      final studyDates = {
        _getDateKey(today),
        _getDateKey(today.subtract(Duration(days: 1))),
        _getDateKey(today.subtract(Duration(days: 2))),
      };

      // Act
      int streak = 0;
      for (int i = 0; i < 7; i++) {
        final checkDate = today.subtract(Duration(days: i));
        if (studyDates.contains(_getDateKey(checkDate))) {
          streak++;
        } else {
          break;
        }
      }

      // Assert
      expect(streak, equals(3)); // 3 consecutive days
    });

    test('Should stop counting when streak is broken', () {
      // Arrange
      final today = DateTime.now();
      final studyDates = {
        _getDateKey(today),
        _getDateKey(today.subtract(Duration(days: 1))),
        // Day 2 is missing - streak breaks here
        _getDateKey(today.subtract(Duration(days: 3))),
        _getDateKey(today.subtract(Duration(days: 4))),
      };

      // Act
      int streak = 0;
      for (int i = 0; i < 7; i++) {
        final checkDate = today.subtract(Duration(days: i));
        if (studyDates.contains(_getDateKey(checkDate))) {
          streak++;
        } else if (streak > 0) {
          break; // Stop when streak is broken
        }
      }

      // Assert
      expect(streak, equals(2)); // Only today and yesterday
    });
  });

  group('📅 Daily Study Times Tests', () {
    test('Should group sessions by date correctly', () {
      // Arrange
      final today = DateTime.now();
      final yesterday = today.subtract(Duration(days: 1));

      final sessions = [
        PomodoroSession(
          categoryName: 'Today1',
          startTime: today,
          endTime: today.add(Duration(minutes: 25)),
          duration: 25,
          pomodoroType: 'work',
          completed: true,
        ),
        PomodoroSession(
          categoryName: 'Today2',
          startTime: today,
          endTime: today.add(Duration(minutes: 25)),
          duration: 25,
          pomodoroType: 'work',
          completed: true,
        ),
        PomodoroSession(
          categoryName: 'Yesterday',
          startTime: yesterday,
          endTime: yesterday.add(Duration(minutes: 25)),
          duration: 25,
          pomodoroType: 'work',
          completed: true,
        ),
      ];

      // Act
      final dailyMinutes = <String, int>{};
      for (var session in sessions.where((s) => s.completed)) {
        final dateKey = _getDateKey(session.startTime);
        dailyMinutes[dateKey] = (dailyMinutes[dateKey] ?? 0) + session.duration;
      }

      // Assert
      expect(dailyMinutes[_getDateKey(today)], equals(50)); // 25 + 25
      expect(dailyMinutes[_getDateKey(yesterday)], equals(25));
    });

    test('Should fill missing days with zero', () {
      // Arrange
      const days = 7;
      final now = DateTime.now();
      final dailyMinutes = <String, int>{
        _getDateKey(now): 50,
        _getDateKey(now.subtract(Duration(days: 2))): 25,
      };

      // Act
      final result = <DateTime, int>{};
      for (int i = days - 1; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dateKey = _getDateKey(date);
        final minutes = dailyMinutes[dateKey] ?? 0;
        result[DateTime(date.year, date.month, date.day)] = minutes;
      }

      // Assert
      expect(result, hasLength(7));
      expect(result.values.where((v) => v == 0), hasLength(5)); // 5 days with 0
    });
  });

  group('📊 Trend Percentage Tests', () {
    test('Should calculate positive trend correctly', () {
      // Arrange
      const thisWeekMinutes = 150; // This week
      const lastWeekMinutes = 100; // Last week

      // Act
      final change =
          ((thisWeekMinutes - lastWeekMinutes) / lastWeekMinutes) * 100;

      // Assert
      expect(change, equals(50.0)); // 50% increase
    });

    test('Should calculate negative trend correctly', () {
      // Arrange
      const thisWeekMinutes = 75; // This week
      const lastWeekMinutes = 100; // Last week

      // Act
      final change =
          ((thisWeekMinutes - lastWeekMinutes) / lastWeekMinutes) * 100;

      // Assert
      expect(change, equals(-25.0)); // 25% decrease
    });

    test('Should handle zero last week minutes', () {
      // Arrange
      const thisWeekMinutes = 100;
      const lastWeekMinutes = 0;

      // Act
      final change = lastWeekMinutes == 0
          ? (thisWeekMinutes > 0 ? 100.0 : 0.0)
          : ((thisWeekMinutes - lastWeekMinutes) / lastWeekMinutes) * 100;

      // Assert
      expect(change, equals(100.0)); // New activity
    });
  });

  group('⏰ Hourly Productivity Tests', () {
    test('Should calculate hourly productivity distribution', () {
      // Arrange
      final sessions = [
        PomodoroSession(
          categoryName: 'Morning',
          startTime: DateTime(2025, 12, 10, 9, 0),
          endTime: DateTime(2025, 12, 10, 9, 25),
          duration: 25,
          pomodoroType: 'work',
          completed: true,
        ),
        PomodoroSession(
          categoryName: 'Morning2',
          startTime: DateTime(2025, 12, 10, 9, 30),
          endTime: DateTime(2025, 12, 10, 9, 55),
          duration: 25,
          pomodoroType: 'work',
          completed: true,
        ),
        PomodoroSession(
          categoryName: 'Afternoon',
          startTime: DateTime(2025, 12, 10, 14, 0),
          endTime: DateTime(2025, 12, 10, 14, 25),
          duration: 25,
          pomodoroType: 'work',
          completed: true,
        ),
      ];

      // Act
      final hourlyMinutes = <int, int>{};
      for (var session in sessions.where((s) => s.completed)) {
        final hour = session.hourOfDay;
        hourlyMinutes[hour] = (hourlyMinutes[hour] ?? 0) + session.duration;
      }

      // Assert
      expect(hourlyMinutes[9], equals(50)); // 25 + 25 at 9:00
      expect(hourlyMinutes[14], equals(25)); // 25 at 14:00
    });
  });

  group('🏷️ Pomodoro Type Distribution Tests', () {
    test('Should distinguish between work and break types', () {
      // Arrange
      final now = DateTime.now();
      final sessions = [
        PomodoroSession(
          categoryName: 'Work1',
          startTime: now,
          endTime: now.add(Duration(minutes: 25)),
          duration: 25,
          pomodoroType: 'work',
          completed: true,
        ),
        PomodoroSession(
          categoryName: 'Work2',
          startTime: now,
          endTime: now.add(Duration(minutes: 25)),
          duration: 25,
          pomodoroType: 'work',
          completed: true,
        ),
        PomodoroSession(
          categoryName: 'Break1',
          startTime: now,
          endTime: now.add(Duration(minutes: 5)),
          duration: 5,
          pomodoroType: 'break',
          completed: true,
        ),
      ];

      // Act
      final distribution = <String, int>{};
      for (var session in sessions.where((s) => s.completed)) {
        distribution[session.pomodoroType] =
            (distribution[session.pomodoroType] ?? 0) + 1;
      }

      // Assert
      expect(distribution['work'], equals(2));
      expect(distribution['break'], equals(1));
    });
  });

  group('🔢 Completed Sessions Count Tests', () {
    test('Should count only completed sessions', () {
      // Arrange
      final now = DateTime.now();
      final sessions = [
        PomodoroSession(
          categoryName: 'Complete1',
          startTime: now,
          endTime: now.add(Duration(minutes: 25)),
          duration: 25,
          pomodoroType: 'work',
          completed: true,
        ),
        PomodoroSession(
          categoryName: 'Complete2',
          startTime: now,
          endTime: now.add(Duration(minutes: 25)),
          duration: 25,
          pomodoroType: 'work',
          completed: true,
        ),
        PomodoroSession(
          categoryName: 'Incomplete',
          startTime: now,
          endTime: now.add(Duration(minutes: 10)),
          duration: 10,
          pomodoroType: 'work',
          completed: false,
        ),
      ];

      // Act
      final completedCount = sessions.where((s) => s.completed).length;

      // Assert
      expect(completedCount, equals(2));
    });
  });
}

// Helper function to get date key
String _getDateKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
