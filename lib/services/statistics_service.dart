import 'database_helper.dart';
import '../models/pomodoro_session.dart';

class StatisticsService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Toplam çalışma süresi (dakika cinsinden)
  // Tarih aralığı belirtilmezse tüm zamanlar hesaplanır
  Future<int> getTotalStudyTime({DateTime? start, DateTime? end}) async {
    try {
      List<PomodoroSession> sessions;

      if (start != null && end != null) {
        sessions = await _dbHelper.getSessionsByDateRange(start, end);
      } else {
        sessions = await _dbHelper.getAllSessions();
      }

      // Sadece tamamlanan seansları hesapla
      final completedSessions = sessions.where((s) => s.completed).toList();

      int totalMinutes = 0;
      for (var session in completedSessions) {
        totalMinutes += session.duration;
      }

      return totalMinutes;
    } catch (e) {
      print('Toplam çalışma süresi hesaplama hatası: $e');
      return 0;
    }
  }

  // Tamamlanan pomodoro sayısı
  Future<int> getTotalCompletedPomodoros(
      {DateTime? start, DateTime? end}) async {
    try {
      List<PomodoroSession> sessions;

      if (start != null && end != null) {
        sessions = await _dbHelper.getSessionsByDateRange(start, end);
      } else {
        sessions = await _dbHelper.getAllSessions();
      }

      return sessions.where((s) => s.completed).length;
    } catch (e) {
      print('Tamamlanan pomodoro sayısı hesaplama hatası: $e');
      return 0;
    }
  }

  // Son 7 günün günlük ortalama çalışma süresi (dakika)
  Future<double> getAverageDailyStudyTime() async {
    try {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));

      final totalMinutes = await getTotalStudyTime(
        start: sevenDaysAgo,
        end: now,
      );

      return totalMinutes / 7.0;
    } catch (e) {
      print('Ortalama günlük çalışma süresi hesaplama hatası: $e');
      return 0.0;
    }
  }

  // Kategori bazında çalışma dağılımı
  // Return: Map<String, int> (kategori adı: toplam dakika)
  Future<Map<String, int>> getCategoryDistribution({
    DateTime? start,
    DateTime? end,
  }) async {
    try {
      List<PomodoroSession> sessions;

      if (start != null && end != null) {
        sessions = await _dbHelper.getSessionsByDateRange(start, end);
      } else {
        sessions = await _dbHelper.getAllSessions();
      }

      // Sadece tamamlanan seansları hesapla
      final completedSessions = sessions.where((s) => s.completed).toList();

      Map<String, int> distribution = {};

      for (var session in completedSessions) {
        if (distribution.containsKey(session.categoryName)) {
          distribution[session.categoryName] =
              distribution[session.categoryName]! + session.duration;
        } else {
          distribution[session.categoryName] = session.duration;
        }
      }

      // Sürelerine göre sırala (en çok çalışılandan az olana)
      final sortedEntries = distribution.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return Map.fromEntries(sortedEntries);
    } catch (e) {
      print('Kategori dağılımı hesaplama hatası: $e');
      return {};
    }
  }

  // Verimlilik skoru: (Tamamlanan / Toplam) * 100
  // 0-100 arası değer döner
  Future<double> getProductivityScore({DateTime? start, DateTime? end}) async {
    try {
      List<PomodoroSession> sessions;

      if (start != null && end != null) {
        sessions = await _dbHelper.getSessionsByDateRange(start, end);
      } else {
        sessions = await _dbHelper.getAllSessions();
      }

      if (sessions.isEmpty) return 0.0;

      final completedCount = sessions.where((s) => s.completed).length;
      final totalCount = sessions.length;

      return (completedCount / totalCount) * 100.0;
    } catch (e) {
      print('Verimlilik skoru hesaplama hatası: $e');
      return 0.0;
    }
  }

  // Ardışık kaç gün çalışıldı (streak)
  Future<int> getStudyStreak() async {
    try {
      final allSessions = await _dbHelper.getAllSessions();

      if (allSessions.isEmpty) return 0;

      // Sadece tamamlanan seansları al
      final completedSessions = allSessions.where((s) => s.completed).toList();

      if (completedSessions.isEmpty) return 0;

      // Günlere göre grupla (sadece tarih kısmı)
      Set<String> studyDates = {};
      for (var session in completedSessions) {
        final dateKey = _getDateKey(session.startTime);
        studyDates.add(dateKey);
      }

      // Tarihleri sırala
      final sortedDates = studyDates.toList()
        ..sort((a, b) => b.compareTo(a)); // Yeniden eskiye

      if (sortedDates.isEmpty) return 0;

      int streak = 0;
      DateTime currentDate = DateTime.now();

      // Bugünden geriye doğru ardışık günleri say
      for (int i = 0; i < sortedDates.length; i++) {
        final expectedDateKey = _getDateKey(
          currentDate.subtract(Duration(days: streak)),
        );

        if (sortedDates.contains(expectedDateKey)) {
          streak++;
        } else if (streak > 0) {
          // Ardışıklık bozuldu
          break;
        }
      }

      return streak;
    } catch (e) {
      print('Çalışma serisi hesaplama hatası: $e');
      return 0;
    }
  }

  // En verimli saat dilimi (en çok pomodoro tamamlanan saat)
  // Return: 0-23 arası saat
  Future<int> getMostProductiveHour() async {
    try {
      final allSessions = await _dbHelper.getAllSessions();
      final completedSessions = allSessions.where((s) => s.completed).toList();

      if (completedSessions.isEmpty) return 9; // Varsayılan: sabah 9

      // Saat bazında sayım yap
      Map<int, int> hourCounts = {};

      for (var session in completedSessions) {
        final hour = session.hourOfDay;
        hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
      }

      // En çok pomodoro yapılan saati bul
      int mostProductiveHour = 9;
      int maxCount = 0;

      hourCounts.forEach((hour, count) {
        if (count > maxCount) {
          maxCount = count;
          mostProductiveHour = hour;
        }
      });

      return mostProductiveHour;
    } catch (e) {
      print('En verimli saat hesaplama hatası: $e');
      return 9; // Varsayılan değer
    }
  }

  // Bu hafta vs geçen hafta karşılaştırması
  // Return: Yüzdelik değişim (pozitif = artış, negatif = azalış)
  Future<double> getTrendPercentage() async {
    try {
      final now = DateTime.now();

      // Bu hafta (son 7 gün)
      final thisWeekStart = now.subtract(const Duration(days: 7));
      final thisWeekMinutes = await getTotalStudyTime(
        start: thisWeekStart,
        end: now,
      );

      // Geçen hafta (7-14 gün önce)
      final lastWeekStart = now.subtract(const Duration(days: 14));
      final lastWeekEnd = now.subtract(const Duration(days: 7));
      final lastWeekMinutes = await getTotalStudyTime(
        start: lastWeekStart,
        end: lastWeekEnd,
      );

      if (lastWeekMinutes == 0) {
        // Geçen hafta veri yoksa
        return thisWeekMinutes > 0 ? 100.0 : 0.0;
      }

      // Yüzdelik değişimi hesapla
      final change =
          ((thisWeekMinutes - lastWeekMinutes) / lastWeekMinutes) * 100;

      return change;
    } catch (e) {
      print('Trend yüzdesi hesaplama hatası: $e');
      return 0.0;
    }
  }

  // Son X günün günlük çalışma süreleri
  // Return: List<MapEntry<DateTime, int>> (tarih: toplam dakika)
  Future<List<MapEntry<DateTime, int>>> getDailyStudyTimes(int days) async {
    try {
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: days));

      final sessions = await _dbHelper.getSessionsByDateRange(startDate, now);
      final completedSessions = sessions.where((s) => s.completed).toList();

      // Günlere göre grupla
      Map<String, int> dailyMinutes = {};

      for (var session in completedSessions) {
        final dateKey = _getDateKey(session.startTime);
        dailyMinutes[dateKey] = (dailyMinutes[dateKey] ?? 0) + session.duration;
      }

      // Son X günü oluştur (veri olmayan günler için 0 değeri)
      List<MapEntry<DateTime, int>> result = [];

      for (int i = days - 1; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dateKey = _getDateKey(date);
        final minutes = dailyMinutes[dateKey] ?? 0;

        result.add(MapEntry(
          DateTime(date.year, date.month, date.day),
          minutes,
        ));
      }

      return result;
    } catch (e) {
      print('Günlük çalışma süreleri hesaplama hatası: $e');
      return [];
    }
  }

  // Kategoriye göre toplam pomodoro sayısı
  Future<Map<String, int>> getCategoryPomodoroCount({
    DateTime? start,
    DateTime? end,
  }) async {
    try {
      List<PomodoroSession> sessions;

      if (start != null && end != null) {
        sessions = await _dbHelper.getSessionsByDateRange(start, end);
      } else {
        sessions = await _dbHelper.getAllSessions();
      }

      final completedSessions = sessions.where((s) => s.completed).toList();

      Map<String, int> counts = {};

      for (var session in completedSessions) {
        counts[session.categoryName] = (counts[session.categoryName] ?? 0) + 1;
      }

      // Sayıya göre sırala
      final sortedEntries = counts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return Map.fromEntries(sortedEntries);
    } catch (e) {
      print('Kategori pomodoro sayısı hesaplama hatası: $e');
      return {};
    }
  }

  // Pomodoro türlerine göre dağılım
  Future<Map<String, int>> getPomodoroTypeDistribution() async {
    try {
      final allSessions = await _dbHelper.getAllSessions();
      final completedSessions = allSessions.where((s) => s.completed).toList();

      Map<String, int> distribution = {};

      for (var session in completedSessions) {
        distribution[session.pomodoroType] =
            (distribution[session.pomodoroType] ?? 0) + 1;
      }

      return distribution;
    } catch (e) {
      print('Pomodoro tipi dağılımı hesaplama hatası: $e');
      return {};
    }
  }

  // Saatlik verimlilik dağılımı (0-23 arası her saat için toplam dakika)
  Future<Map<int, int>> getHourlyProductivity() async {
    try {
      final allSessions = await _dbHelper.getAllSessions();
      final completedSessions = allSessions.where((s) => s.completed).toList();

      Map<int, int> hourlyMinutes = {};

      for (var session in completedSessions) {
        final hour = session.hourOfDay;
        hourlyMinutes[hour] = (hourlyMinutes[hour] ?? 0) + session.duration;
      }

      return hourlyMinutes;
    } catch (e) {
      print('Saatlik verimlilik hesaplama hatası: $e');
      return {};
    }
  }

  // === HELPER METODLAR ===

  // Tarihten string key oluştur (yyyy-MM-dd formatında)
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
