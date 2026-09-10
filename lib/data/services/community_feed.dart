import '../models/community_post_model.dart';
import 'local_db_service.dart';

/// Simple accessor for the community post box — real persisted data,
/// intentionally empty by default (no fake seeded posts).
class CommunityFeed {
  CommunityFeed._();

  static List<CommunityPostModel> posts() {
    return LocalDbService.community.values.where((p) => !p.isRemoved).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<void> toggleLike(String postId, String userId) async {
    final post = LocalDbService.community.get(postId);
    if (post == null) return;
    if (post.likedByUserIds.contains(userId)) {
      post.likedByUserIds.remove(userId);
    } else {
      post.likedByUserIds.add(userId);
    }
    await post.save();
  }
}
