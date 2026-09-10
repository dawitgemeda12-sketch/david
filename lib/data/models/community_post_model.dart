import 'package:hive/hive.dart';

part 'community_post_model.g.dart';

@HiveType(typeId: 7)
class CommunityPostModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userId;

  @HiveField(2)
  String userName;

  @HiveField(3)
  String? userAvatarPath;

  @HiveField(4)
  String? outfitId;

  @HiveField(5)
  String? imagePath;

  @HiveField(6)
  String caption;

  @HiveField(7)
  List<String> likedByUserIds;

  @HiveField(8)
  int commentCount;

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  bool isRemoved; // moderation

  CommunityPostModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatarPath,
    this.outfitId,
    this.imagePath,
    this.caption = '',
    List<String>? likedByUserIds,
    this.commentCount = 0,
    DateTime? createdAt,
    this.isRemoved = false,
  })  : likedByUserIds = likedByUserIds ?? [],
        createdAt = createdAt ?? DateTime.now();
}
