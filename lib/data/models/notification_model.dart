import 'package:hive/hive.dart';

part 'notification_model.g.dart';

@HiveType(typeId: 8)
class NotificationModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userId;

  @HiveField(2)
  String title;

  @HiveField(3)
  String body;

  @HiveField(4)
  String type; // plan_reminder, weather, gap, system

  @HiveField(5)
  bool isRead;

  @HiveField(6)
  DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.type = 'system',
    this.isRead = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
