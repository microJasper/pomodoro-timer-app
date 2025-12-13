import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/statistics_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final StatisticsService _statsService = StatisticsService();

  bool _isLoading = true;

  // İstatistik verileri
  int _totalStudyTime = 0;
  int _totalPomodoros = 0;
  double _productivityScore = 0.0;
  List<MapEntry<DateTime, int>> _dailyStudyTimes = [];
  Map<String, int> _categoryDistribution = {};
  int _mostProductiveHour = 9;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final totalTime = await _statsService.getTotalStudyTime();
      final totalPomodoros = await _statsService.getTotalCompletedPomodoros();
      final productivityScore = await _statsService.getProductivityScore();
      final dailyTimes = await _statsService.getDailyStudyTimes(7);
      final categoryDist = await _statsService.getCategoryDistribution();
      final mostProductiveHour = await _statsService.getMostProductiveHour();

      setState(() {
        _totalStudyTime = totalTime;
        _totalPomodoros = totalPomodoros;
        _productivityScore = productivityScore;
        _dailyStudyTimes = dailyTimes;
        _categoryDistribution = categoryDist;
        _mostProductiveHour = mostProductiveHour;
        _isLoading = false;
      });
    } catch (e) {
      print('İstatistik yükleme hatası: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'İstatistikler',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.deepPurple,
              ),
            )
          : _totalPomodoros == 0
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadStatistics,
                  color: Colors.deepPurple,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Özet Kartlar
                        _buildSummaryCards(),
                        const SizedBox(height: 24),

                        // Haftalık Line Chart
                        _buildWeeklyLineChart(),
                        const SizedBox(height: 24),

                        // Kategori Pie Chart
                        _buildCategoryPieChart(),
                        const SizedBox(height: 24),

                        // Saatlik Bar Chart
                        _buildHourlyBarChart(),
                        const SizedBox(height: 24),

                        // En Verimli Saat Kartı
                        _buildSectionTitle('En Verimli Saat'),
                        const SizedBox(height: 12),
                        _buildMostProductiveHourCard(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'Henüz veri yok',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pomodoro yapmaya başlayın!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.timer),
            label: const Text('Zamanlayıcıya Dön'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Toplam Süre',
            value: _formatTotalTime(_totalStudyTime),
            icon: Icons.access_time,
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            title: 'Pomodoro',
            value: _totalPomodoros.toString(),
            icon: Icons.local_fire_department,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            title: 'Verimlilik',
            value: '${_productivityScore.toStringAsFixed(0)}%',
            icon: Icons.trending_up,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
        letterSpacing: 0.3,
      ),
    );
  }

  // Material Design 3 - Ortak Y ekseni hesaplama fonksiyonları
  double _calculateMaxY(double maxValue) {
    if (maxValue == 0) return 1.0; // Boş grafik için minimum

    double tempMax = maxValue * 1.2; // %20 boşluk

    // Akıllı yuvarlama - tutarlı adımlar için
    if (tempMax <= 2) {
      // 0.25'lik adımlara yuvarla
      return ((tempMax / 0.25).ceil()) * 0.25;
    } else if (tempMax <= 10) {
      // 0.5'lik adımlara yuvarla
      return ((tempMax / 0.5).ceil()) * 0.5;
    } else if (tempMax <= 60) {
      // 10'luk adımlara yuvarla
      return ((tempMax / 10).ceil()) * 10.0;
    } else if (tempMax <= 180) {
      // 30'luk adımlara yuvarla
      return ((tempMax / 30).ceil()) * 30.0;
    } else {
      // 60'lık adımlara yuvarla
      return ((tempMax / 60).ceil()) * 60.0;
    }
  }

  double _calculateInterval(double maxY) {
    if (maxY <= 1.5) return 0.25;
    if (maxY <= 5) return 0.5;
    if (maxY <= 10) return 1.0;
    if (maxY <= 60) return 10.0;
    if (maxY <= 180) return 30.0;
    return 60.0;
  }

  Widget _buildMostProductiveHourCard() {
    final startHour = _mostProductiveHour.toString().padLeft(2, '0');
    final endHour = (_mostProductiveHour + 1).toString().padLeft(2, '0');

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.wb_sunny,
                color: Colors.amber,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'En Verimli Saatiniz',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$startHour:00 - $endHour:00',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Grafik Widget'ları
  Widget _buildWeeklyLineChart() {
    if (_dailyStudyTimes.isEmpty) {
      return Card(
        color: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          height: 250,
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'Henüz günlük veri yok',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    // Haftanın günlerine göre veri haritası oluştur (1=Pzt, 7=Paz)
    final Map<int, double> weekdayData = {};
    final Map<int, DateTime> weekdayDates = {};

    // Veriyi haftanın günlerine göre eşle
    for (final entry in _dailyStudyTimes) {
      final weekday = entry.key.weekday;
      weekdayData[weekday] = entry.value.toDouble();
      weekdayDates[weekday] = entry.key;
    }

    // Pzt(1) - Paz(7) sırasına göre spotlar oluştur
    final spots = <FlSpot>[];
    double maxValue = 0;

    for (int weekday = 1; weekday <= 7; weekday++) {
      final minutes = weekdayData[weekday] ?? 0.0;
      spots.add(FlSpot((weekday - 1).toDouble(), minutes));
      if (minutes > maxValue) maxValue = minutes;
    }

    // Debug: Spot verilerini yazdır
    print('📊 HAFTALIK - Spots: $spots');
    print('📊 HAFTALIK - weekdayData: $weekdayData');
    print('📊 HAFTALIK - maxValue (raw): $maxValue');

    // ✅ ZORUNLU DÜZELTME: Inline hesaplama ile garantiye al
    double maxY;
    double interval;

    if (maxValue == 0) {
      maxY = 1.0;
      interval = 0.25;
      print('📊 HAFTALIK - maxValue = 0, maxY set to 1.0');
    } else {
      final tempMax = maxValue * 1.2;
      print('📊 HAFTALIK - tempMax = $maxValue * 1.2 = $tempMax');

      if (tempMax <= 2) {
        final calculation = (tempMax / 0.25).ceil();
        maxY = calculation * 0.25;
        interval = 0.25;
        print(
            '📊 HAFTALIK - tempMax <= 2: ($tempMax / 0.25).ceil() = $calculation, maxY = $maxY');
      } else if (tempMax <= 10) {
        final calculation = (tempMax / 0.5).ceil();
        maxY = calculation * 0.5;
        interval = 0.5;
        print(
            '📊 HAFTALIK - tempMax <= 10: ($tempMax / 0.5).ceil() = $calculation, maxY = $maxY');
      } else if (tempMax <= 60) {
        final calculation = (tempMax / 10).ceil();
        maxY = calculation * 10.0;
        interval = 10.0;
        print(
            '📊 HAFTALIK - tempMax <= 60: ($tempMax / 10).ceil() = $calculation, maxY = $maxY');
      } else if (tempMax <= 180) {
        final calculation = (tempMax / 30).ceil();
        maxY = calculation * 30.0;
        interval = 30.0;
        print(
            '📊 HAFTALIK - tempMax <= 180: ($tempMax / 30).ceil() = $calculation, maxY = $maxY');
      } else {
        final calculation = (tempMax / 60).ceil();
        maxY = calculation * 60.0;
        interval = 60.0;
        print(
            '📊 HAFTALIK - tempMax > 180: ($tempMax / 60).ceil() = $calculation, maxY = $maxY');
      }
    }

    print('📊 HAFTALIK - FINAL maxY: $maxY');
    print('📊 HAFTALIK - FINAL interval: $interval');
    print('═══════════════════════════════════════════');

    // ✅ EKSTRA DEBUG: LineChart'a gönderilmeden önce kontrol
    final chartMaxY = maxY;
    final chartInterval = interval;
    print(
        '🎨 LineChartData\'ya gönderiliyor -> maxY: $chartMaxY, interval: $chartInterval');

    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Haftalık Çalışma Trendi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Haftanın günlerine göre çalışma dağılımı',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: chartInterval,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.1),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final weekday = value.toInt() + 1;
                          if (weekday >= 1 && weekday <= 7) {
                            final date = weekdayDates[weekday];
                            final isToday = date != null && _isToday(date);
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _getDayName(weekday),
                                style: TextStyle(
                                  color: isToday
                                      ? Colors.deepPurple
                                      : Colors.black87,
                                  fontWeight: isToday
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: chartInterval,
                        reservedSize: 45,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) {
                            return const Text(
                              '0',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          }

                          // ✅ DÜZELTME: Ondalık sayılar için formatla (yuvarlama YOK!)
                          String label;
                          if (value < 1) {
                            // 0.25, 0.5, 0.75 gibi değerler
                            label = value
                                .toStringAsFixed(2)
                                .replaceAll(RegExp(r'\.?0+$'), '');
                          } else if (value < 10 && value % 1 != 0) {
                            // 1.25, 1.5, 2.75 gibi değerler - 2 basamak göster!
                            label = value
                                .toStringAsFixed(
                                    2) // ✅ 1 → 2 değişti (1.25'i 1.3'e yuvarlamayı önle)
                                .replaceAll(RegExp(r'\.?0+$'), '');
                          } else {
                            // 1, 2, 10 gibi tam sayılar
                            label = value.toInt().toString();
                          }

                          print(
                              '🏷️ Y ekseni etiketi: value=$value → label="$label"');

                          return Text(
                            '${label}dk',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.withOpacity(0.2),
                        width: 1.5,
                      ),
                      left: BorderSide(
                        color: Colors.grey.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                  ),
                  minX: 0,
                  maxX: 6,
                  minY: 0,
                  maxY: chartMaxY,
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) =>
                          Colors.deepPurple.withOpacity(0.9),
                      tooltipBorder: const BorderSide(
                        color: Colors.transparent,
                        width: 0,
                      ),
                      tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final weekday = spot.x.toInt() + 1;
                          final minutes = spot.y.toInt();
                          final hours = minutes ~/ 60;
                          final mins = minutes % 60;

                          String timeText;
                          if (hours > 0) {
                            timeText = '${hours}s ${mins}dk';
                          } else {
                            timeText = '${mins}dk';
                          }

                          return LineTooltipItem(
                            '${_getDayName(weekday)}\n$timeText',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
                    handleBuiltInTouches: true,
                    getTouchedSpotIndicator: (barData, spotIndexes) {
                      return spotIndexes.map((index) {
                        return TouchedSpotIndicatorData(
                          FlLine(
                            color: Colors.deepPurple.withOpacity(0.5),
                            strokeWidth: 2,
                            dashArray: [5, 5],
                          ),
                          FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) =>
                                FlDotCirclePainter(
                              radius: 6,
                              color: Colors.amber,
                              strokeWidth: 3,
                              strokeColor: Colors.white,
                            ),
                          ),
                        );
                      }).toList();
                    },
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.35,
                      preventCurveOverShooting:
                          true, // ✅ ÖNEMLİ: Çizginin negatif değerlere inmesini engelle
                      gradient: LinearGradient(
                        colors: [
                          Colors.deepPurple.shade400,
                          Colors.deepPurple.shade600,
                        ],
                      ),
                      barWidth: 3.5,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          final weekday = spot.x.toInt() + 1;
                          final date = weekdayDates[weekday];
                          final isToday = date != null && _isToday(date);

                          return FlDotCirclePainter(
                            radius: isToday ? 7 : 4,
                            color: isToday ? Colors.amber : Colors.white,
                            strokeWidth: isToday ? 3 : 2,
                            strokeColor: isToday
                                ? Colors.deepPurple.shade700
                                : Colors.deepPurple,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.deepPurple.withOpacity(0.2),
                            Colors.deepPurple.withOpacity(0.02),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPieChart() {
    if (_categoryDistribution.isEmpty) {
      return Card(
        color: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          height: 250,
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'Henüz kategori verisi yok',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    final totalMinutes =
        _categoryDistribution.values.fold(0, (sum, val) => sum + val);

    final List<PieChartSectionData> sections = [];
    final colors = [
      Colors.deepPurple,
      Colors.amber,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.teal,
      Colors.pink,
    ];

    int colorIndex = 0;
    for (final entry in _categoryDistribution.entries) {
      final percentage =
          totalMinutes > 0 ? (entry.value / totalMinutes * 100) : 0.0;
      if (percentage > 0) {
        sections.add(
          PieChartSectionData(
            color: colors[colorIndex % colors.length],
            value: entry.value.toDouble(),
            title: '${percentage.toStringAsFixed(0)}%',
            radius: 100,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            badgeWidget: null,
          ),
        );
        colorIndex++;
      }
    }

    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kategori Dağılımı',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Toplam çalışma süresinin kategori bazlı dağılımı',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 0,
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: _categoryDistribution.entries.map((entry) {
                final index =
                    _categoryDistribution.keys.toList().indexOf(entry.key);
                final color = colors[index % colors.length];
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyBarChart() {
    return FutureBuilder<Map<int, int>>(
      future: StatisticsService().getHourlyProductivity(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Card(
            color: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              height: 250,
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Henüz saatlik veri yok',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          );
        }

        final hourlyData = snapshot.data!;
        final maxMinutes = hourlyData.values.isEmpty
            ? 0
            : hourlyData.values.reduce((a, b) => a > b ? a : b);

        // Dinamik Y ekseni hesaplama - Material Design 3
        final maxY = _calculateMaxY(maxMinutes.toDouble());
        final interval = _calculateInterval(maxY);

        final barGroups = <BarChartGroupData>[];
        for (int hour = 0; hour < 24; hour++) {
          final minutes = hourlyData[hour] ?? 0;
          barGroups.add(
            BarChartGroupData(
              x: hour,
              barRods: [
                BarChartRodData(
                  toY: minutes.toDouble(),
                  gradient: LinearGradient(
                    colors: hour == _mostProductiveHour
                        ? [Colors.amber.shade400, Colors.amber.shade700]
                        : [
                            Colors.deepPurple.shade300,
                            Colors.deepPurple.shade500
                          ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 12,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ],
            ),
          );
        }

        return Card(
          color: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Saatlik Verimlilik',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gün içindeki çalışma sürenizin saatlere göre dağılımı',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (group) =>
                              Colors.deepPurple.withOpacity(0.8),
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final hour = group.x.toInt();
                            final minutes = rod.toY.toInt();
                            return BarTooltipItem(
                              '${hour.toString().padLeft(2, '0')}:00\n',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              children: [
                                TextSpan(
                                  text: '${minutes}dk',
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 3,
                            getTitlesWidget: (value, meta) {
                              final hour = value.toInt();
                              if (hour % 3 == 0) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    '${hour.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: interval,
                            getTitlesWidget: (value, meta) {
                              // Ondalık sayılar için akıllı formatlama
                              final formattedValue =
                                  value < 10 && value % 1 != 0
                                      ? value
                                          .toStringAsFixed(2)
                                          .replaceAll(RegExp(r'\.?0+$'), '')
                                      : value.toInt().toString();
                              return Text(
                                '${formattedValue}dk',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border(
                          bottom:
                              BorderSide(color: Colors.grey[300]!, width: 1),
                          left: BorderSide(color: Colors.grey[300]!, width: 1),
                        ),
                      ),
                      barGroups: barGroups,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: interval,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey[300]!,
                            strokeWidth: 1,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper metodlar
  String _formatTotalTime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (hours > 0) {
      return '${hours}s ${mins}dk';
    } else {
      return '${mins}dk';
    }
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Pzt';
      case 2:
        return 'Sal';
      case 3:
        return 'Çar';
      case 4:
        return 'Per';
      case 5:
        return 'Cum';
      case 6:
        return 'Cmt';
      case 7:
        return 'Paz';
      default:
        return '';
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
