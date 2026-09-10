import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/outfit_service.dart';
import 'outfit_builder_screen.dart';
import 'outfit_detail_screen.dart';
import '../widgets/outfit_card.dart';

/// The "Create" tab: launch point for building new outfits and browsing
/// saved outfits — the primary creative surface of Stylish.
class CreateHubScreen extends StatelessWidget {
  const CreateHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final outfitService = context.watch<OutfitService>();
    final user = auth.currentUser!;
    final outfits = outfitService.outfitsFor(user.id);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  Expanded(child: Text('My Outfits', style: AppTextStyles.h1)),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const OutfitBuilderScreen()),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: outfits.isEmpty
                  ? EmptyState(
                      icon: Icons.dashboard_customize_outlined,
                      title: 'Create your first outfit.',
                      message: 'Combine pieces you already own into a look you\'ll love.',
                      actionLabel: 'Create Outfit',
                      onAction: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const OutfitBuilderScreen()),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.78,
                      ),
                      itemCount: outfits.length,
                      itemBuilder: (context, index) {
                        final outfit = outfits[index];
                        return OutfitCard(
                          outfit: outfit,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => OutfitDetailScreen(outfitId: outfit.id)),
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
