import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/auth_service.dart';
import '../../auth/screens/welcome_screen.dart';
import 'change_password_screen.dart';
import 'privacy_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently deletes your account, wardrobe, outfits, plans, and chat history. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete Account', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final auth = context.read<AuthService>();
    await auth.deleteAccount();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser!;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 8),
            _SectionLabel('Account'),
            if (!user.isGuest)
              _SettingsTile(
                icon: Icons.lock_outline,
                label: 'Change Password',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                ),
              ),
            SwitchListTile(
              title: const Text('Notifications'),
              value: user.notificationsEnabled,
              onChanged: (v) => auth.updateProfile((u) {
                u.notificationsEnabled = v;
                return u;
              }),
              secondary: const Icon(Icons.notifications_none_outlined),
            ),
            SwitchListTile(
              title: const Text('AI Personalization'),
              subtitle: const Text('Allow Stylish to use your wardrobe data for recommendations'),
              value: user.aiPersonalizationEnabled,
              onChanged: (v) => auth.updateProfile((u) {
                u.aiPersonalizationEnabled = v;
                return u;
              }),
              secondary: const Icon(Icons.auto_awesome_outlined),
            ),
            const Divider(),
            _SectionLabel('Privacy'),
            _SettingsTile(
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy & Data',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PrivacyScreen()),
              ),
            ),
            const Divider(),
            _SectionLabel('Preferences'),
            ListTile(
              leading: const Icon(Icons.language_outlined),
              title: const Text('Language'),
              trailing: const Text('English'),
            ),
            ListTile(
              leading: const Icon(Icons.attach_money_outlined),
              title: const Text('Currency'),
              trailing: Text(user.currency),
            ),
            ListTile(
              leading: const Icon(Icons.location_city_outlined),
              title: const Text('Location'),
              trailing: Text(user.city),
            ),
            const Divider(),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
                onPressed: () => _confirmDeleteAccount(context),
                child: const Text('Delete Account'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      child: Text(label, style: AppTextStyles.labelMuted),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SettingsTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
