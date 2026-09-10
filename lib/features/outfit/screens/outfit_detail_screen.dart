import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/outfit_service.dart';
import '../../../data/services/wardrobe_service.dart';
import '../../planner/screens/plan_outfit_screen.dart';
import 'outfit_builder_screen.dart';

class OutfitDetailScreen extends StatelessWidget {
  final String outfitId;
  const OutfitDetailScreen({super.key, required this.outfitId});

  @override
  Widget build(BuildContext context) {
    final outfitService = context.watch<OutfitService>();
    final wardrobeService = context.watch<WardrobeService>();
    final resolved = outfitService.getById(outfitId);

    if (resolved == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Outfit not found.')));
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(resolved.name),
        actions: [
          IconButton(
            icon: Icon(resolved.isFavorite ? Icons.favorite : Icons.favorite_border),
            onPressed: () => outfitService.toggleFavorite(resolved),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => OutfitBuilderScreen(existingOutfit: resolved)),
                );
              } else if (value == 'duplicate') {
                await outfitService.duplicateOutfit(resolved);
                if (context.mounted) Navigator.of(context).pop();
              } else if (value == 'plan') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => PlanOutfitScreen(preselectedOutfitId: resolved.id)),
                );
              } else if (value == 'share') {
                final names = resolved.items
                    .map((s) => wardrobeService.getById(s.wardrobeItemId)?.name)
                    .whereType<String>()
                    .join(', ');
                Share.share('Check out my outfit "${resolved.name}" on Stylish: $names');
              } else if (value == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete outfit?'),
                    content: const Text('This will permanently delete this outfit.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                    ],
                  ),
                );
                if (confirm == true) {
                  await outfitService.deleteOutfit(resolved.id);
                  if (context.mounted) Navigator.of(context).pop();
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
              const PopupMenuItem(value: 'plan', child: Text('Plan this outfit')),
              const PopupMenuItem(value: 'share', child: Text('Share')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (resolved.occasion != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Chip(label: Text(resolved.occasion!)),
              ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.85,
              ),
              itemCount: resolved.items.length,
              itemBuilder: (context, index) {
                final slot = resolved.items[index];
                final item = wardrobeService.getById(slot.wardrobeItemId);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.sandLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.divider),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: item?.imagePath != null && File(item!.imagePath!).existsSync()
                            ? Image.file(File(item.imagePath!), fit: BoxFit.cover)
                            : const Icon(Icons.checkroom_outlined, color: AppColors.mutedGray),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(slot.slot, style: AppTextStyles.caption),
                    Text(item?.name ?? 'Item removed', style: AppTextStyles.label),
                  ],
                );
              },
            ),
            if (resolved.notes != null && resolved.notes!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('Notes', style: AppTextStyles.label),
              const SizedBox(height: 6),
              Text(resolved.notes!, style: AppTextStyles.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }

}
