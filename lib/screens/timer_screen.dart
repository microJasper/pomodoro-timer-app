import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:pomodoro_timer_app/screens/settings_screen.dart';
import 'statistics_screen.dart';
import '../services/database_helper.dart';
import '../models/pomodoro_session.dart';
import '../models/category.dart';
import '../services/category_service.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen>
    with TickerProviderStateMixin {
  Timer? _timer;
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  bool _isWorkTime = true;
  int _sessionCount = 0;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final String _workEndSoundPath = 'sounds/work_end.mp3';
  final String _breakEndSoundPath = 'sounds/break_end.mp3';

  // Veritabanı ve seans takibi
  final DatabaseHelper _database = DatabaseHelper();
  final CategoryService _categoryService = CategoryService();
  DateTime? _sessionStartTime;
  String _currentCategory = "Genel";
  Category? _selectedCategory;
  List<Category> _categories = [];

  int _workTime = 25;
  int _breakTime = 5;
  int _longBreakTime = 15;
  int _sessionsUntilLongBreak = 4;
  bool _autoStart = true;
  bool _soundEnabled = true;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    _loadSettings();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      print('🔄 Kategoriler yükleniyor...');

      // Varsayılan kategorileri başlat (ilk açılışta)
      await _categoryService.initializeDefaultCategories();
      print('✅ Varsayılan kategoriler kontrol edildi');

      // Tüm kategorileri yükle
      final categories = await _categoryService.getAllCategories();
      print('📊 Yüklenen kategori sayısı: ${categories.length}');

      if (mounted) {
        setState(() {
          _categories = categories;
          // Varsayılan olarak "Genel" kategorisini seç
          if (categories.isNotEmpty) {
            _selectedCategory = categories.firstWhere(
              (c) => c.name == 'Genel',
              orElse: () => categories.first,
            );
            _currentCategory = _selectedCategory?.name ?? "Genel";
            print('✅ Seçilen kategori: $_currentCategory');
          } else {
            print('⚠️ Hiç kategori bulunamadı!');
          }
        });
      }

      print('✅ Kategori yükleme tamamlandı');
    } catch (e, stackTrace) {
      print('❌ Kategori yükleme hatası: $e');
      print('Stack trace: $stackTrace');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _workTime = prefs.getInt('workTime') ?? 25;
      _breakTime = prefs.getInt('breakTime') ?? 5;
      _longBreakTime = prefs.getInt('longBreakTime') ?? 15;
      _sessionsUntilLongBreak = prefs.getInt('sessionsUntilLongBreak') ?? 4;
      _autoStart = prefs.getBool('autoStart') ?? true;
      _soundEnabled = prefs.getBool('soundEnabled') ?? true;

      if (!_isRunning) {
        _remainingSeconds = _workTime * 60;
        _isWorkTime = true;
        _sessionCount = 0;
      }
    });
  }

  Future<void> _applyAndSaveSettings({
    int? workTime,
    int? breakTime,
    int? longBreakTime,
    int? sessionsUntilLongBreak,
    bool? autoStart,
    bool? soundEnabled,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (workTime != null) await prefs.setInt('workTime', workTime);
    if (breakTime != null) await prefs.setInt('breakTime', breakTime);
    if (longBreakTime != null)
      await prefs.setInt('longBreakTime', longBreakTime);
    if (sessionsUntilLongBreak != null)
      await prefs.setInt('sessionsUntilLongBreak', sessionsUntilLongBreak);
    if (autoStart != null) await prefs.setBool('autoStart', autoStart);
    if (soundEnabled != null) await prefs.setBool('soundEnabled', soundEnabled);

    await _loadSettings();
    if (!_isRunning) {
      setState(() {
        _remainingSeconds = _workTime * 60;
        _isWorkTime = true;
        _sessionCount = 0;
      });
    }
  }

  void _startTimer() {
    if (_isRunning) return;

    // Seans başlangıç zamanını kaydet (sadece work time için)
    if (_isWorkTime && _sessionStartTime == null) {
      _sessionStartTime = DateTime.now();
    }

    setState(() {
      _isRunning = true;
    });
    _pulseController.stop();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
          _isRunning = false;
          _pulseController.repeat(reverse: true);
          _playSound();
          _nextPhase();
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
    _pulseController.repeat(reverse: true);

    // Kesintiye uğrayan seansı kaydet (sadece work time için)
    if (_isWorkTime && _sessionStartTime != null) {
      _saveSession(interrupted: true);
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isWorkTime = true;
      _sessionCount = 0;
      _remainingSeconds = _workTime * 60;
    });
    _pulseController.repeat(reverse: true);

    // Seans başlangıç zamanını temizle
    _sessionStartTime = null;
  }

  void _nextPhase() {
    // Work time tamamlandıysa seansı kaydet
    if (_isWorkTime && _sessionStartTime != null) {
      _saveSession(interrupted: false);
    }

    if (_isWorkTime) {
      _sessionCount++;
      if (_sessionCount % _sessionsUntilLongBreak == 0) {
        _remainingSeconds = _longBreakTime * 60;
        _isWorkTime = false;
      } else {
        _remainingSeconds = _breakTime * 60;
        _isWorkTime = false;
      }
    } else {
      _remainingSeconds = _workTime * 60;
      _isWorkTime = true;
    }

    if (_autoStart && mounted) {
      setState(() {});
      _startTimer();
    } else if (mounted) {
      setState(() {});
    }
  }

  Future<void> _saveSession({required bool interrupted}) async {
    if (_sessionStartTime == null) return;

    try {
      final endTime = DateTime.now();
      final actualDuration = endTime.difference(_sessionStartTime!).inMinutes;

      final session = PomodoroSession(
        categoryName: _currentCategory,
        startTime: _sessionStartTime!,
        endTime: endTime,
        duration: actualDuration > 0 ? actualDuration : 1,
        pomodoroType: "Klasik", // Şimdilik sabit, sonra dinamik yapılacak
        completed: !interrupted,
        interrupted: interrupted,
      );

      await _database.insertSession(session);
      print(
          '✅ Seans kaydedildi: ${session.categoryName} - ${session.duration} dk (interrupted: $interrupted)');
    } catch (e) {
      print('❌ Seans kaydetme hatası: $e');
    } finally {
      // Bir sonraki seans için başlangıç zamanını sıfırla
      _sessionStartTime = null;
    }
  }

  Future<void> _playSound() async {
    if (!_soundEnabled) return;
    if (_isWorkTime) {
      await _audioPlayer.play(AssetSource(_breakEndSoundPath));
    } else {
      await _audioPlayer.play(AssetSource(_workEndSoundPath));
    }
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final int totalDuration = _isWorkTime
        ? _workTime * 60
        : (_sessionCount % _sessionsUntilLongBreak == 0 && !_isWorkTime)
            ? _longBreakTime * 60
            : _breakTime * 60;

    final double progress = totalDuration > 0
        ? (_remainingSeconds.toDouble() / totalDuration.toDouble())
        : 0.0;

    final Color primaryColor = _isWorkTime ? Colors.deepPurple : Colors.amber;

    final Color primaryColorDark =
        _isWorkTime ? Colors.deepPurple.shade700 : Colors.amber.shade700;

    return CupertinoTheme(
      data: const CupertinoThemeData(brightness: Brightness.dark),
      child: DefaultTextStyle(
        style: const TextStyle(
          decoration: TextDecoration.none,
          fontFamily: '.SF Pro Text',
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF1A1A2E),
                const Color(0xFF16213E),
                const Color(0xFF0F1419),
              ],
            ),
          ),
          child: CupertinoPageScaffold(
            backgroundColor: Colors.transparent,
            navigationBar: CupertinoNavigationBar(
              middle: const Text(
                'Pomodoro',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  decoration: TextDecoration.none,
                  color: Color(0xFFF5F5F5),
                ),
              ),
              backgroundColor: Colors.transparent,
              border: null,
              leading: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => const StatisticsScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2D3A).withOpacity(0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    CupertinoIcons.chart_bar_fill,
                    size: 22,
                    color: Color(0xFFE8E8E8),
                  ),
                ),
              ),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () async {
                  final bool? settingsChanged = await Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                  if (settingsChanged == true) {
                    _loadSettings();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2D3A).withOpacity(0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    CupertinoIcons.settings,
                    size: 22,
                    color: Color(0xFFE8E8E8),
                  ),
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isWorkTime ? 'Odaklan' : 'Dinlen',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                              letterSpacing: 0.5,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        width: 320,
                        height: 320,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.2),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 320,
                              height: 320,
                              child: CircularProgressIndicator(
                                value: 1.0,
                                strokeWidth: 12,
                                backgroundColor:
                                    const Color(0xFF2A2D3A).withOpacity(0.4),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  const Color(0xFF2A2D3A).withOpacity(0.4),
                                ),
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                            SizedBox(
                              width: 320,
                              height: 320,
                              child: ShaderMask(
                                shaderCallback: (bounds) {
                                  return LinearGradient(
                                    colors: [primaryColor, primaryColorDark],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ).createShader(bounds);
                                },
                                child: CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 12,
                                  backgroundColor: Colors.transparent,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                  strokeCap: StrokeCap.round,
                                ),
                              ),
                            ),
                            Container(
                              width: 260,
                              height: 260,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(0xFF1E2235).withOpacity(0.8),
                                    const Color(0xFF16182B),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _formatTime(_remainingSeconds),
                                    style: TextStyle(
                                      fontSize: 68,
                                      fontWeight: FontWeight.w300,
                                      color: const Color(0xFFF5F5F5),
                                      letterSpacing: -3,
                                      height: 1,
                                      decoration: TextDecoration.none,
                                      shadows: [
                                        Shadow(
                                          color: primaryColor.withOpacity(0.3),
                                          blurRadius: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _isWorkTime ? 'Çalışma' : 'Mola',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: primaryColor.withOpacity(0.9),
                                      letterSpacing: 2,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2A2D3A)
                                          .withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Seans $_sessionCount/$_sessionsUntilLongBreak',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFFB0B0B0),
                                        letterSpacing: 0.5,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2235).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF2A2D3A).withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildPresetButton(
                                  '⚡️ Klasik',
                                  '25/5',
                                  () => _applyAndSaveSettings(
                                    workTime: 25,
                                    breakTime: 5,
                                    longBreakTime: 15,
                                    sessionsUntilLongBreak: 4,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildPresetButton(
                                  '🔥 Yoğun',
                                  '50/10',
                                  () => _applyAndSaveSettings(
                                    workTime: 50,
                                    breakTime: 10,
                                    longBreakTime: 20,
                                    sessionsUntilLongBreak: 3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _buildPresetButton(
                            '🌱 Hızlı',
                            '15/3',
                            () => _applyAndSaveSettings(
                              workTime: 15,
                              breakTime: 3,
                              longBreakTime: 10,
                              sessionsUntilLongBreak: 2,
                            ),
                            fullWidth: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Kategori Seçici
                    _buildCategorySelector(),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: GestureDetector(
                            onTap: _isRunning ? _pauseTimer : _startTimer,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [primaryColor, primaryColorDark],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.4),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isRunning
                                        ? CupertinoIcons.pause_fill
                                        : CupertinoIcons.play_fill,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isRunning ? 'Duraklat' : 'Başlat',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _resetTimer,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A2D3A).withOpacity(0.8),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF3A3D4A).withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              CupertinoIcons.arrow_clockwise,
                              color: Color(0xFFE8E8E8),
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPresetButton(
    String title,
    String subtitle,
    VoidCallback onPressed, {
    bool fullWidth = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2D3A).withOpacity(0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF3A3D4A).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment:
              fullWidth ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: fullWidth
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE8E8E8),
                    letterSpacing: 0.3,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFB0B0B0).withOpacity(0.8),
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    // Kategoriler henüz yüklenmediyse loading göster
    if (_categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2D3A).withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF3A3D4A).withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Loading indicator
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF3A3D4A).withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const CupertinoActivityIndicator(
                radius: 10,
                color: Color(0xFFB0B0B0),
              ),
            ),
            const SizedBox(width: 16),
            // Loading text
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kategori',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFB0B0B0),
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Yükleniyor...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF808080),
                      letterSpacing: 0.3,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showCategoryPicker(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2D3A).withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF3A3D4A).withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Kategori rengi
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _selectedCategory != null
                    ? Color(_selectedCategory!.colorValue)
                    : Colors.grey,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_selectedCategory != null
                            ? Color(_selectedCategory!.colorValue)
                            : Colors.grey)
                        .withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Kategori adı
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kategori',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFB0B0B0),
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedCategory?.name ?? 'Seçiniz',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE8E8E8),
                      letterSpacing: 0.3,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
            // Ok ikonu
            const Icon(
              CupertinoIcons.chevron_right,
              color: Color(0xFFB0B0B0),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryPicker() {
    if (_categories.isEmpty) return;

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: 500,
              decoration: BoxDecoration(
                color: const Color(0xFF1E2235),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border.all(
                  color: const Color(0xFF2A2D3A).withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: const Color(0xFF2A2D3A).withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Kategori Seç',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFF5F5F5),
                            decoration: TextDecoration.none,
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: const Text(
                            'Kapat',
                            style: TextStyle(
                              color: Color(0xFFB0B0B0),
                              decoration: TextDecoration.none,
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  // Kategori Listesi
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected = _selectedCategory?.id == category.id;
                        // Sadece "Genel" kategorisi korunsun
                        final canDelete = category.name != 'Genel';

                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              // Ana kategori butonu (seçmek için)
                              Expanded(
                                child: CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    setState(() {
                                      _selectedCategory = category;
                                      _currentCategory = category.name;
                                    });
                                    Navigator.pop(context);
                                    print(
                                        '📂 Kategori seçildi: ${category.name}');
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Color(category.colorValue),
                                      borderRadius: BorderRadius.circular(12),
                                      border: isSelected
                                          ? Border.all(
                                              color: Colors.amber,
                                              width: 3,
                                            )
                                          : null,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(category.colorValue)
                                              .withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            category.name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              decoration: TextDecoration.none,
                                            ),
                                          ),
                                        ),
                                        // Genel kategorisine "Varsayılan" badge
                                        if (!canDelete)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'Varsayılan',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                decoration: TextDecoration.none,
                                              ),
                                            ),
                                          ),
                                        if (isSelected)
                                          const SizedBox(width: 8),
                                        if (isSelected)
                                          const Icon(
                                            CupertinoIcons
                                                .check_mark_circled_solid,
                                            color: Colors.amber,
                                            size: 24,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // SİL BUTONU (Genel hariç hepsi için)
                              if (canDelete) const SizedBox(width: 8),

                              if (canDelete)
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () async {
                                    final categoryName = category.name;
                                    final categoryId = category.id;

                                    print('');
                                    print(
                                        '🗑️ SİL BUTONUNA BASILDI: $categoryName');

                                    try {
                                      // Eğer seçili kategori siliniyorsa, önce "Genel"e geç
                                      if (_selectedCategory?.id == categoryId) {
                                        print(
                                            '⚠️ Seçili kategori siliniyor, Genel\'e geçiliyor...');
                                        final generalCategory =
                                            _categories.firstWhere(
                                          (cat) => cat.name == 'Genel',
                                        );
                                        setState(() {
                                          _selectedCategory = generalCategory;
                                          _currentCategory =
                                              generalCategory.name;
                                        });
                                        print(
                                            '✅ Seçili kategori değiştirildi: Genel');
                                      }

                                      // Kategoriyi sil (await ile bekle)
                                      print('🔄 deleteCategory çağrılıyor...');
                                      await _categoryService
                                          .deleteCategory(categoryId);
                                      print('✅ deleteCategory tamamlandı');

                                      // Kategorileri yeniden yükle
                                      print(
                                          '🔄 Kategoriler yeniden yükleniyor...');
                                      await _loadCategories();
                                      print(
                                          '✅ Kategoriler yenilendi, setState çağrılacak');

                                      // Ana UI'ı güncelle
                                      if (mounted) {
                                        setState(() {
                                          print('✅ Ana setState çağrıldı');
                                        });
                                      }

                                      // MODAL UI'ı güncelle (ÖNEMLI!)
                                      setModalState(() {
                                        print(
                                            '✅ Modal setState çağrıldı, liste güncellendi');
                                      });

                                      // TOAST MESAJI
                                      _showToast('$categoryName silindi');
                                      print('✅ Toast gösterildi');
                                      print('');
                                    } catch (e, stackTrace) {
                                      print('');
                                      print('❌ TİMER_SCREEN HATA!');
                                      print('Hata: $e');
                                      print('Stack Trace:');
                                      print(stackTrace);
                                      print('');

                                      // Hata toast'ı
                                      _showToast(
                                          'Silme hatası: ${e.toString()}',
                                          isError: true);
                                    }
                                  },
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.red.shade600,
                                          Colors.red.shade400,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.red.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      CupertinoIcons.trash_fill,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  // Yeni Kategori Ekle Butonu
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: const Color(0xFF2A2D3A).withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          _showAddCategoryDialog();
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Colors.deepPurple,
                                      Colors.deepPurpleAccent,
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.deepPurple.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  CupertinoIcons.add,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Yeni Kategori Ekle',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.deepPurple,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddCategoryDialog() {
    final TextEditingController nameController = TextEditingController();
    String selectedColor = '#9B59B6';

    final List<Map<String, dynamic>> colorOptions = [
      {'hex': '#9B59B6', 'name': 'Mor'},
      {'hex': '#3498DB', 'name': 'Mavi'},
      {'hex': '#E74C3C', 'name': 'Kırmızı'},
      {'hex': '#27AE60', 'name': 'Yeşil'},
      {'hex': '#F39C12', 'name': 'Turuncu'},
      {'hex': '#E91E63', 'name': 'Pembe'},
      {'hex': '#00BCD4', 'name': 'Turkuaz'},
      {'hex': '#FF5722', 'name': 'Koyu Turuncu'},
      {'hex': '#9C27B0', 'name': 'Koyu Mor'},
      {'hex': '#607D8B', 'name': 'Gri'},
    ];

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Color(0xFF2C3E50),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Başlık
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Yeni Kategori Ekle',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.pop(dialogContext),
                          child: Text(
                            'İptal',
                            style: TextStyle(
                              color: Colors.deepPurple.shade300,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Scrollable İçerik
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Kategori adı label
                          Text(
                            'Kategori Adı',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Cupertino Text Field
                          CupertinoTextField(
                            controller: nameController,
                            placeholder: 'Örn: Kalkülüs, Organik Kimya',
                            placeholderStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 15,
                            ),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            maxLength: 50,
                            autofocus: true,
                            clearButtonMode: OverlayVisibilityMode.editing,
                            onChanged: (value) {
                              setDialogState(() {});
                            },
                          ),

                          const SizedBox(height: 24),

                          // Renk seçimi label
                          Text(
                            'Renk Seç',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Renk seçenekleri
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: colorOptions.map((colorOption) {
                              final String hex = colorOption['hex'];
                              final bool isSelected = selectedColor == hex;

                              return GestureDetector(
                                onTap: () {
                                  setDialogState(() {
                                    selectedColor = hex;
                                  });
                                },
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Color(int.parse(
                                        hex.replaceFirst('#', '0xff'))),
                                    shape: BoxShape.circle,
                                    border: isSelected
                                        ? Border.all(
                                            color: Colors.amber,
                                            width: 4,
                                          )
                                        : Border.all(
                                            color:
                                                Colors.white.withOpacity(0.3),
                                            width: 2,
                                          ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: Color(int.parse(
                                                      hex.replaceFirst(
                                                          '#', '0xff')))
                                                  .withOpacity(0.6),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          CupertinoIcons.check_mark,
                                          color: Colors.white,
                                          size: 24,
                                        )
                                      : null,
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 24),

                          // Önizleme
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Color(int.parse(
                                  selectedColor.replaceFirst('#', '0xff'))),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(int.parse(selectedColor
                                          .replaceFirst('#', '0xff')))
                                      .withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  nameController.text.isEmpty
                                      ? 'Kategori Önizleme'
                                      : nameController.text,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Alt buton (Ekle)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                    ),
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () async {
                        final String name = nameController.text.trim();

                        // Validasyon
                        if (name.isEmpty) {
                          _showErrorDialog(context, 'Kategori adı boş olamaz!');
                          return;
                        }

                        if (name.length > 50) {
                          _showErrorDialog(context,
                              'Kategori adı çok uzun! (Max 50 karakter)');
                          return;
                        }

                        try {
                          final success = await _categoryService
                              .addCustomCategory(name, selectedColor);

                          if (success) {
                            await _loadCategories();
                            Navigator.pop(dialogContext);
                            _showSuccessDialog(
                                context, '$name kategorisi eklendi!');
                          } else {
                            Navigator.pop(dialogContext);
                            _showErrorDialog(context,
                                'Kategori eklenemedi! Aynı isimde kategori olabilir veya maksimum sayıya ulaşmış olabilirsiniz.');
                          }
                        } catch (e) {
                          print('❌ Kategori ekleme hatası: $e');
                          Navigator.pop(dialogContext);
                          _showErrorDialog(
                              context, 'Kategori eklenemedi: ${e.toString()}');
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.deepPurple,
                              Colors.deepPurple.shade300,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepPurple.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.checkmark_circle_fill,
                              color: Colors.white,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Kategori Ekle',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSuccessDialog(BuildContext context, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.check_mark_circled_solid,
                color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Başarılı'),
          ],
        ),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Tamam'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.exclamationmark_triangle_fill,
                color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('Hata'),
          ],
        ),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Tamam'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showToast(String message, {bool isError = false}) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 100,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isError
                    ? [
                        Colors.red.shade600,
                        Colors.red.shade400,
                      ]
                    : [
                        Colors.green.shade600,
                        Colors.green.shade400,
                      ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: (isError ? Colors.red : Colors.green).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isError
                      ? CupertinoIcons.exclamationmark_circle_fill
                      : CupertinoIcons.check_mark_circled_solid,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // 2 saniye sonra toast'ı kaldır
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }
}
