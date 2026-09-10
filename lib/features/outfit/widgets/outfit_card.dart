import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/outfit_model.dart';
import '../../../data/services/wardrobe_service.dart';

class OutfitCard extends StatelessWidget {
  final OutfitModel outfit;
  final VoidCallback onTap;

  const OutfitCard({super.key, required this.outfit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final wardrobeService = context.read<WardrobeService>();
    final previewItems = outfit.items.take(4).toList();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.ivory,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: previewItems.isEmpty
                  ? Container(
                      color: AppColors.sandLight,
                      child: const Center(child: Icon(Icons.checkroom_outlined, color: AppColors.mutedGray)),
                    )
                  : GridView.count(
                      crossAxisCount: 2,
                      physics: const NeverScrollableScrollPhysics(),
                      children: previewItems.map((slot) {
                        final item = wardrobeService.getById(slot.wardrobeItemId);
                        return Container(
                          color: AppColors.sandLight,
                          child: item?.imagePath != null && File(item!.imagePath!).existsSync()
                              ? Image.file(File(item.imagePath!), fit: BoxFit.cover)
                              : const Icon(Icons.checkroom_outlined, size: 18, color: AppColors.mutedGray),
                        );
                      }).toList(),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      outfit.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.label,
                    ),
                  ),
                  if (outfit.isFavorite) const Icon(Icons.favorite, size: 14, color: AppColors.error),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
