import 'package:hive/hive.dart';

part 'plan_model.g.dart';

@HiveType(typeId: 4)
class PlanModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userId;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  String outfitId;

  @HiveField(4)
  String? occasion;

  @HiveField(5)
  String? notes;

  @HiveField(6)
  bool reminderEnabled;

  @HiveField(7)
  DateTime createdAt;

  PlanModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.outfitId,
    this.occasion,
    this.notes,
    this.reminderEnabled = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
