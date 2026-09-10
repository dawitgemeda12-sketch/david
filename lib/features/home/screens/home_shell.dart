import 'package:flutter/material.dart';
import '../../../core/widgets/stylish_bottom_nav.dart';
import 'home_screen.dart';
import '../../wardrobe/screens/wardrobe_screen.dart';
import '../../outfit/screens/create_hub_screen.dart';
import '../../planner/screens/planner_screen.dart';
import '../../profile/screens/profile_screen.dart';

/// Root navigation shell hosting the 5 primary tabs: Home, Wardrobe,
/// Create, Plan, Profile — every tab is a fully functional screen.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void goToTab(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onNavigateTab: goToTab),
      const WardrobeScreen(),
      const CreateHubScreen(),
      const PlannerScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: StylishBottomNav(currentIndex: _index, onTap: goToTab),
    );
  }
}
