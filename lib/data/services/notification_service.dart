import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import 'local_db_service.dart';
import '../../core/utils/security_utils.dart';

/// In-app notification center. Push notification delivery (via
/// flutter_local_notifications / FCM) hooks into this same model —
/// see backend/README "Notifications" for the production push
/// architecture. Users fully control notification preferences from
/// Settings (never spams by default).
class NotificationService extends ChangeNotifier {
  List<NotificationModel> notificationsFor(String userId) {
    return LocalDbService.notifications.values.where((n) => n.userId == userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  int unreadCountFor(String userId) {
    return notificationsFor(userId).where((n) => !n.isRead).length;
  }

  Future<void> add({
    required String userId,
    required String title,
    required String body,
    String type = 'system',
  }) async {
    final n = NotificationModel(
      id: SecurityUtils.generateId(),
      userId: userId,
      title: title,
      body: body,
      type: type,
    );
    await LocalDbService.notifications.put(n.id, n);
    notifyListeners();
  }

  Future<void> markRead(NotificationModel n) async {
    n.isRead = true;
    await n.save();
    notifyListeners();
  }

  Future<void> markAllRead(String userId) async {
    for (final n in notificationsFor(userId)) {
      n.isRead = true;
      await n.save();
    }
    notifyListeners();
  }
}
