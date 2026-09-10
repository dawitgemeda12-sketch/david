import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/outfit_model.dart';
import '../../../data/models/wardrobe_item_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/wardrobe_service.dart';
import '../../../data/services/outfit_service.dart';

/// Interactive outfit builder: pick a wardrobe item per slot
/// (Top, Bottom, Shoes, Outerwear, Bag, Accessories), see completeness,
/// then save as a real outfit made from owned pieces.
class OutfitBuilderScreen extends StatefulWidget {
  final OutfitModel? existingOutfit;
  const OutfitBuilderScreen({super.key, this.existingOutfit});

  @override
  State<OutfitBuilderScreen> createState() => _OutfitBuilderScreenState();
}

class _OutfitBuilderScreenState extends State<OutfitBuilderScreen> {
  final Map<String, String> _slotToItemId = {}; // slot -> wardrobeItemId
  final _nameCtrl = TextEditingController();
  String? _occasion;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingOutfit;
    if (existing != null) {
      _nameCtrl.text = existing.name;
      _occasion = existing.occasion;
      for (final slot in existing.items) {
        _slotToItemId[slot.slot] = slot.wardrobeItemId;
      }
    } else {
      _nameCtrl.text = 'New Outfit';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  double get _completeness {
    const core = ['Top', 'Bottom', 'Shoes'];
    final filled = core.where((s) => _slotToItemId.containsKey(s)).length;
    return filled / core.length;
  }

  Future<void> _pickForSlot(String slot) async {
    final auth = context.read<AuthService>();
    final wardrobeService = context.read<WardrobeService>();
    final user = auth.currentUser!;

    final categoriesForSlot = _categoriesForSlot(slot);
    final options = wardrobeService
        .activeItemsFor(user.id)
        .where((i) => categoriesForSlot.contains(i.category))
        .toList();

    final selected = await showModalBottomSheet<WardrobeItemModel?>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SlotPickerSheet(slot: slot, options: options),
    );

    if (selected != null) {
      setState(() => _slotToItemId[slot] = selected.id);
    }
  }

  List<String> _categoriesForSlot(String slot) {
    switch (slot) {
      case 'Top':
        return ['Tops', 'Shirts', 'T-Shirts', 'Blouses', 'Sweaters', 'Dresses'];
      case 'Bottom':
        return ['Pants', 'Jeans', 'Skirts', 'Shorts'];
      case 'Shoes':
        return ['Shoes'];
      case 'Outerwear':
        return ['Jackets', 'Coats', 'Suits'];
      case 'Bag':
        return ['Bags'];
      case 'Accessories':
        return ['Accessories', 'Traditional'];
      default:
        return AppConstants.categories;
    }
  }

  Future<void> _save() async {
    if (_slotToItemId.isEmpty) return;
    setState(() => _isSaving = true);
    final auth = context.read<AuthService>();
    final outfitService = context.read<OutfitService>();
    final user = auth.currentUser!;

    final slots = _slotToItemId.entries
        .map((e) => OutfitSlot(slot: e.key, wardrobeItemId: e.value))
        .toList();

    if (widget.existingOutfit != null) {
      final outfit = widget.existingOutfit!;
      outfit.name = _nameCtrl.text.trim().isEmpty ? 'Untitled Outfit' : _nameCtrl.text.trim();
      outfit.items = slots;
      outfit.occasion = _occasion;
      await outfitService.updateOutfit(outfit);
    } else {
      await outfitService.createOutfit(
        userId: user.id,
        name: _nameCtrl.text.trim().isEmpty ? 'Untitled Outfit' : _nameCtrl.text.trim(),
        items: slots,
        occasion: _occasion,
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final wardrobeService = context.watch<WardrobeService>();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: TextField(
          controller: _nameCtrl,
          style: AppTextStyles.h3,
          decoration: const InputDecoration(border: InputBorder.none, hintText: 'Outfit name'),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _completeness,
                        minHeight: 8,
                        backgroundColor: AppColors.divider,
                        color: AppColors.olive,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('${(_completeness * 100).round()}% complete', style: AppTextStyles.caption),
                ],
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: AppConstants.occasions.map((o) {
                  final selected = _occasion == o;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(o),
                      selected: selected,
                      onSelected: (_) => setState(() => _occasion = selected ? null : o),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: AppConstants.outfitSlots.map((slot) {
                  final itemId = _slotToItemId[slot];
                  final item = itemId != null ? wardrobeService.getById(itemId) : null;
                  return _SlotTile(
                    slot: slot,
                    item: item,
                    onTap: () => _pickForSlot(slot),
                    onRemove: item == null ? null : () => setState(() => _slotToItemId.remove(slot)),
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: ElevatedButton(
                onPressed: _isSaving || _slotToItemId.isEmpty ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Outfit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotTile extends StatelessWidget {
  final String slot;
  final WardrobeItemModel? item;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _SlotTile({required this.slot, required this.item, required this.onTap, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final String? imgPath = item?.imagePath;
    final bool hasImage = imgPath != null && File(imgPath).existsSync();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.ivory,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.sandLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: hasImage
                    ? Image.file(File(imgPath), fit: BoxFit.cover)
                    : Icon(Icons.add, color: AppColors.mutedGray),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(slot, style: AppTextStyles.caption),
                    const SizedBox(height: 2),
                    Text(
                      item?.name ?? 'Tap to add $slot',
                      style: AppTextStyles.label.copyWith(
                        color: item == null ? AppColors.mutedGray : AppColors.charcoal,
                      ),
                    ),
                  ],
                ),
              ),
              if (onRemove != null)
                IconButton(icon: const Icon(Icons.close, size: 18), onPressed: onRemove),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlotPickerSheet extends StatelessWidget {
  final String slot;
  final List<WardrobeItemModel> options;
  const _SlotPickerSheet({required this.slot, required this.options});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Choose $slot', style: AppTextStyles.h3),
            ),
            Expanded(
              child: options.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'You don\'t have any items for this slot yet. Add some to your wardrobe first.',
                          style: AppTextStyles.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final item = options[index];
                        return GestureDetector(
                          onTap: () => Navigator.of(context).pop(item),
                          child: Column(
                            children: [
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: AppColors.sandLight,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: item.imagePath != null && File(item.imagePath!).existsSync()
                                      ? Image.file(File(item.imagePath!), fit: BoxFit.cover)
                                      : const Icon(Icons.checkroom_outlined, color: AppColors.mutedGray),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
