import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class StylishBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const StylishBottomNav({super.key, required this.currentIndex, required this.onTap});

  static const _items = [
    (icon: Icons.home_outlined, activeIcon: Icons.home_filled, label: 'Home'),
    (icon: Icons.checkroom_outlined, activeIcon: Icons.checkroom, label: 'Wardrobe'),
    (icon: Icons.add_circle_outline, activeIcon: Icons.add_circle, label: 'Create'),
    (icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today, label: 'Plan'),
    (icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.ivory,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final selected = index == currentIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        selected ? item.activeIcon : item.icon,
                        color: selected ? AppColors.charcoal : AppColors.mutedGray,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: AppTextStyles.navLabel.copyWith(
                          color: selected ? AppColors.charcoal : AppColors.mutedGray,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
