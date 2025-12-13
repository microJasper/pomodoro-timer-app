# Kategori Yönetim Sistemi - Kullanım Kılavuzu

## 📚 Genel Bakış

Bu sistem, Pomodoro Timer uygulamasında kategorileri yönetmek için kullanılır.

---

## 🗂️ Dosya Yapısı

```
lib/
├── models/
│   └── category.dart           # Kategori modeli
└── services/
    ├── category_service.dart   # Kategori iş mantığı
    └── database_helper.dart    # Veritabanı işlemleri (güncellenmiş)
```

---

## 🎯 Kullanım Örnekleri

### 1. İlk Kurulum (main.dart veya splash_screen.dart'ta)

```dart
import 'package:flutter/material.dart';
import 'services/category_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Varsayılan kategorileri yükle
  final categoryService = CategoryService();
  await categoryService.initializeDefaultCategories();
  
  runApp(MyApp());
}
```

---

### 2. Tüm Kategorileri Listeleme

```dart
import 'services/category_service.dart';
import 'package:flutter/material.dart';

class CategoryListScreen extends StatefulWidget {
  @override
  _CategoryListScreenState createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  final CategoryService _categoryService = CategoryService();
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await _categoryService.getAllCategories();
    setState(() {
      _categories = categories;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Color(category.colorValue),
          ),
          title: Text(category.name),
          subtitle: Text(category.isDefault ? 'Varsayılan' : 'Özel'),
          trailing: category.isDefault 
              ? null 
              : IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _deleteCategory(category.id),
                ),
        );
      },
    );
  }

  Future<void> _deleteCategory(String id) async {
    final success = await _categoryService.deleteCategory(id);
    if (success) {
      _loadCategories(); // Listeyi yenile
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kategori silindi')),
      );
    }
  }
}
```

---

### 3. Yeni Kategori Ekleme

```dart
import 'services/category_service.dart';
import 'package:flutter/material.dart';

class AddCategoryDialog extends StatefulWidget {
  @override
  _AddCategoryDialogState createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final CategoryService _categoryService = CategoryService();
  final TextEditingController _nameController = TextEditingController();
  String _selectedColor = '#9B59B6';

  Future<void> _addCategory() async {
    final name = _nameController.text.trim();
    
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kategori adı boş olamaz')),
      );
      return;
    }

    final success = await _categoryService.addCustomCategory(name, _selectedColor);
    
    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kategori eklendi: $name')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kategori eklenemedi')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Yeni Kategori'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Kategori Adı',
              hintText: 'Örn: Programlama',
            ),
          ),
          SizedBox(height: 16),
          Text('Renk Seçin:'),
          Wrap(
            spacing: 8,
            children: CategoryService.suggestedColors.map((color) {
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(int.parse(color.replaceAll('#', 'FF'), radix: 16)),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _selectedColor == color ? Colors.black : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _addCategory,
          child: Text('Ekle'),
        ),
      ],
    );
  }
}
```

---

### 4. Kategori Seçici Widget

```dart
import 'services/category_service.dart';
import 'models/category.dart';
import 'package:flutter/material.dart';

class CategoryPicker extends StatefulWidget {
  final Function(Category) onCategorySelected;
  final Category? initialCategory;

  const CategoryPicker({
    required this.onCategorySelected,
    this.initialCategory,
  });

  @override
  _CategoryPickerState createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<CategoryPicker> {
  final CategoryService _categoryService = CategoryService();
  List<Category> _categories = [];
  Category? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await _categoryService.getAllCategories();
    setState(() {
      _categories = categories;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<Category>(
      value: _selectedCategory,
      hint: Text('Kategori Seçin'),
      isExpanded: true,
      items: _categories.map((category) {
        return DropdownMenuItem<Category>(
          value: category,
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Color(category.colorValue),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 12),
              Text(category.name),
            ],
          ),
        );
      }).toList(),
      onChanged: (category) {
        if (category != null) {
          setState(() => _selectedCategory = category);
          widget.onCategorySelected(category);
        }
      },
    );
  }
}

// Kullanım:
CategoryPicker(
  onCategorySelected: (category) {
    print('Seçilen kategori: ${category.name}');
    // Timer screen'de _currentCategory = category.name;
  },
  initialCategory: await _categoryService.getCategoryByName('Genel'),
)
```

---

### 5. Kategori İstatistikleri

```dart
import 'services/category_service.dart';

Future<void> showCategoryStats() async {
  final categoryService = CategoryService();
  final stats = await categoryService.getCategoryStats();

  print('📊 Kategori İstatistikleri:');
  print('Toplam: ${stats['total']}');
  print('Varsayılan: ${stats['default']}');
  print('Özel: ${stats['custom']}');
  print('Kalan Limit: ${stats['remaining']}');
}
```

---

### 6. Kategori Güncelleme

