import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/wardrobe_service.dart';
import '../widgets/wardrobe_item_card.dart';
import 'add_item_screen.dart';
import 'item_detail_screen.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  final _searchCtrl = TextEditingController();
  String _category = 'All';
  bool _favoritesOnly = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final wardrobeService = context.watch<WardrobeService>();
    final user = auth.currentUser!;

    final items = wardrobeService.search(
      userId: user.id,
      query: _searchCtrl.text,
      category: _category,
      favoritesOnly: _favoritesOnly,
    );
    final allActive = wardrobeService.activeItemsFor(user.id);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  Expanded(child: Text('My Wardrobe', style: AppTextStyles.h1)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AddItemScreen()),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Search your wardrobe',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _category == 'All',
                    onTap: () => setState(() => _category = 'All'),
                  ),
                  ..._relevantCategories(allActive).map((c) => _FilterChip(
                        label: c,
                        selected: _category == c,
                        onTap: () => setState(() => _category = c),
                      )),
                  _FilterChip(
                    label: 'Favorites',
                    icon: Icons.favorite,
                    selected: _favoritesOnly,
                    onTap: () => setState(() => _favoritesOnly = !_favoritesOnly),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: allActive.isEmpty
                  ? EmptyState(
                      icon: Icons.checkroom_outlined,
                      title: 'Your wardrobe starts here.',
                      message: 'Add your first item and start building your digital closet.',
                      actionLabel: 'Add Clothing',
                      onAction: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AddItemScreen()),
                      ),
                    )
                  : items.isEmpty
                      ? EmptyState(
                          icon: Icons.search_off,
                          title: 'No matches found',
                          message: 'Try a different search term or filter.',
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return WardrobeItemCard(
                              item: item,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: item.id)),
                              ),
                              onFavoriteToggle: () => wardrobeService.toggleFavorite(item),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _relevantCategories(List items) {
    final present = <String>{};
    for (final i in items) {
      present.add(i.category as String);
    }
    return AppConstants.categories.where((c) => present.contains(c)).toList();
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  const _FilterChip({required this.label, required this.selected, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.charcoal : AppColors.sandLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              if (icon != null) Icon(icon, size: 14, color: selected ? AppColors.ivory : AppColors.mutedGray),
              if (icon != null) const SizedBox(width: 4),
              Text(
                label,
                style: AppTextStyles.label.copyWith(
                  color: selected ? AppColors.ivory : AppColors.charcoal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
