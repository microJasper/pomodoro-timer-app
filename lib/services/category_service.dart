import 'database_helper.dart';
import '../models/category.dart';

class CategoryService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Maksimum özel kategori sayısı
  static const int maxCustomCategories = 20;

  // Varsayılan kategoriler
  static final List<Map<String, dynamic>> defaultCategoriesData = [
    {'name': 'Matematik', 'colorHex': '#9B59B6'}, // Mor
    {'name': 'Fizik', 'colorHex': '#3498DB'}, // Mavi
    {'name': 'Kimya', 'colorHex': '#E74C3C'}, // Kırmızı
    {'name': 'Biyoloji', 'colorHex': '#27AE60'}, // Yeşil
    {'name': 'İngilizce', 'colorHex': '#F39C12'}, // Turuncu
    {'name': 'Tarih', 'colorHex': '#95A5A6'}, // Gri
    {'name': 'Edebiyat', 'colorHex': '#E91E63'}, // Pembe
    {'name': 'Genel', 'colorHex': '#607D8B'}, // Gri-Mavi
  ];

  // Önerilen renk paleti (özel kategori ekleme için)
  static const List<String> suggestedColors = [
    '#9B59B6',
    '#3498DB',
    '#E74C3C',
    '#27AE60',
    '#F39C12',
    '#95A5A6',
    '#E91E63',
    '#607D8B',
    '#1ABC9C',
    '#2ECC71',
    '#34495E',
    '#16A085',
    '#D35400',
    '#C0392B',
    '#8E44AD',
    '#2980B9',
  ];

  // İlk açılışta varsayılan kategorileri ekle
  Future<void> initializeDefaultCategories() async {
    try {
      final existingCategories = await getAllCategories();

      // Eğer hiç kategori yoksa varsayılanları ekle
      if (existingCategories.isEmpty) {
        print('📚 Varsayılan kategoriler ekleniyor...');

        for (var data in defaultCategoriesData) {
          final category = Category(
            name: data['name'] as String,
            colorHex: data['colorHex'] as String,
            isDefault: true,
          );

          await _dbHelper.insertCategory(category);
          print('✅ ${category.name} eklendi');
        }

        print(
            '✅ ${defaultCategoriesData.length} varsayılan kategori başarıyla eklendi');
      } else {
        print(
            '📚 Kategoriler zaten mevcut (${existingCategories.length} adet)');
      }
    } catch (e) {
      print('❌ Varsayılan kategoriler eklenirken hata: $e');
    }
  }

  // Tüm kategorileri getir (varsayılan + özel)
  Future<List<Category>> getAllCategories() async {
    try {
      final categories = await _dbHelper.getAllCategories();
      print('📚 ${categories.length} kategori getirildi');
      return categories;
    } catch (e) {
      print('❌ Kategorileri getirme hatası: $e');
      return [];
    }
  }

  // Özel kategori ekle
  Future<bool> addCustomCategory(String name, String colorHex) async {
    try {
      // Kategori adı validasyonu
      if (name.trim().isEmpty) {
        print('❌ Kategori adı boş olamaz');
        return false;
      }

      if (name.length > 50) {
        print('❌ Kategori adı çok uzun (max 50 karakter)');
        return false;
      }

      // Aynı isimde kategori kontrolü
      final existingCategory = await getCategoryByName(name.trim());
      if (existingCategory != null) {
        print('❌ Bu isimde bir kategori zaten var: $name');
        return false;
      }

      // Özel kategori sayısı kontrolü
      final allCategories = await getAllCategories();
      final customCategoriesCount =
          allCategories.where((c) => !c.isDefault).length;

      if (customCategoriesCount >= maxCustomCategories) {
        print(
            '❌ Maksimum özel kategori sayısına ulaşıldı ($maxCustomCategories)');
        return false;
      }

      // Renk kodu validasyonu
      String validColorHex = colorHex.trim();
      if (!validColorHex.startsWith('#')) {
        validColorHex = '#$validColorHex';
      }

      if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(validColorHex)) {
        print('❌ Geçersiz renk kodu: $colorHex');
        return false;
      }

      // Kategori oluştur ve ekle
      final category = Category(
        name: name.trim(),
        colorHex: validColorHex.toUpperCase(),
        isDefault: false,
      );

      await _dbHelper.insertCategory(category);
      print('✅ Özel kategori eklendi: ${category.name}');
      return true;
    } catch (e) {
      print('❌ Özel kategori ekleme hatası: $e');
      return false;
    }
  }

  // Kategori güncelle
  Future<bool> updateCategory(Category category) async {
    try {
      // Varsayılan kategoriler güncellenemez (isim ve renk değiştirilemez)
      if (category.isDefault) {
        print('❌ Varsayılan kategoriler güncellenemez: ${category.name}');
        return false;
      }

      // Kategori adı validasyonu
      if (category.name.trim().isEmpty) {
        print('❌ Kategori adı boş olamaz');
        return false;
      }

      if (category.name.length > 50) {
        print('❌ Kategori adı çok uzun (max 50 karakter)');
        return false;
      }

      // Aynı isimde başka kategori kontrolü
      final existingCategory = await getCategoryByName(category.name.trim());
      if (existingCategory != null && existingCategory.id != category.id) {
        print('❌ Bu isimde bir kategori zaten var: ${category.name}');
        return false;
      }

      await _dbHelper.updateCategory(category);
      print('✅ Kategori güncellendi: ${category.name}');
      return true;
    } catch (e) {
      print('❌ Kategori güncelleme hatası: $e');
      return false;
    }
  }

  // Kategori sil (Genel kategorisi hariç tümü silinebilir)
  Future<void> deleteCategory(String id) async {
    print('');
    print('═══════════════════════════════════════');
    print('🗑️ KATEGORİ SİLME BAŞLADI');
    print('═══════════════════════════════════════');
    print('📌 Silinecek ID: $id');

    try {
      // Kategoriyi bul
      print('🔍 Kategori aranıyor...');
      final category = await getCategoryById(id);
      print('✅ Kategori bulundu: ${category.name}');
      print('📊 isDefault: ${category.isDefault}');

      // SADECE "Genel" kategorisi korunsun
      if (category.name == 'Genel') {
        print('⛔ HATA: Genel kategorisi silinemez!');
        throw Exception('Genel kategorisi silinemez! En az 1 kategori olmalı.');
      }

      print('✅ Kategori silinebilir');

      // Pomodoro kayıtlarını taşı
      print('📝 Pomodoro kayıtları taşınıyor...');
      final db = await _dbHelper.database;

      final updateCount = await db.update(
        'pomodoro_sessions',
        {'category_name': 'Genel'},
        where: 'category_name = ?',
        whereArgs: [category.name],
      );

      print('✅ $updateCount pomodoro kaydı "Genel"e taşındı');

      // Kategoriyi sil
      print('🗑️ Veritabanından siliniyor...');
      await _dbHelper.deleteCategory(id);
      print('✅ Kategori veritabanından silindi');

      print('═══════════════════════════════════════');
      print('🎉 KATEGORİ SİLME BAŞARILI: ${category.name}');
      print('═══════════════════════════════════════');
      print('');
    } catch (e, stackTrace) {
      print('');
      print('═══════════════════════════════════════');
      print('❌ KATEGORİ SİLME HATASI!');
      print('═══════════════════════════════════════');
      print('Hata: $e');
      print('Stack Trace:');
      print(stackTrace);
      print('═══════════════════════════════════════');
      print('');
      rethrow;
    }
  }

  // ID ile kategori bul
  Future<Category> getCategoryById(String id) async {
    print('🔍 getCategoryById: $id');
    final categories = await getAllCategories();
    print('📊 Toplam kategori sayısı: ${categories.length}');

    try {
      final category = categories.firstWhere((cat) => cat.id == id);
      print('✅ Kategori bulundu: ${category.name}');
      return category;
    } catch (e) {
      print('❌ Kategori bulunamadı: $id');
      print('Mevcut kategori ID\'leri:');
      for (var cat in categories) {
        print('  - ${cat.id}: ${cat.name}');
      }
      throw Exception('Kategori bulunamadı: $id');
    }
  }

  // İsimle kategori bul
  Future<Category?> getCategoryByName(String name) async {
    try {
      final allCategories = await getAllCategories();

      for (var category in allCategories) {
        if (category.name.toLowerCase() == name.toLowerCase()) {
          return category;
        }
      }

      return null;
    } catch (e) {
      print('❌ Kategori bulma hatası (İsim): $e');
      return null;
    }
  }

  // Sadece varsayılan kategorileri getir
  Future<List<Category>> getDefaultCategories() async {
    try {
      final allCategories = await getAllCategories();
      return allCategories.where((c) => c.isDefault).toList();
    } catch (e) {
      print('❌ Varsayılan kategorileri getirme hatası: $e');
      return [];
    }
  }

  // Sadece özel kategorileri getir
  Future<List<Category>> getCustomCategories() async {
    try {
      final allCategories = await getAllCategories();
      return allCategories.where((c) => !c.isDefault).toList();
    } catch (e) {
      print('❌ Özel kategorileri getirme hatası: $e');
      return [];
    }
  }

  // Özel kategori ekleme limiti kontrolü
  Future<bool> canAddMoreCustomCategories() async {
    try {
      final customCategories = await getCustomCategories();
      return customCategories.length < maxCustomCategories;
    } catch (e) {
      print('❌ Limit kontrolü hatası: $e');
      return false;
    }
  }

  // Kategori istatistikleri
  Future<Map<String, int>> getCategoryStats() async {
    try {
      final allCategories = await getAllCategories();
      final defaultCount = allCategories.where((c) => c.isDefault).length;
      final customCount = allCategories.where((c) => !c.isDefault).length;

      return {
        'total': allCategories.length,
        'default': defaultCount,
        'custom': customCount,
        'remaining': maxCustomCategories - customCount,
      };
    } catch (e) {
      print('❌ İstatistik hatası: $e');
      return {
        'total': 0,
        'default': 0,
        'custom': 0,
        'remaining': maxCustomCategories,
      };
    }
  }
}
