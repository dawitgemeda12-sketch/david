import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/wardrobe_service.dart';
import '../../../data/services/outfit_service.dart';
import '../../../data/services/plan_service.dart';
import '../../../data/services/shop_gap_service.dart';
import '../../../data/services/stylist_service.dart';
import '../../../data/services/notification_service.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../wardrobe/screens/add_item_screen.dart';
import '../../outfit/screens/outfit_builder_screen.dart';
import '../../stylist/screens/ai_stylist_screen.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int tabIndex) onNavigateTab;
  const HomeScreen({super.key, required this.onNavigateTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _weatherTip;
  bool _loadingTip = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWeatherTip());
  }

  Future<void> _loadWeatherTip() async {
    final auth = context.read<AuthService>();
    final wardrobeService = context.read<WardrobeService>();
    final stylist = context.read<StylistService>();
    final user = auth.currentUser;
    if (user == null) return;
    final wardrobe = wardrobeService.activeItemsFor(user.id);
    final tip = await stylist.weatherTip(city: user.city, wardrobe: wardrobe);
    if (!mounted) return;
    setState(() {
      _weatherTip = tip;
      _loadingTip = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final wardrobeService = context.watch<WardrobeService>();
    final outfitService = context.watch<OutfitService>();
    final planService = context.watch<PlanService>();
    final shopGapService = context.watch<ShopGapService>();
    final notifService = context.watch<NotificationService>();

    final user = auth.currentUser!;
    final wardrobe = wardrobeService.activeItemsFor(user.id);
    final outfits = outfitService.outfitsFor(user.id);
    final favoriteOutfit = outfits.where((o) => o.isFavorite).isNotEmpty
        ? outfits.where((o) => o.isFavorite).first
        : null;
    final recentOutfit = outfits.isNotEmpty ? outfits.first : null;
    final upcomingPlans = planService.upcomingPlans(user.id, limit: 1);
    final unread = notifService.unreadCountFor(user.id);
    final insight = shopGapService.wardrobeInsight(wardrobe);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadWeatherTip,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Stylish', style: AppTextStyles.logo.copyWith(fontSize: 24)),
                          Text(
                            'Hi ${user.name.split(' ').first.isEmpty ? 'there' : user.name.split(' ').first},',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                      ),
                      icon: Badge(
                        isLabelVisible: unread > 0,
                        label: Text('$unread'),
                        child: const Icon(Icons.notifications_none_rounded),
                      ),
                    ),
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.sand,
                      backgroundImage: user.profileImagePath != null
                          ? FileImage(File(user.profileImagePath!))
                          : null,
                      child: user.profileImagePath == null
                          ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'S')
                          : null,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Text('Your wardrobe. Your style.', style: AppTextStyles.h1),
              ),
              const SizedBox(height: 16),

              // Weather tip banner
              if (!_loadingTip && _weatherTip != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.oliveSurface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.wb_cloudy_outlined, color: AppColors.oliveDark),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(_weatherTip!, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.charcoal)),
                      ),
                    ],
                  ),
                ),
              if (!_loadingTip && _weatherTip != null) const SizedBox(height: 16),

              // Stats row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _StatCard(label: 'Wardrobe items', value: '${wardrobe.length}'),
                    const SizedBox(width: 12),
                    _StatCard(label: 'Saved outfits', value: '${outfits.length}'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Quick actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Quick actions', style: AppTextStyles.h3),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 96,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _QuickAction(
                      icon: Icons.add_a_photo_outlined,
                      label: 'Add Clothing',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AddItemScreen()),
                      ),
                    ),
                    _QuickAction(
                      icon: Icons.dashboard_customize_outlined,
                      label: 'Create Outfit',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const OutfitBuilderScreen()),
                      ),
                    ),
                    _QuickAction(
                      icon: Icons.event_available_outlined,
                      label: 'Plan Outfit',
                      onTap: () => widget.onNavigateTab(3),
                    ),
                    _QuickAction(
                      icon: Icons.auto_awesome_outlined,
                      label: 'Ask Stylish',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AiStylistScreen()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Wardrobe insight
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.ivory,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.insights_outlined, color: AppColors.olive),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Wardrobe insight', style: AppTextStyles.label),
                            const SizedBox(height: 4),
                            Text(insight, style: AppTextStyles.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Upcoming plan
              if (upcomingPlans.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Upcoming plan', style: AppTextStyles.h3),
                      TextButton(
                        onPressed: () => widget.onNavigateTab(3),
                        child: const Text('View planner'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.sandLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_outlined, color: AppColors.oliveDark),
                        const SizedBox(width: 12),
                        Text(
                          '${_formatDate(upcomingPlans.first.date)} — ${upcomingPlans.first.occasion ?? 'Planned outfit'}',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.charcoal),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              if (favoriteOutfit != null || recentOutfit != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Recent activity', style: AppTextStyles.h3),
                ),
              if (recentOutfit != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Text(
                    'Recent outfit: ${recentOutfit.name} (${recentOutfit.items.length} pieces)',
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              if (favoriteOutfit != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Text(
                    'Favorite outfit: ${favoriteOutfit.name}',
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[date.weekday - 1]}, ${date.day}/${date.month}';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.ivory,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: AppTextStyles.h1),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 92,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.ivory,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.oliveDark),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(color: AppColors.charcoal, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
