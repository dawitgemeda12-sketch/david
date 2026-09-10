import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/screens/welcome_screen.dart';

class _OnboardingPage {
  final String title;
  final String body;
  final IconData icon;
  const _OnboardingPage({required this.title, required this.body, required this.icon});
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      title: 'Stylish',
      body: 'Wear What You Own. Wear It Better.',
      icon: Icons.checkroom,
    ),
    _OnboardingPage(
      title: 'Your wardrobe, organized.',
      body: 'Add what you own and make getting dressed easier.',
      icon: Icons.dashboard_outlined,
    ),
    _OnboardingPage(
      title: 'Your personal stylist.',
      body: 'Get intelligent recommendations based on your wardrobe, occasion, weather, preferences, and lifestyle.',
      icon: Icons.auto_awesome_outlined,
    ),
    _OnboardingPage(
      title: 'Shop the Gap.',
      body: 'Find the pieces that actually complete your wardrobe.',
      icon: Icons.shopping_bag_outlined,
    ),
    _OnboardingPage(
      title: 'Privacy and trust.',
      body: 'You control your wardrobe and personal information. Your photos and data stay private and secure.',
      icon: Icons.verified_user_outlined,
    ),
  ];

  void _next() {
    if (_index == _pages.length - 1) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOut);
    }
  }

  void _skip() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 20, top: 8),
                child: TextButton(
                  onPressed: _skip,
                  child: Text('Skip', style: AppTextStyles.label.copyWith(color: AppColors.mutedGray)),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final page = _pages[i];
                  final isFirst = i == 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 36),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: const BoxDecoration(
                            color: AppColors.sand,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(page.icon, size: 52, color: AppColors.oliveDark),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: isFirst ? AppTextStyles.logo : AppTextStyles.h1,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.body,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyLarge,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final selected = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: selected ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.olive : AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton(
                onPressed: _next,
                child: Text(_index == _pages.length - 1 ? 'Get Started' : 'Continue'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
