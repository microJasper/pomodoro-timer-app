import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/pomodoro_session.dart';
import '../models/category.dart';

class DatabaseHelper {
  // Singleton pattern - tek bir instance olacak
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  // Factory constructor - her zaman aynı instance'ı döndürür
  factory DatabaseHelper() {
    return _instance;
  }

  // Private constructor
  DatabaseHelper._internal();

  // Veritabanı dosya adı ve versiyon
  static const String _databaseName = 'pomodoro_database.db';
  static const int _databaseVersion =
      2; // Version artırıldı (categories tablosu için)

  // Tablo ve kolon adları
  static const String _tableName = 'pomodoro_sessions';
  static const String _columnId = 'id';
  static const String _columnCategoryName = 'category_name';
  static const String _columnStartTime = 'start_time';
  static const String _columnEndTime = 'end_time';
  static const String _columnDuration = 'duration';
  static const String _columnPomodoroType = 'pomodoro_type';
  static const String _columnCompleted = 'completed';
  static const String _columnInterrupted = 'interrupted';

  // Categories tablo ve kolon adları
  static const String _categoriesTableName = 'categories';
  static const String _catColumnId = 'id';
  static const String _catColumnName = 'name';
  static const String _catColumnColorHex = 'color_hex';
  static const String _catColumnIsDefault = 'is_default';
  static const String _catColumnCreatedAt = 'created_at';

