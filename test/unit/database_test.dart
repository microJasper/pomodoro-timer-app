import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_timer_app/models/pomodoro_session.dart';

/// 🎯 Database Logic Unit Tests
///
/// Bu test dosyası, veritabanı işlemlerinin mantığını test eder:
/// - Veri modeli dönüşümleri (toMap, fromMap)
/// - Tarih aralığı hesaplamaları
/// - Liste filtreleme mantığı
/// - İstatistik hesaplama senaryoları
///
/// NOT: Bu testler veritabanı mantığını simüle eder.
/// Gerçek database entegrasyon testleri ayrı yazılmalıdır.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('📦 Session Map Conversion Tests', () {
    test('PomodoroSession should convert to Map correctly', () {
      // Arrange
      final now = DateTime.now();
      final session = PomodoroSession(
        id: 'test-123',
        categoryName: 'Matematik',
        startTime: now,
        endTime: now.add(Duration(minutes: 25)),
        duration: 25,
        pomodoroType: 'work',
        completed: true,
        interrupted: false,
      );

      // Act
      final map = session.toMap();

      // Assert
      expect(map['id'], equals('test-123'));
      expect(map['categoryName'], equals('Matematik'));
      expect(map['duration'], equals(25));
      expect(map['pomodoroType'], equals('work'));
      expect(map['completed'], equals(1)); // true = 1
      expect(map['interrupted'], equals(0)); // false = 0
    });

    test('PomodoroSession should be created from Map correctly', () {
      // Arrange
      final now = DateTime.now();
      final map = {
        'id': 'test-456',
        'categoryName': 'Fizik',
        'startTime': now.toIso8601String(),
        'endTime': now.add(Duration(minutes: 25)).toIso8601String(),
        'duration': 25,
        'pomodoroType': 'work',
        'completed': 1,
        'interrupted': 0,
      };

      // Act
      final session = PomodoroSession.fromMap(map);

      // Assert
      expect(session.id, equals('test-456'));
      expect(session.categoryName, equals('Fizik'));
      expect(session.duration, equals(25));
      expect(session.completed, isTrue);
      expect(session.interrupted, isFalse);
    });

    test('Session Map conversion should be reversible', () {
      // Arrange
      final now = DateTime.now();
      final originalSession = PomodoroSession(
        id: 'reverse-test',
        categoryName: 'Test',
        startTime: now,
        endTime: now.add(const Duration(minutes: 25)),
        duration: 25,
        pomodoroType: 'work',
        completed: true,
        interrupted: false,
      );

      // Act
      final map = originalSession.toMap();
      final reconstructedSession = PomodoroSession.fromMap(map);

      // Assert
      expect(reconstructedSession.id, equals(originalSession.id));
      expect(reconstructedSession.categoryName,
          equals(originalSession.categoryName));
      expect(reconstructedSession.duration, equals(originalSession.duration));
      expect(reconstructedSession.completed, equals(originalSession.completed));
    });
  });

  group('📅 Date Range Query Logic Tests', () {
    test('Should filter sessions within date range', () {
      // Arrange
      final today = DateTime.now();
      final yesterday = today.subtract(Duration(days: 1));
      final twoDaysAgo = today.subtract(Duration(days: 2));

      final sessions = [
        PomodoroSession(
          categoryName: 'Today',
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
        PomodoroSession(
          categoryName: 'Old',
          startTime: twoDaysAgo,
          endTime: twoDaysAgo.add(Duration(minutes: 25)),
          duration: 25,
          pomodoroType: 'work',
          completed: true,
        ),
      ];

      // Act - Filter last 24 hours
      final filtered = sessions.where((s) {
        return s.startTime.isAfter(yesterday.subtract(Duration(hours: 1)));
      }).toList();

      // Assert
      expect(filtered, hasLength(2));
      expect(filtered.any((s) => s.categoryName == 'Today'), isTrue);
      expect(filtered.any((s) => s.categoryName == 'Yesterday'), isTrue);
      expect(filtered.any((s) => s.categoryName == 'Old'), isFalse);
    });

    test('Should calculate date range correctly', () {
      // Arrange
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(Duration(days: 7));

      // Act
      final difference = now.difference(sevenDaysAgo);

      // Assert
      expect(difference.inDays, equals(7));
    });
  });

  group('🔍 Category Filtering Tests', () {
    test('Should filter sessions by category', () {
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
      ];

      // Act
      final mathSessions =
          sessions.where((s) => s.categoryName == 'Matematik').toList();

      // Assert
      expect(mathSessions, hasLength(2));
      expect(mathSessions.every((s) => s.categoryName == 'Matematik'), isTrue);
    });

    test('Should handle empty category filter result', () {
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
      ];

      // Act
      final filtered =
          sessions.where((s) => s.categoryName == 'NonExistent').toList();

      // Assert
      expect(filtered, isEmpty);
    });
  });

  group('📊 Statistics Calculation Tests', () {
    test('Should count completed sessions correctly', () {
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
          completed: false,
          interrupted: true,
        ),
      ];

      // Act
      final completedCount = sessions.where((s) => s.completed).length;

      // Assert
      expect(completedCount, equals(2));
    });

    test('Should calculate total focus time correctly', () {
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
          endTime: now.add(Duration(minutes: 15)),
          duration: 15,
          pomodoroType: 'work',
          completed: false,
        ),
      ];

      // Act
      final totalMinutes = sessions
          .where((s) => s.completed)
          .fold<int>(0, (sum, s) => sum + s.duration);

      // Assert
      expect(totalMinutes, equals(50)); // 25 + 25 = 50
    });

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
    });
  });

  group('⏰ Time Extraction Tests', () {
    test('Should extract hour of day correctly from session', () {
      // Arrange
      final morning = DateTime(2025, 12, 10, 9, 30); // 09:30
      final afternoon = DateTime(2025, 12, 10, 14, 45); // 14:45
      final evening = DateTime(2025, 12, 10, 20, 15); // 20:15

      final sessions = [
        PomodoroSession(
          categoryName: 'Morning',
          startTime: morning,
          endTime: morning.add(Duration(minutes: 25)),
          duration: 25,
          pomodoroType: 'work',
          completed: true,
        ),
        PomodoroSession(
          categoryName: 'Afternoon',
          startTime: afternoon,
          endTime: afternoon.add(Duration(minutes: 25)),
          duration: 25,
          pomodoroType: 'work',
          completed: true,
        ),
        PomodoroSession(
          categoryName: 'Evening',
          startTime: evening,
          endTime: evening.add(Duration(minutes: 25)),
          duration: 25,
          pomodoroType: 'work',
          completed: true,
        ),
      ];

      // Act
      final hours = sessions.map((s) => s.startTime.hour).toList();

      // Assert
      expect(hours, contains(9));
      expect(hours, contains(14));
      expect(hours, contains(20));
    });

    test('Should extract day of week correctly from session', () {
      // Arrange
      final monday = DateTime(2025, 12, 8); // Monday
      final friday = DateTime(2025, 12, 12); // Friday

      final session1 = PomodoroSession(
        categoryName: 'Monday Work',
        startTime: monday,
        endTime: monday.add(Duration(minutes: 25)),
        duration: 25,
        pomodoroType: 'work',
        completed: true,
      );

      final session2 = PomodoroSession(
        categoryName: 'Friday Work',
        startTime: friday,
        endTime: friday.add(Duration(minutes: 25)),
        duration: 25,
        pomodoroType: 'work',
        completed: true,
      );

      // Act & Assert
      expect(session1.dayOfWeek, equals(DateTime.monday)); // 1
      expect(session2.dayOfWeek, equals(DateTime.friday)); // 5
    });
  });

  group('🔢 List Operations Tests', () {
    test('Should sort sessions by start time descending', () {
      // Arrange
      final oldest = DateTime.now().subtract(Duration(days: 2));
      final middle = DateTime.now().subtract(Duration(days: 1));
      final newest = DateTime.now();

      var sessions = [
        PomodoroSession(
          categoryName: 'Middle',
          startTime: middle,
          endTime: middle.add(Duration(minutes: 25)),
          duration: 25,
          pomodoroType: 'work',
          completed: true,
        ),
        PomodoroSession(
          categoryName: 'Newest',
          startTime: newest,
          endTime: newest.add(Duration(minutes: 25)),
          duration: 25,
          pomodoroType: 'work',
          completed: true,
        ),
        PomodoroSession(
          categoryName: 'Oldest',
          startTime: oldest,
          endTime: oldest.add(Duration(minutes: 25)),
          duration: 25,
          pomodoroType: 'work',
          completed: true,
        ),
      ];

      // Act
      sessions.sort((a, b) => b.startTime.compareTo(a.startTime));

      // Assert
      expect(sessions.first.categoryName, equals('Newest'));
      expect(sessions.last.categoryName, equals('Oldest'));
    });

    test('Should handle empty sessions list', () {
      // Arrange
      final List<PomodoroSession> sessions = [];

      // Act
      final completedCount = sessions.where((s) => s.completed).length;
      final totalTime = sessions.fold<int>(0, (sum, s) => sum + s.duration);

      // Assert
      expect(completedCount, equals(0));
      expect(totalTime, equals(0));
      expect(sessions, isEmpty);
    });
  });

  group('✅ Session Completion Status Tests', () {
    test('Should distinguish between completed and interrupted sessions', () {
      // Arrange
      final now = DateTime.now();

      final completedSession = PomodoroSession(
        categoryName: 'Completed',
        startTime: now,
        endTime: now.add(Duration(minutes: 25)),
        duration: 25,
        pomodoroType: 'work',
        completed: true,
        interrupted: false,
      );

      final interruptedSession = PomodoroSession(
        categoryName: 'Interrupted',
        startTime: now,
        endTime: now.add(Duration(minutes: 10)),
        duration: 10,
        pomodoroType: 'work',
        completed: false,
        interrupted: true,
      );

      // Assert
      expect(completedSession.completed, isTrue);
      expect(completedSession.interrupted, isFalse);
      expect(interruptedSession.completed, isFalse);
      expect(interruptedSession.interrupted, isTrue);
    });

    test('Should filter only completed sessions', () {
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
          categoryName: 'Incomplete',
          startTime: now,
          endTime: now.add(Duration(minutes: 10)),
          duration: 10,
          pomodoroType: 'work',
          completed: false,
        ),
        PomodoroSession(
          categoryName: 'Complete2',
          startTime: now,
          endTime: now.add(Duration(minutes: 25)),
          duration: 25,
          pomodoroType: 'work',
          completed: true,
        ),
      ];

      // Act
      final completedOnly = sessions.where((s) => s.completed).toList();

      // Assert
      expect(completedOnly, hasLength(2));
      expect(completedOnly.every((s) => s.completed), isTrue);
    });
  });

  group('🏷️ Pomodoro Type Tests', () {
    test('Should distinguish between work and break sessions', () {
      // Arrange
      final now = DateTime.now();

      final workSession = PomodoroSession(
        categoryName: 'Work',
        startTime: now,
        endTime: now.add(Duration(minutes: 25)),
        duration: 25,
        pomodoroType: 'work',
        completed: true,
      );

      final breakSession = PomodoroSession(
        categoryName: 'Break',
        startTime: now,
        endTime: now.add(Duration(minutes: 5)),
        duration: 5,
        pomodoroType: 'break',
        completed: true,
      );

      // Assert
      expect(workSession.pomodoroType, equals('work'));
      expect(breakSession.pomodoroType, equals('break'));
      expect(workSession.duration, equals(25));
      expect(breakSession.duration, equals(5));
    });

    test('Should filter work sessions only', () {
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
          categoryName: 'Break',
          startTime: now,
          endTime: now.add(Duration(minutes: 5)),
          duration: 5,
          pomodoroType: 'break',
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
      ];

      // Act
      final workOnly = sessions.where((s) => s.pomodoroType == 'work').toList();

      // Assert
      expect(workOnly, hasLength(2));
      expect(workOnly.every((s) => s.pomodoroType == 'work'), isTrue);
    });
  });
}
