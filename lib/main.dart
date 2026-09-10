import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'data/services/local_db_service.dart';
import 'data/services/auth_service.dart';
import 'data/services/wardrobe_service.dart';
import 'data/services/outfit_service.dart';
import 'data/services/plan_service.dart';
import 'data/services/shop_gap_service.dart';
import 'data/services/stylist_service.dart';
import 'data/services/notification_service.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/home/screens/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDbService.init();
  runApp(const StylishApp());
}

class StylishApp extends StatelessWidget {
  const StylishApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()..restoreSession()),
        ChangeNotifierProvider(create: (_) => WardrobeService()),
        ChangeNotifierProvider(create: (_) => OutfitService()),
        ChangeNotifierProvider(create: (_) => PlanService()),
        ChangeNotifierProvider(create: (_) => ShopGapService()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
        ChangeNotifierProxyProvider2<WardrobeService, ShopGapService, StylistService>(
          create: (ctx) => StylistService(
            wardrobeService: ctx.read<WardrobeService>(),
            shopGapService: ctx.read<ShopGapService>(),
          ),
          update: (ctx, wardrobe, shopGap, previous) =>
              previous ?? StylistService(wardrobeService: wardrobe, shopGapService: shopGap),
        ),
      ],
      child: MaterialApp(
        title: 'Stylish',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const _RootRouter(),
      ),
    );
  }
}

/// Decides whether to show onboarding/auth or the main app shell based
/// on the restored session state.
class _RootRouter extends StatelessWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (auth.isAuthenticated) {
          return const HomeShell();
        }
        return const OnboardingScreen();
      },
    );
  }
}
