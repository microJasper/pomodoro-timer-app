import 'package:uuid/uuid.dart';

class Category {
  final String id;
  final String name;
  final String colorHex;
  final bool isDefault;
  final DateTime createdAt;

  Category({
    String? id,
    required this.name,
    required this.colorHex,
    this.isDefault = false,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  // Veritabanına kaydetmek için Map'e dönüştür
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color_hex': colorHex,
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  // Veritabanından okumak için Map'ten oluştur
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      colorHex: map['color_hex'] as String,
      isDefault: (map['is_default'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['created_at'] as int,
      ),
    );
  }

  // Kopya oluştur (güncelleme için)
  Category copyWith({
    String? id,
    String? name,
    String? colorHex,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Renk kodunu Color objesine çevir
  int get colorValue {
    String hex = colorHex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex'; // Alpha channel ekle
    }
    return int.parse(hex, radix: 16);
  }

  @override
  String toString() {
    return 'Category(id: $id, name: $name, color: $colorHex, isDefault: $isDefault)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
