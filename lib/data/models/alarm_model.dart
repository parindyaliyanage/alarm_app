import 'package:hive/hive.dart';

part 'alarm_model.g.dart';

@HiveType(typeId: 0)
class AlarmModel extends HiveObject {

  @HiveField(0)
  final String id;

  @HiveField(1)
  final int hour;

  @HiveField(2)
  final int minute;

  @HiveField(3)
  final String label;

  @HiveField(4)
  final List<bool> repeatDays; // index 0=Mon, 1=Tue ... 6=Sun

  @HiveField(5)
  bool isEnabled;

  @HiveField(6)
  final String challengeType; // 'math' or 'object'

  AlarmModel({
    required this.id,
    required this.hour,
    required this.minute,
    required this.label,
    required this.repeatDays,
    required this.isEnabled,
    required this.challengeType,
  });

  // Human readable time e.g. "07:30"
  String get formattedTime =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  // Copy with modified fields
  AlarmModel copyWith({
    String? id,
    int? hour,
    int? minute,
    String? label,
    List<bool>? repeatDays,
    bool? isEnabled,
    String? challengeType,
  }) {
    return AlarmModel(
      id: id ?? this.id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      label: label ?? this.label,
      repeatDays: repeatDays ?? this.repeatDays,
      isEnabled: isEnabled ?? this.isEnabled,
      challengeType: challengeType ?? this.challengeType,
    );
  }
}