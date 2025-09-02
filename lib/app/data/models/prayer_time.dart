//lib\app\data\models\prayer_time.dart
class PrayerTime {
  final int id;
  final String name;
  final DateTime dateTime;

  PrayerTime({required this.id, required this.name, required this.dateTime});

  // Optional: Add to/from JSON methods for caching
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'dateTime': dateTime.toIso8601String(),
  };

  factory PrayerTime.fromJson(Map<String, dynamic> json) => PrayerTime(
    id: json['id'] as int,
    name: json['name'] as String,
    dateTime: DateTime.parse(json['dateTime'] as String),
  );
}
