import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/outfit_service.dart';
import '../../../data/services/plan_service.dart';
import '../../outfit/screens/outfit_builder_screen.dart';

class PlanOutfitScreen extends StatefulWidget {
  final DateTime? date;
  final String? preselectedOutfitId;
  const PlanOutfitScreen({super.key, this.date, this.preselectedOutfitId});

  @override
  State<PlanOutfitScreen> createState() => _PlanOutfitScreenState();
}

class _PlanOutfitScreenState extends State<PlanOutfitScreen> {
  late DateTime _date;
  String? _selectedOutfitId;
  String? _occasion;
  final _notesCtrl = TextEditingController();
  bool _reminder = false;

  @override
  void initState() {
    super.initState();
    _date = widget.date ?? DateTime.now();
    _selectedOutfitId = widget.preselectedOutfitId;
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedOutfitId == null) return;
    final auth = context.read<AuthService>();
    final planService = context.read<PlanService>();
    final user = auth.currentUser!;
    await planService.upsertPlan(
      userId: user.id,
      date: _date,
      outfitId: _selectedOutfitId!,
      occasion: _occasion,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      reminderEnabled: _reminder,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final outfitService = context.watch<OutfitService>();
    final user = auth.currentUser!;
    final outfits = outfitService.outfitsFor(user.id);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Plan Outfit')),
      body: SafeArea(
        child: outfits.isEmpty
            ? EmptyState(
                icon: Icons.checkroom_outlined,
                title: 'No outfits yet.',
                message: 'Create an outfit first, then plan it for a date.',
                actionLabel: 'Create Outfit',
                onAction: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OutfitBuilderScreen()),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text('Date', style: AppTextStyles.label),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime.now().subtract(const Duration(days: 1)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
                    child: Text('${_date.month}/${_date.day}/${_date.year}'),
                  ),
                  const SizedBox(height: 20),
                  Text('Occasion', style: AppTextStyles.label),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppConstants.occasions.map((o) {
                      final selected = _occasion == o;
                      return ChoiceChip(
                        label: Text(o),
                        selected: selected,
                        onSelected: (_) => setState(() => _occasion = selected ? null : o),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Text('Choose outfit', style: AppTextStyles.label),
                  const SizedBox(height: 8),
                  ...outfits.map((o) {
                    final selected = _selectedOutfitId == o.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedOutfitId = o.id),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.oliveSurface : AppColors.ivory,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: selected ? AppColors.olive : AppColors.divider),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                selected ? Icons.check_circle : Icons.checkroom_outlined,
                                color: selected ? AppColors.olive : AppColors.mutedGray,
                              ),
                              const SizedBox(width: 12),
                              Text(o.name, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.charcoal)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(hintText: 'Notes (optional)'),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Remind me'),
                    value: _reminder,
                    onChanged: (v) => setState(() => _reminder = v),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _selectedOutfitId == null ? null : _save,
                    child: const Text('Save Plan'),
                  ),
                ],
              ),
      ),
    );
  }
}