```dart
import 'services/category_service.dart';

Future<void> updateCategory() async {
  final categoryService = CategoryService();
  
  // Kategoriyi bul
  final category = await categoryService.getCategoryByName('Programlama');
  
  if (category != null && !category.isDefault) {
    // Güncelle
    final updatedCategory = category.copyWith(
      name: 'Yazılım Geliştirme',
      colorHex: '#2ECC71',
    );
    
    final success = await categoryService.updateCategory(updatedCategory);
    
    if (success) {
      print('✅ Kategori güncellendi');
    }
  }
}
```

---

### 7. Timer Screen Entegrasyonu

```dart
// timer_screen.dart içinde:

import 'services/category_service.dart';
import 'models/category.dart';

class _TimerScreenState extends State<TimerScreen> {
  final CategoryService _categoryService = CategoryService();
  List<Category> _categories = [];
  Category? _selectedCategory;
  
  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await _categoryService.getAllCategories();
    setState(() {
      _categories = categories;
      // Varsayılan olarak "Genel" kategorisini seç
      _selectedCategory = categories.firstWhere(
        (c) => c.name == 'Genel',
        orElse: () => categories.first,
      );
    });
  }

  // Seans kaydederken:
  Future<void> _saveSession({required bool interrupted}) async {
    if (_sessionStartTime == null || _selectedCategory == null) return;

    try {
      final endTime = DateTime.now();
      final actualDuration = endTime.difference(_sessionStartTime!).inMinutes;

      final session = PomodoroSession(
        categoryName: _selectedCategory!.name,  // Kategori adını kullan
        startTime: _sessionStartTime!,
        endTime: endTime,
        duration: actualDuration > 0 ? actualDuration : 1,
        pomodoroType: "Klasik",
        completed: !interrupted,
        interrupted: interrupted,
      );

      await _database.insertSession(session);
      print('✅ Seans kaydedildi: ${session.categoryName}');
    } catch (e) {
      print('❌ Seans kaydetme hatası: $e');
    }
  }
}
```

---

## 🎨 Varsayılan Kategoriler

| Kategori | Renk | Hex Kod |
|----------|------|---------|
| Matematik | 🟣 Mor | #9B59B6 |
| Fizik | 🔵 Mavi | #3498DB |
| Kimya | 🔴 Kırmızı | #E74C3C |
| Biyoloji | 🟢 Yeşil | #27AE60 |
| İngilizce | 🟠 Turuncu | #F39C12 |
| Tarih | ⚪ Gri | #95A5A6 |
| Edebiyat | 🩷 Pembe | #E91E63 |
| Genel | 🔷 Gri-Mavi | #607D8B |

---

## ⚠️ Önemli Notlar

### Limitler:
- ✅ Maksimum 20 özel kategori eklenebilir
- ✅ Kategori adı maksimum 30 karakter
- ✅ Varsayılan kategoriler silinemez veya düzenlenemez

### Validasyonlar:
- ❌ Boş kategori adı
- ❌ Aynı isimde kategori
- ❌ Geçersiz renk kodu
- ❌ Limit aşımı

---

## 🔍 Debug

Tüm kategori metodları konsola log yazdırır:

```
📚 Varsayılan kategoriler ekleniyor...
✅ Matematik eklendi
✅ Fizik eklendi
...
✅ 8 varsayılan kategori başarıyla eklendi

📚 15 kategori getirildi
✅ Özel kategori eklendi: Programlama
❌ Bu isimde bir kategori zaten var: Matematik
```

---

## 🚀 İleri Seviye Kullanım

### Renk Yardımcı Fonksiyonu

```dart
extension CategoryColorExtension on Category {
  Color get color => Color(colorValue);
  
  bool get isDarkColor {
    final r = (colorValue >> 16) & 0xFF;
    final g = (colorValue >> 8) & 0xFF;
    final b = colorValue & 0xFF;
    final brightness = (r * 299 + g * 587 + b * 114) / 1000;
    return brightness < 128;
  }
  
  Color get textColor => isDarkColor ? Colors.white : Colors.black;
}
```

### Kategori Filtreleme

```dart
// Sadece özel kategoriler
final customCategories = await _categoryService.getCustomCategories();

// Sadece varsayılan kategoriler
final defaultCategories = await _categoryService.getDefaultCategories();

// İsme göre arama
final category = await _categoryService.getCategoryByName('Matematik');

// ID ile bulma
final category = await _categoryService.getCategoryById('uuid-123');
```

---

## ✅ Test Önerileri

```dart
void testCategorySystem() async {
  final service = CategoryService();
  
  // 1. İlk kurulum
  await service.initializeDefaultCategories();
  
  // 2. Kategori ekleme
  final success = await service.addCustomCategory('Test', '#FF0000');
  assert(success == true);
  
  // 3. Kategori getirme
  final categories = await service.getAllCategories();
  assert(categories.length >= 9); // 8 varsayılan + 1 özel
  
  // 4. Kategori silme
  final testCategory = await service.getCategoryByName('Test');
  if (testCategory != null) {
    final deleted = await service.deleteCategory(testCategory.id);
    assert(deleted == true);
  }
  
  print('✅ Tüm testler başarılı!');
}
```

---

## 📞 Destek

Sorunlarınız için konsol loglarını kontrol edin. Tüm metodlar detaylı hata mesajları yazdırır.
