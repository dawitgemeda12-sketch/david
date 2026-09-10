import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/plan_service.dart';
import '../../../data/services/outfit_service.dart';
import 'plan_outfit_screen.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  DateTime _weekStart = _startOfWeek(DateTime.now());
  DateTime _selectedDate = DateTime.now();

  static DateTime _startOfWeek(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final planService = context.watch<PlanService>();
    final outfitService = context.watch<OutfitService>();
    final user = auth.currentUser!;

    final weekDays = List.generate(7, (i) => _weekStart.add(Duration(days: i)));
    final planForSelected = planService.planForDate(user.id, _selectedDate);
    final outfitForSelected = planForSelected != null ? outfitService.getById(planForSelected.outfitId) : null;
    final upcoming = planService.upcomingPlans(user.id, limit: 10);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  Expanded(child: Text('Plan', style: AppTextStyles.h1)),
                  IconButton(
                    icon: const Icon(Icons.today_outlined),
                    onPressed: () => setState(() {
                      _selectedDate = DateTime.now();
                      _weekStart = _startOfWeek(DateTime.now());
                    }),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7))),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: weekDays.map((d) {
                      final selected = _isSameDay(d, _selectedDate);
                      final hasPlan = planService.planForDate(user.id, d) != null;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedDate = d),
                        child: Column(
                          children: [
                            Text(_weekdayLabel(d.weekday), style: AppTextStyles.caption),
                            const SizedBox(height: 6),
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: selected ? AppColors.charcoal : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${d.day}',
                                style: AppTextStyles.label.copyWith(
                                  color: selected ? AppColors.ivory : AppColors.charcoal,
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: hasPlan ? AppColors.olive : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(() => _weekStart = _weekStart.add(const Duration(days: 7))),
                ),
              ],
            ),
            const Divider(height: 24),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  Text(_formatFullDate(_selectedDate), style: AppTextStyles.h3),
                  const SizedBox(height: 12),
                  if (outfitForSelected != null)
                    _PlannedOutfitTile(
                      occasion: planForSelected?.occasion,
                      outfitName: outfitForSelected.name,
                      onEdit: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => PlanOutfitScreen(date: _selectedDate)),
                      ),
                      onDelete: () async {
                        await planService.deletePlan(planForSelected!.id);
                      },
                    )
                  else
                    Column(
                      children: [
                        const SizedBox(height: 12),
                        EmptyState(
                          icon: Icons.event_available_outlined,
                          title: 'Nothing planned yet.',
                          message: 'Plan tomorrow\'s look in seconds.',
                          actionLabel: 'Plan Outfit',
                          onAction: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => PlanOutfitScreen(date: _selectedDate)),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  if (upcoming.isNotEmpty) ...[
                    Text('Upcoming', style: AppTextStyles.h3),
                    const SizedBox(height: 10),
                    ...upcoming.map((p) {
                      final outfit = outfitService.getById(p.outfitId);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.ivory,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(color: AppColors.sandLight, borderRadius: BorderRadius.circular(10)),
                              alignment: Alignment.center,
                              child: Text('${p.date.day}', style: AppTextStyles.label),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.occasion ?? 'Planned outfit', style: AppTextStyles.label),
                                  Text(outfit?.name ?? 'Outfit removed', style: AppTextStyles.bodySmall),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  String _weekdayLabel(int weekday) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return labels[weekday - 1];
  }

  String _formatFullDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _PlannedOutfitTile extends StatelessWidget {
  final String? occasion;
  final String outfitName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PlannedOutfitTile({
    required this.occasion,
    required this.outfitName,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.ivory,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.checkroom, color: AppColors.oliveDark),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(occasion ?? 'Planned outfit', style: AppTextStyles.label),
                Text(outfitName, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: onEdit),
          IconButton(icon: const Icon(Icons.delete_outline, size: 18), onPressed: onDelete),
        ],
      ),
    );
  }
}
