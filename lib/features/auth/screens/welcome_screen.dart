import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/auth_service.dart';
import '../../home/screens/home_shell.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _continueAsGuest(BuildContext context) async {
    final auth = context.read<AuthService>();
    await auth.continueAsGuest();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeShell()),
        (route) => false,
      );
    }
  }

  Future<void> _continueWithGoogle(BuildContext context) async {
    // Real production behavior requires GOOGLE_CLIENT_ID configured server
    // side (see backend/.env.example). Here we surface the exact state so
    // this never silently pretends to work without valid credentials.
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Continue with Google'),
        content: const Text(
          'Google Sign-In requires backend OAuth credentials '
          '(GOOGLE_CLIENT_ID/SECRET) to be configured for production. '
          'Use email sign-up to continue in this environment, or connect '
          'your Google account once credentials are configured.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.oliveDark.withValues(alpha: 0.55),
                  AppColors.charcoal,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),
                Text('Stylish', style: AppTextStyles.heroTitle.copyWith(fontSize: 44)),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    "Africa's most trusted personal fashion platform.",
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyLarge.copyWith(color: AppColors.sandLight),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Wear What You Own. Wear It Better.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.sand,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const Spacer(flex: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.ivory,
                          foregroundColor: AppColors.charcoal,
                        ),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        ),
                        child: const Text('Create Account'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.ivory,
                          side: const BorderSide(color: AppColors.ivory),
                        ),
                        onPressed: () => _continueWithGoogle(context),
                        child: const Text('Continue with Google'),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        ),
                        child: Text('Sign In', style: AppTextStyles.button.copyWith(color: AppColors.sand)),
                      ),
                      TextButton(
                        onPressed: () => _continueAsGuest(context),
                        child: Text(
                          'Continue as Guest',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedGray),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
