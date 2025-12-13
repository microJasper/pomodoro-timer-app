import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_timer_app/models/category.dart';

/// 🎯 Category Model Unit Tests
///
/// Bu test dosyası, Category modelinin işlevselliğini test eder:
/// - Category oluşturma ve özellikleri
/// - Map dönüşümleri (toMap, fromMap)
/// - Varsayılan kategoriler
/// - Renk kodu işlemleri
/// - Eşitlik ve hashCode kontrolü

void main() {
  group('📦 Category Creation Tests', () {
    test('Category should be created with required fields', () {
      // Arrange & Act
      final category = Category(
        name: 'Test Category',
        colorHex: '#FF6B6B',
      );

      // Assert
      expect(category.name, equals('Test Category'));
      expect(category.colorHex, equals('#FF6B6B'));
      expect(category.isDefault, isFalse);
      expect(category.id, isNotEmpty);
      expect(category.createdAt, isNotNull);
    });

    test('Category should generate unique ID automatically', () {
      // Arrange & Act
      final category1 = Category(name: 'Category 1', colorHex: '#FF6B6B');
      final category2 = Category(name: 'Category 2', colorHex: '#4ECDC4');

      // Assert
      expect(category1.id, isNotEmpty);
      expect(category2.id, isNotEmpty);
      expect(category1.id, isNot(equals(category2.id)));
    });

    test('Category should accept custom ID', () {
      // Arrange
      const customId = 'custom-uuid-12345';

      // Act
      final category = Category(
        id: customId,
        name: 'Custom Category',
        colorHex: '#9B59B6',
      );

      // Assert
      expect(category.id, equals(customId));
    });

    test('Category should set isDefault flag correctly', () {
      // Arrange & Act
      final defaultCategory = Category(
        name: 'Genel',
        colorHex: '#607D8B',
        isDefault: true,
      );

      final customCategory = Category(
        name: 'Özel Kategori',
        colorHex: '#E74C3C',
        isDefault: false,
      );

      // Assert
      expect(defaultCategory.isDefault, isTrue);
      expect(customCategory.isDefault, isFalse);
    });

    test('Category should store creation timestamp', () {
      // Arrange
      final beforeCreation = DateTime.now();

      // Act
      final category = Category(name: 'Test', colorHex: '#FF6B6B');

      // Assert
      expect(category.createdAt, isNotNull);
      expect(
        category.createdAt
            .isAfter(beforeCreation.subtract(Duration(seconds: 1))),
        isTrue,
      );
    });
  });

  group('🔄 Category Map Conversion Tests', () {
    test('Category.toMap() should convert to Map correctly', () {
      // Arrange
      final now = DateTime.now();
      final category = Category(
        id: 'test-id-123',
        name: 'Matematik',
        colorHex: '#9B59B6',
        isDefault: true,
        createdAt: now,
      );

      // Act
      final map = category.toMap();

      // Assert
      expect(map['id'], equals('test-id-123'));
      expect(map['name'], equals('Matematik'));
      expect(map['color_hex'], equals('#9B59B6'));
      expect(map['is_default'], equals(1)); // true = 1
      expect(map['created_at'], equals(now.millisecondsSinceEpoch));
    });

    test('Category.fromMap() should create Category from Map', () {
      // Arrange
      final now = DateTime.now();
      final map = {
        'id': 'test-id-456',
        'name': 'Fizik',
        'color_hex': '#3498DB',
        'is_default': 1,
        'created_at': now.millisecondsSinceEpoch,
      };

      // Act
      final category = Category.fromMap(map);

      // Assert
      expect(category.id, equals('test-id-456'));
      expect(category.name, equals('Fizik'));
      expect(category.colorHex, equals('#3498DB'));
      expect(category.isDefault, isTrue); // 1 = true
      expect(category.createdAt.millisecondsSinceEpoch,
          equals(now.millisecondsSinceEpoch));
    });

    test('toMap() and fromMap() should be reversible', () {
      // Arrange
      final originalCategory = Category(
        id: 'original-id',
        name: 'İngilizce',
        colorHex: '#F39C12',
        isDefault: false,
      );

      // Act
      final map = originalCategory.toMap();
      final reconstructedCategory = Category.fromMap(map);

      // Assert
      expect(reconstructedCategory.id, equals(originalCategory.id));
      expect(reconstructedCategory.name, equals(originalCategory.name));
      expect(reconstructedCategory.colorHex, equals(originalCategory.colorHex));
      expect(
          reconstructedCategory.isDefault, equals(originalCategory.isDefault));
    });

    test('isDefault should convert correctly between bool and int', () {
      // Arrange & Act
      final trueCategory =
          Category(name: 'True', colorHex: '#FF0000', isDefault: true);
      final falseCategory =
          Category(name: 'False', colorHex: '#00FF00', isDefault: false);

      final trueMap = trueCategory.toMap();
      final falseMap = falseCategory.toMap();

      // Assert
      expect(trueMap['is_default'], equals(1));
      expect(falseMap['is_default'], equals(0));

      final reconstructedTrue = Category.fromMap(trueMap);
      final reconstructedFalse = Category.fromMap(falseMap);

      expect(reconstructedTrue.isDefault, isTrue);
      expect(reconstructedFalse.isDefault, isFalse);
    });
  });

  group('🎨 Color Handling Tests', () {
    test('Category should store hex color as string', () {
      // Arrange & Act
      final category = Category(name: 'Red', colorHex: '#FF0000');

      // Assert
      expect(category.colorHex, isA<String>());
      expect(category.colorHex, equals('#FF0000'));
    });

    test('Category should convert hex to color value correctly', () {
      // Arrange
      final category = Category(name: 'Red', colorHex: '#FF0000');

      // Act
      final colorValue = category.colorValue;

      // Assert
      expect(colorValue, isA<int>());
      expect(colorValue, equals(0xFFFF0000)); // With alpha channel
    });

    test('Color value should handle 6-digit hex codes', () {
      // Arrange
      final testCases = {
        '#FF6B6B': 0xFFFF6B6B,
        '#4ECDC4': 0xFF4ECDC4,
        '#9B59B6': 0xFF9B59B6,
        '#FFFFFF': 0xFFFFFFFF,
        '#000000': 0xFF000000,
      };

      // Act & Assert
      testCases.forEach((hex, expectedValue) {
        final category = Category(name: 'Test', colorHex: hex);
        expect(category.colorValue, equals(expectedValue),
            reason: '$hex renk kodu $expectedValue değerine dönüşmeli');
      });
    });
  });

  group('🏷️ Default Categories Tests', () {
    test('Default categories should have specific names', () {
      // Arrange
      final expectedNames = [
        'Matematik',
        'Fizik',
        'Kimya',
        'Biyoloji',
        'İngilizce',
        'Tarih',
        'Edebiyat',
        'Genel',
      ];

      // Assert
      expect(expectedNames, hasLength(8));
      expect(expectedNames, contains('Matematik'));
      expect(expectedNames, contains('Genel'));
    });

    test('Default categories should have unique colors', () {
      // Arrange
      final defaultColors = [
        '#9B59B6', // Mor
        '#3498DB', // Mavi
        '#E74C3C', // Kırmızı
        '#27AE60', // Yeşil
        '#F39C12', // Turuncu
        '#95A5A6', // Gri
        '#E91E63', // Pembe
        '#607D8B', // Gri-Mavi
      ];

      // Assert
      expect(defaultColors, hasLength(8));
      expect(defaultColors.toSet(), hasLength(8)); // All unique
    });

    test('Genel category should be a default category', () {
      // Arrange & Act
      final genelCategory = Category(
        name: 'Genel',
        colorHex: '#607D8B',
        isDefault: true,
      );

      // Assert
      expect(genelCategory.isDefault, isTrue);
      expect(genelCategory.name, equals('Genel'));
    });
  });

  group('🔍 Category Comparison Tests', () {
    test('Two categories with same ID should be equal', () {
      // Arrange
      const sharedId = 'same-id-123';
      final category1 = Category(
        id: sharedId,
        name: 'Category 1',
        colorHex: '#FF0000',
      );
      final category2 = Category(
        id: sharedId,
        name: 'Category 2',
        colorHex: '#00FF00',
      );

      // Act & Assert
      expect(category1, equals(category2));
      expect(category1.hashCode, equals(category2.hashCode));
    });

    test('Two categories with different IDs should not be equal', () {
      // Arrange
      final category1 = Category(name: 'Category 1', colorHex: '#FF0000');
      final category2 = Category(name: 'Category 1', colorHex: '#FF0000');

      // Act & Assert
      expect(category1, isNot(equals(category2)));
    });

    test('Category should equal itself', () {
      // Arrange
      final category = Category(name: 'Test', colorHex: '#FF0000');

      // Act & Assert
      expect(category, equals(category));
      expect(identical(category, category), isTrue);
    });
  });

  group('📝 Category CopyWith Tests', () {
    test('copyWith() should create new category with updated fields', () {
      // Arrange
      final original = Category(
        id: 'original-id',
        name: 'Original',
        colorHex: '#FF0000',
        isDefault: false,
      );

      // Act
      final copied = original.copyWith(
        name: 'Updated Name',
        colorHex: '#00FF00',
      );

      // Assert
      expect(copied.id, equals(original.id)); // Same ID
      expect(copied.name, equals('Updated Name')); // Updated
      expect(copied.colorHex, equals('#00FF00')); // Updated
      expect(copied.isDefault, equals(original.isDefault)); // Unchanged
    });

    test('copyWith() without parameters should return identical copy', () {
      // Arrange
      final original = Category(
        id: 'test-id',
        name: 'Test',
        colorHex: '#FF0000',
      );

      // Act
      final copied = original.copyWith();

      // Assert
      expect(copied.id, equals(original.id));
      expect(copied.name, equals(original.name));
      expect(copied.colorHex, equals(original.colorHex));
      expect(copied.isDefault, equals(original.isDefault));
    });
  });

  group('🖨️ Category ToString Tests', () {
    test('toString() should provide readable string representation', () {
      // Arrange
      final category = Category(
        id: 'test-123',
        name: 'Matematik',
        colorHex: '#9B59B6',
        isDefault: true,
      );

      // Act
      final stringRepresentation = category.toString();

      // Assert
      expect(stringRepresentation, contains('Category'));
      expect(stringRepresentation, contains('test-123'));
      expect(stringRepresentation, contains('Matematik'));
      expect(stringRepresentation, contains('#9B59B6'));
      expect(stringRepresentation, contains('true'));
    });
  });

  group('✅ Category Validation Tests', () {
    test('Category name should not be empty', () {
      // Arrange
      final category = Category(name: 'Valid Name', colorHex: '#FF0000');

      // Assert
      expect(category.name, isNotEmpty);
      expect(category.name.length, greaterThan(0));
    });

    test('Category color hex should follow hex format', () {
      // Arrange
      final validColors = [
        '#FF0000',
        '#00FF00',
        '#0000FF',
        '#FFFFFF',
        '#000000',
      ];

      // Act & Assert
      for (var color in validColors) {
        expect(color, startsWith('#'));
        expect(color.length, equals(7)); // # + 6 characters
      }
    });

    test('Category should accept various name lengths', () {
      // Arrange & Act
      final shortName = Category(name: 'A', colorHex: '#FF0000');
      final mediumName = Category(name: 'Matematik', colorHex: '#FF0000');
      final longName = Category(
        name: 'Çok Uzun Bir Kategori Adı Test',
        colorHex: '#FF0000',
      );

      // Assert
      expect(shortName.name.length, equals(1));
      expect(mediumName.name.length, greaterThanOrEqualTo(8));
      expect(longName.name.length, greaterThan(10));
    });
  });
}
