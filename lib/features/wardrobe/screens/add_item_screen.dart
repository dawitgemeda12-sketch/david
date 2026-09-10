import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/app_error_banner.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/wardrobe_service.dart';
import '../../../data/services/image_processing_service.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _imagePath;
  String _category = AppConstants.categories.first;
  String? _color;
  String? _formality;
  final Set<String> _occasions = {};
  bool _isProcessingImage = false;
  bool _isSaving = false;
  String? _error;

  final _picker = ImagePicker();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _error = null);
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 90);
      if (picked == null) return;
      setState(() => _isProcessingImage = true);
      final file = File(picked.path);

      final usable = await ImageProcessingService.looksLikeUsablePhoto(file);
      if (!usable) {
        setState(() {
          _isProcessingImage = false;
          _error = "This doesn't look like a clothing item. Please upload a clear photo of clothing.";
        });
        return;
      }

      final storedPath = await ImageProcessingService.processAndStore(file);
      setState(() {
        _imagePath = storedPath;
        _isProcessingImage = false;
      });
    } catch (e) {
      setState(() {
        _isProcessingImage = false;
        _error = e is ImageProcessingException ? e.message : friendlyErrorMessage(e);
      });
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please give this item a name.');
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    final auth = context.read<AuthService>();
    final wardrobeService = context.read<WardrobeService>();
    final user = auth.currentUser!;
    try {
      await wardrobeService.addItem(
        userId: user.id,
        name: _nameCtrl.text.trim(),
        category: _category,
        color: _color,
        formality: _formality,
        occasions: _occasions.toList(),
        brand: _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        imagePath: _imagePath,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _isSaving = false;
        _error = friendlyErrorMessage(e);
      });
    }
  }

  static const _colors = [
    'Black', 'White', 'Beige', 'Brown', 'Navy', 'Blue', 'Green', 'Red', 'Gray', 'Ivory', 'Multi',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Add Clothing')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_error != null) Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AppErrorBanner(message: _error!),
            ),
            _ImagePickerArea(
              imagePath: _imagePath,
              isProcessing: _isProcessingImage,
              onCamera: () => _pickImage(ImageSource.camera),
              onGallery: () => _pickImage(ImageSource.gallery),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(hintText: 'Item name (e.g. Blue Denim Jacket)'),
            ),
            const SizedBox(height: 14),
            Text('Category', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.categories.map((c) {
                final selected = c == _category;
                return _Chip(label: c, selected: selected, onTap: () => setState(() => _category = c));
              }).toList(),
            ),
            const SizedBox(height: 18),
            Text('Color', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colors.map((c) {
                final selected = c == _color;
                return _Chip(label: c, selected: selected, onTap: () => setState(() => _color = selected ? null : c));
              }).toList(),
            ),
            const SizedBox(height: 18),
            Text('Formality', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.formalityLevels.map((f) {
                final selected = f == _formality;
                return _Chip(label: f, selected: selected, onTap: () => setState(() => _formality = selected ? null : f));
              }).toList(),
            ),
            const SizedBox(height: 18),
            Text('Occasions', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.occasions.map((o) {
                final selected = _occasions.contains(o);
                return _Chip(
                  label: o,
                  selected: selected,
                  onTap: () => setState(() {
                    if (selected) {
                      _occasions.remove(o);
                    } else {
                      _occasions.add(o);
                    }
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _brandCtrl,
              decoration: const InputDecoration(hintText: 'Brand (optional)'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Notes (optional)'),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save to Wardrobe'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _ImagePickerArea extends StatelessWidget {
  final String? imagePath;
  final bool isProcessing;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _ImagePickerArea({
    required this.imagePath,
    required this.isProcessing,
    required this.onCamera,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.sandLight,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.divider),
          ),
          clipBehavior: Clip.antiAlias,
          child: isProcessing
              ? const Center(child: CircularProgressIndicator())
              : imagePath != null
                  ? Image.file(File(imagePath!), fit: BoxFit.cover)
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.checkroom_outlined, size: 40, color: AppColors.mutedGray),
                          const SizedBox(height: 8),
                          Text('No photo yet', style: AppTextStyles.bodyMedium),
                        ],
                      ),
                    ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onCamera,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Take Photo'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Choose Photo'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.charcoal : AppColors.ivory,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.charcoal : AppColors.divider),
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(color: selected ? AppColors.ivory : AppColors.charcoal),
        ),
      ),
    );
  }
}
