import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/wardrobe_service.dart';
import '../../../data/services/outfit_service.dart';
import '../../../data/services/image_processing_service.dart';
import '../../auth/screens/welcome_screen.dart';
import '../../shopgap/screens/shop_gap_screen.dart';
import '../../community/screens/community_screen.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _changeAvatar(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked == null) return;
    try {
      final path = await ImageProcessingService.processAndStore(File(picked.path));
      final auth = context.read<AuthService>();
      await auth.updateProfile((u) {
        u.profileImagePath = path;
        return u;
      });
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('We couldn\'t update your photo. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final wardrobeService = context.watch<WardrobeService>();
    final outfitService = context.watch<OutfitService>();
    final user = auth.currentUser!;
    final wardrobeCount = wardrobeService.activeItemsFor(user.id).length;
    final outfitCount = outfitService.outfitsFor(user.id).length;
    final favoriteCount = wardrobeService.favoritesFor(user.id).length;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: user.isGuest ? null : () => _changeAvatar(context),
                  child: CircleAvatar(
                    radius: 34,
                    backgroundColor: AppColors.sand,
                    backgroundImage: user.profileImagePath != null
                        ? FileImage(File(user.profileImagePath!))
                        : null,
                    child: user.profileImagePath == null
                        ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'S', style: AppTextStyles.h1)
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.isGuest ? 'Guest' : user.name, style: AppTextStyles.h2),
                      if (!user.isGuest) Text(user.email, style: AppTextStyles.bodySmall),
                      if (user.isGuest)
                        Text('Create an account to save your wardrobe permanently.', style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                if (!user.isGuest)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _StatChip(label: 'Items', value: '$wardrobeCount'),
                const SizedBox(width: 12),
                _StatChip(label: 'Outfits', value: '$outfitCount'),
                const SizedBox(width: 12),
                _StatChip(label: 'Favorites', value: '$favoriteCount'),
              ],
            ),
            const SizedBox(height: 28),
            _ProfileTile(
              icon: Icons.shopping_bag_outlined,
              label: 'Shop the Gap',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShopGapScreen())),
            ),
            _ProfileTile(
              icon: Icons.groups_outlined,
              label: 'Community',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CommunityScreen())),
            ),
            _ProfileTile(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () async {
                await auth.logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (route) => false,
                  );
                }
              },
              child: const Text('Log Out'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.ivory,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Text(value, style: AppTextStyles.h2),
            Text(label, style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ProfileTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.ivory,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.oliveDark),
                const SizedBox(width: 14),
                Expanded(child: Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.charcoal))),
                const Icon(Icons.chevron_right, color: AppColors.mutedGray),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