  // Veritabanı getter - lazy initialization
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  // Veritabanını başlat ve tabloyu oluştur
  Future<Database> initDatabase() async {
    try {
      // Veritabanı dosyasının yolunu al
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, _databaseName);

      print('Veritabanı yolu: $path');

      // Veritabanını aç (yoksa oluştur)
      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      print('Veritabanı başlatma hatası: $e');
      rethrow;
    }
  }

  // Tablo oluşturma fonksiyonu (ilk kurulumda çalışır)
  Future<void> _onCreate(Database db, int version) async {
    try {
      // Pomodoro sessions tablosu
      await db.execute('''
        CREATE TABLE $_tableName (
          $_columnId TEXT PRIMARY KEY,
          $_columnCategoryName TEXT NOT NULL,
          $_columnStartTime INTEGER NOT NULL,
          $_columnEndTime INTEGER NOT NULL,
          $_columnDuration INTEGER NOT NULL,
          $_columnPomodoroType TEXT NOT NULL,
          $_columnCompleted INTEGER NOT NULL DEFAULT 0,
          $_columnInterrupted INTEGER NOT NULL DEFAULT 0
        )
      ''');
      print('Tablo başarıyla oluşturuldu: $_tableName');

      // Categories tablosu
      await db.execute('''
        CREATE TABLE $_categoriesTableName (
          $_catColumnId TEXT PRIMARY KEY,
          $_catColumnName TEXT NOT NULL,
          $_catColumnColorHex TEXT NOT NULL,
          $_catColumnIsDefault INTEGER NOT NULL DEFAULT 0,
          $_catColumnCreatedAt INTEGER NOT NULL
        )
      ''');
      print('Tablo başarıyla oluşturuldu: $_categoriesTableName');
    } catch (e) {
      print('Tablo oluşturma hatası: $e');
      rethrow;
    }
  }

  // Veritabanı versiyonu güncellendiğinde çalışır (gelecekteki güncellemeler için)
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Veritabanı güncelleniyor: v$oldVersion -> v$newVersion');

    // v1'den v2'ye: categories tablosu ekle
    if (oldVersion < 2) {
      try {
        await db.execute('''
          CREATE TABLE $_categoriesTableName (
            $_catColumnId TEXT PRIMARY KEY,
            $_catColumnName TEXT NOT NULL,
            $_catColumnColorHex TEXT NOT NULL,
            $_catColumnIsDefault INTEGER NOT NULL DEFAULT 0,
            $_catColumnCreatedAt INTEGER NOT NULL
          )
        ''');
        print('Categories tablosu başarıyla eklendi (v1 -> v2)');
      } catch (e) {
        print('Categories tablosu ekleme hatası: $e');
        rethrow;
      }
    }
  }

  // Yeni seans kaydet
  Future<int> insertSession(PomodoroSession session) async {
    try {
      final db = await database;
      final map = _sessionToMap(session);

      final result = await db.insert(
        _tableName,
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      print('Seans kaydedildi: ${session.id}');
      return result;
    } catch (e) {
      print('Seans kaydetme hatası: $e');
      rethrow;
    }
  }

  // Tüm seansları getir (en yeniden en eskiye)
  Future<List<PomodoroSession>> getAllSessions() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        orderBy: '$_columnStartTime DESC',
      );

      print('${maps.length} seans getirildi');
      return maps.map((map) => _mapToSession(map)).toList();
    } catch (e) {
      print('Seansları getirme hatası: $e');
      return [];
    }
  }

  // Tarih aralığına göre seansları getir
  Future<List<PomodoroSession>> getSessionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final db = await database;

      final startTimestamp = start.millisecondsSinceEpoch;
      final endTimestamp = end.millisecondsSinceEpoch;

      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: '$_columnStartTime >= ? AND $_columnStartTime <= ?',
        whereArgs: [startTimestamp, endTimestamp],
        orderBy: '$_columnStartTime DESC',
      );

      print(
          '${maps.length} seans getirildi (${start.toString().split(' ')[0]} - ${end.toString().split(' ')[0]})');
      return maps.map((map) => _mapToSession(map)).toList();
    } catch (e) {
      print('Tarih aralığına göre seansları getirme hatası: $e');
      return [];
    }
  }

  // Kategoriye göre seansları getir
  Future<List<PomodoroSession>> getSessionsByCategory(String category) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: '$_columnCategoryName = ?',
        whereArgs: [category],
        orderBy: '$_columnStartTime DESC',
      );

      print('${maps.length} seans getirildi (kategori: $category)');
      return maps.map((map) => _mapToSession(map)).toList();
    } catch (e) {
      print('Kategoriye göre seansları getirme hatası: $e');
      return [];
    }
  }

  // Belirli bir seansı sil
  Future<int> deleteSession(String id) async {
    try {
      final db = await database;
      final result = await db.delete(
        _tableName,
        where: '$_columnId = ?',
        whereArgs: [id],
      );

      print('Seans silindi: $id');
      return result;
    } catch (e) {
      print('Seans silme hatası: $e');
      return 0;
    }
  }

  // Tüm seansları sil (test/debug için)
  Future<int> deleteAllSessions() async {
    try {
      final db = await database;
      final result = await db.delete(_tableName);

      print('Tüm seanslar silindi ($result adet)');
      return result;
    } catch (e) {
      print('Tüm seansları silme hatası: $e');
      return 0;
    }
  }

  // Tamamlanmış seansların sayısını getir
  Future<int> getCompletedSessionsCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName WHERE $_columnCompleted = 1',
      );

      final count = Sqflite.firstIntValue(result) ?? 0;
      return count;
    } catch (e) {
      print('Tamamlanan seansları sayma hatası: $e');
      return 0;
    }
  }

  // Toplam odaklanma süresini hesapla (tamamlanan seanslar, dakika cinsinden)
  Future<int> getTotalFocusTime() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT SUM($_columnDuration) as total FROM $_tableName WHERE $_columnCompleted = 1',
      );

      final total = Sqflite.firstIntValue(result) ?? 0;
      return total;
    } catch (e) {
      print('Toplam odaklanma süresini hesaplama hatası: $e');
      return 0;
    }
  }

  // Veritabanını kapat (uygulama kapanırken)
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    print('Veritabanı kapatıldı');
  }

  // === HELPER METODLAR ===

  // PomodoroSession'ı Map'e dönüştür (veritabanı için)
  Map<String, dynamic> _sessionToMap(PomodoroSession session) {
    return {
      _columnId: session.id,
      _columnCategoryName: session.categoryName,
      _columnStartTime: session.startTime.millisecondsSinceEpoch,
      _columnEndTime: session.endTime.millisecondsSinceEpoch,
      _columnDuration: session.duration,
      _columnPomodoroType: session.pomodoroType,
      _columnCompleted: session.completed ? 1 : 0,
      _columnInterrupted: session.interrupted ? 1 : 0,
    };
  }

  // Map'i PomodoroSession'a dönüştür
  PomodoroSession _mapToSession(Map<String, dynamic> map) {
    return PomodoroSession(
      id: map[_columnId] as String,
      categoryName: map[_columnCategoryName] as String,
      startTime: DateTime.fromMillisecondsSinceEpoch(
        map[_columnStartTime] as int,
      ),
      endTime: DateTime.fromMillisecondsSinceEpoch(
        map[_columnEndTime] as int,
      ),
      duration: map[_columnDuration] as int,
      pomodoroType: map[_columnPomodoroType] as String,
      completed: (map[_columnCompleted] as int) == 1,
      interrupted: (map[_columnInterrupted] as int) == 1,
    );
  }

  // === CATEGORY CRUD METODLARI ===

  // Kategori ekle
  Future<int> insertCategory(Category category) async {
    try {
      final db = await database;
      final map = _categoryToMap(category);

      final result = await db.insert(
        _categoriesTableName,
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      print('Kategori kaydedildi: ${category.name}');
      return result;
    } catch (e) {
      print('Kategori kaydetme hatası: $e');
      rethrow;
    }
  }

  // Tüm kategorileri getir
  Future<List<Category>> getAllCategories() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _categoriesTableName,
        orderBy: '$_catColumnIsDefault DESC, $_catColumnName ASC',
      );

      print('${maps.length} kategori getirildi');
      return maps.map((map) => _mapToCategory(map)).toList();
    } catch (e) {
      print('Kategorileri getirme hatası: $e');
      return [];
    }
  }

  // Kategori güncelle
  Future<int> updateCategory(Category category) async {
    try {
      final db = await database;
      final map = _categoryToMap(category);

      final result = await db.update(
        _categoriesTableName,
        map,
        where: '$_catColumnId = ?',
        whereArgs: [category.id],
      );

      print('Kategori güncellendi: ${category.name}');
      return result;
    } catch (e) {
      print('Kategori güncelleme hatası: $e');
      return 0;
    }
  }

  // Kategori sil
  Future<int> deleteCategory(String id) async {
    try {
      final db = await database;
      final result = await db.delete(
        _categoriesTableName,
        where: '$_catColumnId = ?',
        whereArgs: [id],
      );

      print('Kategori silindi: $id');
      return result;
    } catch (e) {
      print('Kategori silme hatası: $e');
      return 0;
    }
  }

  // ID ile kategori bul
  Future<Category?> getCategoryById(String id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _categoriesTableName,
        where: '$_catColumnId = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        return _mapToCategory(maps.first);
      }
      return null;
    } catch (e) {
      print('Kategori bulma hatası: $e');
      return null;
    }
  }

  // === CATEGORY HELPER METODLAR ===

  // Category'ı Map'e dönüştür (veritabanı için)
  Map<String, dynamic> _categoryToMap(Category category) {
    return {
      _catColumnId: category.id,
      _catColumnName: category.name,
      _catColumnColorHex: category.colorHex,
      _catColumnIsDefault: category.isDefault ? 1 : 0,
      _catColumnCreatedAt: category.createdAt.millisecondsSinceEpoch,
    };
  }

  // Map'i Category'e dönüştür
  Category _mapToCategory(Map<String, dynamic> map) {
    return Category(
      id: map[_catColumnId] as String,
      name: map[_catColumnName] as String,
      colorHex: map[_catColumnColorHex] as String,
      isDefault: (map[_catColumnIsDefault] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map[_catColumnCreatedAt] as int,
      ),
    );
  }
}
