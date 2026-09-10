import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Privacy & Data')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _Section(
              title: 'What we collect',
              body: 'Your wardrobe photos and details, outfits, plans, style preferences, and account '
                  'information (name, email). Location is only used with your permission for weather '
                  'and local retailer relevance.',
            ),
            _Section(
              title: 'Why we collect it',
              body: 'To organize your digital wardrobe, generate outfit recommendations from clothes you '
                  'actually own, and identify genuinely useful "Shop the Gap" suggestions.',
            ),
            _Section(
              title: 'Image processing',
              body: 'Clothing photos are compressed and stored securely. They are never shared publicly '
                  'unless you choose to post them to the Community.',
            ),
            _Section(
              title: 'AI processing',
              body: 'Style recommendations are generated using your wardrobe data. You can disable AI '
                  'personalization at any time in Settings.',
            ),
            _Section(
              title: 'Storage & retention',
              body: 'Your data is stored securely on your device and, in the connected production '
                  'deployment, on encrypted backend infrastructure. Deleted items are permanently removed.',
            ),
            _Section(
              title: 'Your controls',
              body: 'You can delete individual wardrobe items or outfits at any time, or permanently '
                  'delete your entire account and all associated data from Settings > Delete Account.',
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.h3),
          const SizedBox(height: 6),
          Text(body, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
