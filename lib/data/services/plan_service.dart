import 'package:flutter/foundation.dart';
import '../models/plan_model.dart';
import 'local_db_service.dart';
import '../../core/utils/security_utils.dart';

/// Outfit planning / calendar service.
class PlanService extends ChangeNotifier {
  List<PlanModel> plansFor(String userId) {
    return LocalDbService.plans.values.where((p) => p.userId == userId).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  PlanModel? planForDate(String userId, DateTime date) {
    final target = DateTime(date.year, date.month, date.day);
    for (final p in plansFor(userId)) {
      final d = DateTime(p.date.year, p.date.month, p.date.day);
      if (d == target) return p;
    }
    return null;
  }

  List<PlanModel> upcomingPlans(String userId, {int limit = 5}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return plansFor(userId)
        .where((p) => !p.date.isBefore(today))
        .take(limit)
        .toList();
  }

  Future<PlanModel> upsertPlan({
    required String userId,
    required DateTime date,
    required String outfitId,
    String? occasion,
    String? notes,
    bool reminderEnabled = false,
  }) async {
    final existing = planForDate(userId, date);
    if (existing != null) {
      existing.outfitId = outfitId;
      existing.occasion = occasion;
      existing.notes = notes;
      existing.reminderEnabled = reminderEnabled;
      await existing.save();
      notifyListeners();
      return existing;
    }
    final plan = PlanModel(
      id: SecurityUtils.generateId(),
      userId: userId,
      date: DateTime(date.year, date.month, date.day),
      outfitId: outfitId,
      occasion: occasion,
      notes: notes,
      reminderEnabled: reminderEnabled,
    );
    await LocalDbService.plans.put(plan.id, plan);
    notifyListeners();
    return plan;
  }

  Future<void> deletePlan(String id) async {
    await LocalDbService.plans.delete(id);
    notifyListeners();
  }
}
