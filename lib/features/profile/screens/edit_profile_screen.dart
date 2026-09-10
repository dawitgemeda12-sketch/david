import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _budgetCtrl;
  String? _gender;
  String _city = AppConstants.defaultCity;
  final Set<String> _colors = {};

  static const _colorOptions = ['Black', 'White', 'Beige', 'Brown', 'Navy', 'Green', 'Red'];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().currentUser!;
    _nameCtrl = TextEditingController(text: user.name);
    _budgetCtrl = TextEditingController(text: user.monthlyBudget?.toStringAsFixed(0) ?? '');
    _gender = user.gender;
    _city = user.city;
    _colors.addAll(user.favoriteColors);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final auth = context.read<AuthService>();
    await auth.updateProfile((u) {
      u.name = _nameCtrl.text.trim();
      u.gender = _gender;
      u.city = _city;
      u.favoriteColors = _colors.toList();
      final budget = double.tryParse(_budgetCtrl.text.trim());
      u.monthlyBudget = budget;
      return u;
    });
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'Full name')),
            const SizedBox(height: 18),
            Text('Gender', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: AppConstants.genderOptions.map((g) {
                final selected = _gender == g;
                return ChoiceChip(
                  label: Text(g),
                  selected: selected,
                  onSelected: (_) => setState(() => _gender = selected ? null : g),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            Text('City', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: AppConstants.ethiopianCities.map((c) {
                final selected = _city == c;
                return ChoiceChip(
                  label: Text(c),
                  selected: selected,
                  onSelected: (_) => setState(() => _city = c),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            Text('Favorite colors', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colorOptions.map((c) {
                final selected = _colors.contains(c);
                return FilterChip(
                  label: Text(c),
                  selected: selected,
                  onSelected: (v) => setState(() => v ? _colors.add(c) : _colors.remove(c)),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _budgetCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Monthly clothing budget (ETB)'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _save, child: const Text('Save Changes')),
          ],
        ),
      ),
    );
  }
}
