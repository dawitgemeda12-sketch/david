import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/wardrobe_item_model.dart';

class WardrobeItemCard extends StatelessWidget {
  final WardrobeItemModel item;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;

  const WardrobeItemCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.sandLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: item.imagePath != null && File(item.imagePath!).existsSync()
                      ? Image.file(File(item.imagePath!), fit: BoxFit.cover)
                      : Center(
                          child: Icon(
                            _categoryIcon(item.category),
                            size: 34,
                            color: AppColors.mutedGray,
                          ),
                        ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: onFavoriteToggle,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item.isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 15,
                        color: item.isFavorite ? AppColors.error : AppColors.mutedGray,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.label,
          ),
          Text(
            item.category,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Shoes':
        return Icons.snowshoeing_outlined;
      case 'Bags':
        return Icons.shopping_bag_outlined;
      case 'Accessories':
        return Icons.watch_outlined;
      case 'Dresses':
      case 'Skirts':
        return Icons.checkroom;
      case 'Jackets':
      case 'Coats':
        return Icons.dry_cleaning_outlined;
      default:
        return Icons.checkroom_outlined;
    }
  }
}
