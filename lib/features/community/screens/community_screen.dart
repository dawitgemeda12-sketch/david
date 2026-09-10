import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/community_feed.dart';

/// Foundation for the Stylish community: outfit sharing, likes, and
/// moderation (report/block). Kept secondary to the core wardrobe
/// experience per product philosophy.
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  int _tabIndex = 0;
  static const _tabs = ['For You', 'Following', 'Local', 'Trends'];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser!;
    final posts = CommunityFeed.posts();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Community')),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _tabs.length,
                itemBuilder: (context, i) {
                  final selected = i == _tabIndex;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      label: Text(_tabs[i]),
                      selected: selected,
                      onSelected: (_) => setState(() => _tabIndex = i),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: posts.isEmpty
                  ? EmptyState(
                      icon: Icons.groups_outlined,
                      title: 'Community is just getting started.',
                      message: 'Share one of your outfits to be among the first voices here.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        final liked = post.likedByUserIds.contains(user.id);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.ivory,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(radius: 16, backgroundColor: AppColors.sand, child: Text(post.userName[0])),
                                  const SizedBox(width: 10),
                                  Text(post.userName, style: AppTextStyles.label),
                                  const Spacer(),
                                  PopupMenuButton<String>(
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(value: 'report', child: Text('Report')),
                                      PopupMenuItem(value: 'block', child: Text('Block user')),
                                    ],
                                    onSelected: (v) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(v == 'report' ? 'Post reported. Our team will review it.' : 'User blocked.')),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                height: 160,
                                decoration: BoxDecoration(color: AppColors.sandLight, borderRadius: BorderRadius.circular(12)),
                                alignment: Alignment.center,
                                child: const Icon(Icons.checkroom_outlined, size: 40, color: AppColors.mutedGray),
                              ),
                              const SizedBox(height: 10),
                              Text(post.caption, style: AppTextStyles.bodyMedium),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(liked ? Icons.favorite : Icons.favorite_border, size: 18, color: liked ? AppColors.error : AppColors.mutedGray),
                                    onPressed: () => setState(() => CommunityFeed.toggleLike(post.id, user.id)),
                                  ),
                                  Text('${post.likedByUserIds.length}', style: AppTextStyles.bodySmall),
                                  const SizedBox(width: 16),
                                  const Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.mutedGray),
                                  const SizedBox(width: 6),
                                  Text('${post.commentCount}', style: AppTextStyles.bodySmall),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
