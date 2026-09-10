import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/wardrobe_service.dart';
import '../../../data/services/shop_gap_service.dart';
import '../../../data/models/shop_gap_model.dart';

/// "Shop the Gap" — Stylish's key differentiator. Presents only real,
/// wardrobe-gap-driven product suggestions with transparent retailer,
/// price (ETB), and availability info. Never invents prices/retailers.
class ShopGapScreen extends StatefulWidget {
  const ShopGapScreen({super.key});

  @override
  State<ShopGapScreen> createState() => _ShopGapScreenState();
}

class _ShopGapScreenState extends State<ShopGapScreen> {
  bool _loading = true;
  List<ShopGapProductModel> _suggestions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _analyze());
  }

  Future<void> _analyze() async {
    final auth = context.read<AuthService>();
    final wardrobeService = context.read<WardrobeService>();
    final shopGapService = context.read<ShopGapService>();
    final user = auth.currentUser!;
    final wardrobe = wardrobeService.activeItemsFor(user.id);
    final results = await shopGapService.analyzeAndSuggest(userId: user.id, wardrobe: wardrobe);
    if (!mounted) return;
    setState(() {
      _suggestions = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Shop the Gap')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _analyze,
                child: _suggestions.isEmpty
                    ? EmptyState(
                        icon: Icons.checkroom_outlined,
                        title: 'Your wardrobe is well covered.',
                        message: 'Add more items so Stylish can spot new gaps.',
                      )
                    : ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          Text(
                            'You\'re almost there!',
                            style: AppTextStyles.h1,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'These items will complete your look.',
                            style: AppTextStyles.bodyMedium,
                          ),
                          const SizedBox(height: 20),
                          ..._suggestions.map((p) => _GapProductTile(product: p)),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.sandLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, size: 18, color: AppColors.mutedGray),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Prices and availability reflect our Ethiopian retailer catalog and may change. Live retailer integration is coming soon.',
                                    style: AppTextStyles.caption,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
      ),
    );
  }
}

class _GapProductTile extends StatelessWidget {
  final ShopGapProductModel product;
  const _GapProductTile({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.ivory,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: AppColors.sandLight, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.checkroom_outlined, color: AppColors.mutedGray),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.productName, style: AppTextStyles.label),
                const SizedBox(height: 4),
                Text(
                  '${product.retailerName} · ${product.city}',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 6),
                Text(
                  product.gapReason,
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${product.price.toStringAsFixed(0)} ${product.currency}',
                      style: AppTextStyles.h3,
                    ),
                    const Spacer(),
                    if (product.isAvailable)
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(minimumSize: const Size(72, 34), padding: EdgeInsets.zero),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Live retailer checkout is coming soon.')),
                          );
                        },
                        child: const Text('View'),
                      )
                    else
                      Text('Unavailable', style: AppTextStyles.caption.copyWith(color: AppColors.error)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
