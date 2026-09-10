import 'package:hive/hive.dart';

part 'chat_message_model.g.dart';

@HiveType(typeId: 6)
class ChatMessageModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userId;

  @HiveField(2)
  String text;

  @HiveField(3)
  bool isFromUser;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  List<String> referencedWardrobeItemIds;

  @HiveField(6)
  List<String> referencedShopGapIds;

  ChatMessageModel({
    required this.id,
    required this.userId,
    required this.text,
    required this.isFromUser,
    DateTime? createdAt,
    List<String>? referencedWardrobeItemIds,
    List<String>? referencedShopGapIds,
  })  : createdAt = createdAt ?? DateTime.now(),
        referencedWardrobeItemIds = referencedWardrobeItemIds ?? [],
        referencedShopGapIds = referencedShopGapIds ?? [];
}
