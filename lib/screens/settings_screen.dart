import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';
import '../services/category_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const int _defaultWorkTime = 25;
  static const int _defaultBreakTime = 5;
  static const int _defaultLongBreakTime = 15;
  static const int _defaultSessions = 4;
  static const bool _defaultAutoStart = true;
  static const bool _defaultSoundEnabled = true;

  int _workTime = _defaultWorkTime;
  int _breakTime = _defaultBreakTime;
  int _longBreakTime = _defaultLongBreakTime;
  int _sessions = _defaultSessions;
  bool _autoStart = _defaultAutoStart;
  bool _soundEnabled = _defaultSoundEnabled;

  final FixedExtentScrollController _workScrollController =
      FixedExtentScrollController(initialItem: _defaultWorkTime - 1);
  final FixedExtentScrollController _breakScrollController =
      FixedExtentScrollController(initialItem: _defaultBreakTime - 1);
  final FixedExtentScrollController _longBreakScrollController =
      FixedExtentScrollController(initialItem: _defaultLongBreakTime - 1);
  final FixedExtentScrollController _sessionsScrollController =
      FixedExtentScrollController(initialItem: _defaultSessions - 1);

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final work = prefs.getInt('workTime') ?? _defaultWorkTime;
    final breakT = prefs.getInt('breakTime') ?? _defaultBreakTime;
    final longBreakT = prefs.getInt('longBreakTime') ?? _defaultLongBreakTime;
    final sessions = prefs.getInt('sessionsUntilLongBreak') ?? _defaultSessions;
    final autoStart = prefs.getBool('autoStart') ?? _defaultAutoStart;
    final soundEnabled = prefs.getBool('soundEnabled') ?? _defaultSoundEnabled;

    _workTime = work;
    _breakTime = breakT;
    _longBreakTime = longBreakT;
    _sessions = sessions;
    _autoStart = autoStart;
    _soundEnabled = soundEnabled;

    _workScrollController.jumpToItem(_workTime - 1);
    _breakScrollController.jumpToItem(_breakTime - 1);
    _longBreakScrollController.jumpToItem(_longBreakTime - 1);
    _sessionsScrollController.jumpToItem(_sessions - 1);

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _workScrollController.dispose();
    _breakScrollController.dispose();
    _longBreakScrollController.dispose();
    _sessionsScrollController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('workTime', _workTime);
    await prefs.setInt('breakTime', _breakTime);
    await prefs.setInt('longBreakTime', _longBreakTime);
    await prefs.setInt('sessionsUntilLongBreak', _sessions);
    await prefs.setBool('autoStart', _autoStart);
    await prefs.setBool('soundEnabled', _soundEnabled);

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  void _resetSettingsToDefaults() {
    setState(() {
      _workTime = _defaultWorkTime;
      _breakTime = _defaultBreakTime;
      _longBreakTime = _defaultLongBreakTime;
      _sessions = _defaultSessions;
      _autoStart = _defaultAutoStart;
      _soundEnabled = _defaultSoundEnabled;

      _workScrollController.jumpToItem(_defaultWorkTime - 1);
      _breakScrollController.jumpToItem(_defaultBreakTime - 1);
      _longBreakScrollController.jumpToItem(_defaultLongBreakTime - 1);
      _sessionsScrollController.jumpToItem(_defaultSessions - 1);
    });
  }

  void _showResetConfirmation() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Ayarları Sıfırla'),
          content: const Text(
              'Tüm ayarları varsayılan değerlere döndürmek istediğinizden emin misiniz?'),
          actions: [
            CupertinoDialogAction(
              child: const Text('Vazgeç'),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Sıfırla'),
              onPressed: () {
                Navigator.pop(context);
                _resetSettingsToDefaults();
              },
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildPickerItems(int max) {
    return List.generate(max, (index) {
      final value = index + 1;
      return Center(
        child: Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 22,
            color: CupertinoColors.white,
            decoration: TextDecoration.none,
          ),
        ),
      );
    });
  }

  void _showPickerModal(
    BuildContext context, {
    required FixedExtentScrollController controller,
    required int maxValue,
    required ValueChanged<int> onSelectedItemChanged,
  }) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 250,
          decoration: BoxDecoration(
            color: const Color(0xFF1E2235),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: const Color(0xFF2A2D3A).withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
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
                    CupertinoButton(
                      child: const Text(
                        'İptal',
                        style: TextStyle(
                          color: Color(0xFFB0B0B0),
                          decoration: TextDecoration.none,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    CupertinoButton(
                      child: const Text(
                        'Tamam',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 40.0,
                  scrollController: controller,
                  children: _buildPickerItems(maxValue),
                  onSelectedItemChanged: (index) {
                    onSelectedItemChanged(index + 1);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                'Ayarlar',
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
                onPressed: () => Navigator.pop(context),
                child: const Icon(
                  CupertinoIcons.back,
                  color: Color(0xFFE8E8E8),
                ),
              ),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _saveSettings,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.deepPurple, Colors.deepPurple.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Kaydet',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ),
            child: SafeArea(
              child: _isLoading
                  ? const Center(
                      child: CupertinoActivityIndicator(
                        radius: 16,
                        color: Colors.deepPurple,
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 20),
                      children: [
                        _buildSectionHeader('⚡️ Otomasyon', Icons.flash_on),
                        const SizedBox(height: 12),
                        _buildCard(
                          children: [
                            _buildToggleTile(
                              icon: CupertinoIcons.play_circle_fill,
                              title: 'Otomatik Başlat',
                              subtitle: 'Molaları otomatik olarak başlat',
                              value: _autoStart,
                              onChanged: (value) =>
                                  setState(() => _autoStart = value),
                            ),
                            _buildDivider(),
                            _buildToggleTile(
                              icon: CupertinoIcons.speaker_2_fill,
                              title: 'Sesli Bildirimler',
                              subtitle: 'Süre bittiğinde ses çıkar',
                              value: _soundEnabled,
                              onChanged: (value) =>
                                  setState(() => _soundEnabled = value),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        _buildSectionHeader('⏱ Süre Ayarları', Icons.timer),
                        const SizedBox(height: 12),
                        _buildCard(
                          children: [
                            _buildPickerTile(
                              icon: CupertinoIcons.timer,
                              title: 'Çalışma Süresi',
                              currentValue: _workTime,
                              unit: 'dk',
                              controller: _workScrollController,
                              maxValue: 60,
                              color: Colors.deepPurple,
                              onSelectedItemChanged: (newValue) {
                                setState(() => _workTime = newValue);
                              },
                            ),
                            _buildDivider(),
                            _buildPickerTile(
                              icon: CupertinoIcons.pause_circle,
                              title: 'Kısa Mola',
                              currentValue: _breakTime,
                              unit: 'dk',
                              controller: _breakScrollController,
                              maxValue: 30,
                              color: Colors.amber,
                              onSelectedItemChanged: (newValue) {
                                setState(() => _breakTime = newValue);
                              },
                            ),
                            _buildDivider(),
                            _buildPickerTile(
                              icon: CupertinoIcons.moon_fill,
                              title: 'Uzun Mola',
                              currentValue: _longBreakTime,
                              unit: 'dk',
                              controller: _longBreakScrollController,
                              maxValue: 60,
                              color: Colors.amber,
                              onSelectedItemChanged: (newValue) {
                                setState(() => _longBreakTime = newValue);
                              },
                            ),
                            _buildDivider(),
                            _buildPickerTile(
                              icon: CupertinoIcons.repeat,
                              title: 'Uzun Mola Aralığı',
                              currentValue: _sessions,
                              unit: 'seans',
                              controller: _sessionsScrollController,
                              maxValue: 10,
                              color: Colors.amber,
                              onSelectedItemChanged: (newValue) {
                                setState(() => _sessions = newValue);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        _buildSectionHeader('💾 Veri Yönetimi', Icons.storage),
                        const SizedBox(height: 12),
                        _buildCard(
                          children: [
                            _buildActionTile(
                              icon: CupertinoIcons.chart_bar,
                              title: 'İstatistikleri Sıfırla',
                              subtitle:
                                  'Pomodoro kayıtlarını sil (kategoriler korunur)',
                              onTap: _showResetStatisticsConfirmation,
                              isDestructive: false,
                            ),
                            _buildDivider(),
                            _buildActionTile(
                              icon: CupertinoIcons.trash,
                              title: 'Tüm Verileri Sil',
                              subtitle:
                                  'Pomodoro kayıtları + özel kategoriler silinir',
                              onTap: _showDeleteAllDataConfirmation,
                              isDestructive: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        _buildSectionHeader('🔄 Diğer', Icons.settings),
                        const SizedBox(height: 12),
                        _buildCard(
                          children: [
                            _buildActionTile(
                              icon: CupertinoIcons.refresh_circled,
                              title: 'Varsayılana Sıfırla',
                              subtitle: 'Tüm ayarları varsayılana döndür',
                              onTap: _showResetConfirmation,
                              isDestructive: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFFF5F5F5),
              letterSpacing: 0.5,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2235).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2A2D3A).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: const Color(0xFF2A2D3A).withOpacity(0.5),
      indent: 56,
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2D3A).withOpacity(0.6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 22,
              color: const Color(0xFFFF6B6B),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF5F5F5),
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFFB0B0B0).withOpacity(0.8),
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFFF6B6B),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerTile({
    required IconData icon,
    required String title,
    required int currentValue,
    required String unit,
    required FixedExtentScrollController controller,
    required int maxValue,
    required Color color,
    required ValueChanged<int> onSelectedItemChanged,
  }) {
    return GestureDetector(
      onTap: () {
        _showPickerModal(
          context,
          controller: controller,
          maxValue: maxValue,
          onSelectedItemChanged: onSelectedItemChanged,
        );
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 22,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF5F5F5),
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2D3A).withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    currentValue.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFB0B0B0),
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              CupertinoIcons.chevron_right,
              size: 18,
              color: const Color(0xFFB0B0B0).withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDestructive
                    ? const Color(0xFFFF6B6B).withOpacity(0.15)
                    : const Color(0xFF2A2D3A).withOpacity(0.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isDestructive
                    ? const Color(0xFFFF6B6B)
                    : const Color(0xFFB0B0B0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDestructive
                          ? const Color(0xFFFF6B6B)
                          : const Color(0xFFF5F5F5),
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: const Color(0xFFB0B0B0).withOpacity(0.8),
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 18,
              color: const Color(0xFFB0B0B0).withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  // İstatistikleri Sıfırla Onayı
  void _showResetStatisticsConfirmation() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.chart_bar, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Text('İstatistikleri Sıfırla'),
            ],
          ),
          content: const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Tüm pomodoro kayıtları silinecek.\n\nKategorileriniz korunacak.\n\nBu işlem geri alınamaz!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('İptal'),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () async {
                Navigator.pop(context);
                await _resetStatistics();
              },
              child: const Text('Sıfırla'),
            ),
          ],
        );
      },
    );
  }

  // İstatistikleri Sıfırla
  Future<void> _resetStatistics() async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      // Tüm pomodoro kayıtlarını sil
      await db.delete('pomodoro_sessions');

      print('✅ Tüm pomodoro kayıtları silindi');

      // Başarı mesajı
      if (mounted) {
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
            content: const Text('İstatistikler sıfırlandı!'),
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
    } catch (e) {
      print('❌ İstatistik sıfırlama hatası: $e');

      if (mounted) {
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
            content: Text('Hata oluştu: ${e.toString()}'),
            actions: [
              CupertinoDialogAction(
                child: const Text('Tamam'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    }
  }

  // Tüm Verileri Sil Onayı
  void _showDeleteAllDataConfirmation() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.trash, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text('Tüm Verileri Sil'),
            ],
          ),
          content: const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              '⚠️ DİKKAT! ⚠️\n\nTüm pomodoro kayıtları SİLİNECEK.\nTüm özel kategoriler SİLİNECEK.\n\nSadece varsayılan kategoriler kalacak.\n\nBu işlem GERİ ALINAMAZ!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('İptal'),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () async {
                Navigator.pop(context);
                await _deleteAllData();
              },
              child: const Text('Tümünü Sil'),
            ),
          ],
        );
      },
    );
  }

  // Tüm Verileri Sil
  Future<void> _deleteAllData() async {
    try {
      final dbHelper = DatabaseHelper();
      final categoryService = CategoryService();
      final db = await dbHelper.database;

      print('🗑️ Tüm veriler siliniyor...');

      // 1. Tüm pomodoro kayıtlarını sil
      await db.delete('pomodoro_sessions');
      print('✅ Pomodoro kayıtları silindi');

      // 2. Özel kategorileri sil (varsayılanlar korunur)
      final allCategories = await categoryService.getAllCategories();
      int deletedCount = 0;

      for (var category in allCategories) {
        if (!category.isDefault) {
          try {
            await categoryService.deleteCategory(category.id);
            deletedCount++;
          } catch (e) {
            print('⚠️ Kategori silinemedi: ${category.name}');
          }
        }
      }

      print('✅ $deletedCount özel kategori silindi');
      print('✅ Tüm veriler silindi');

      // Başarı mesajı
      if (mounted) {
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
            content: Text(
                'Tüm veriler silindi!\n\n$deletedCount özel kategori kaldırıldı.'),
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
    } catch (e) {
      print('❌ Veri silme hatası: $e');

      if (mounted) {
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
            content: Text('Hata oluştu: ${e.toString()}'),
            actions: [
              CupertinoDialogAction(
                child: const Text('Tamam'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    }
  }
}
