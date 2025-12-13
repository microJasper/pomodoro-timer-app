import 'package:uuid/uuid.dart';

class PomodoroSession {
  final String id;
  final String categoryName;
  final DateTime startTime;
  final DateTime endTime;
  final int duration;
  final String pomodoroType;
  final bool completed;
  final bool interrupted;

  PomodoroSession({
    String? id,
    required this.categoryName,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.pomodoroType,
    this.completed = false,
    this.interrupted = false,
  }) : id = id ?? const Uuid().v4();

  // Veritabanına kaydetmek için Map'e dönüştür
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryName': categoryName,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'duration': duration,
      'pomodoroType': pomodoroType,
      'completed': completed ? 1 : 0,
      'interrupted': interrupted ? 1 : 0,
    };
  }

  // Veritabanından okumak için Map'ten oluştur
  factory PomodoroSession.fromMap(Map<String, dynamic> map) {
    return PomodoroSession(
      id: map['id'] as String,
      categoryName: map['categoryName'] as String,
      startTime: DateTime.parse(map['startTime'] as String),
      endTime: DateTime.parse(map['endTime'] as String),
      duration: map['duration'] as int,
      pomodoroType: map['pomodoroType'] as String,
      completed: (map['completed'] as int) == 1,
      interrupted: (map['interrupted'] as int) == 1,
    );
  }

  // Haftanın günü (1 = Pazartesi, 7 = Pazar)
  int get dayOfWeek => startTime.weekday;

  // Günün saati (0-23)
  int get hourOfDay => startTime.hour;

  // Kopya oluştur (değişiklikleri uygularken kullanışlı)
  PomodoroSession copyWith({
    String? id,
    String? categoryName,
    DateTime? startTime,
    DateTime? endTime,
    int? duration,
    String? pomodoroType,
    bool? completed,
    bool? interrupted,
  }) {
    return PomodoroSession(
      id: id ?? this.id,
      categoryName: categoryName ?? this.categoryName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      pomodoroType: pomodoroType ?? this.pomodoroType,
      completed: completed ?? this.completed,
      interrupted: interrupted ?? this.interrupted,
    );
  }

  @override
  String toString() {
    return 'PomodoroSession(id: $id, category: $categoryName, type: $pomodoroType, duration: $duration min, completed: $completed)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PomodoroSession && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
