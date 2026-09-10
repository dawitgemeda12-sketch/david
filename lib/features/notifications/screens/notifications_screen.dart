import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/notification_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final notifService = context.watch<NotificationService>();
    final user = auth.currentUser!;
    final notifications = notifService.notificationsFor(user.id);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () => notifService.markAllRead(user.id),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: SafeArea(
        child: notifications.isEmpty
            ? const EmptyState(
                icon: Icons.notifications_none_outlined,
                title: 'No notifications yet.',
                message: 'We\'ll let you know about weather tips, planned outfits, and wardrobe gaps.',
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final n = notifications[index];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: n.isRead ? AppColors.ivory : AppColors.oliveSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        Icon(_iconFor(n.type), color: AppColors.oliveDark),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n.title, style: AppTextStyles.label),
                              const SizedBox(height: 2),
                              Text(n.body, style: AppTextStyles.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'weather':
        return Icons.wb_cloudy_outlined;
      case 'plan_reminder':
        return Icons.event_available_outlined;
      case 'gap':
        return Icons.shopping_bag_outlined;
      default:
        return Icons.notifications_none_outlined;
    }
  }
}
