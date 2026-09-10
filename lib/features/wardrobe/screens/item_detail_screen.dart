import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/wardrobe_service.dart';

class ItemDetailScreen extends StatefulWidget {
  final String itemId;
  const ItemDetailScreen({super.key, required this.itemId});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  bool _editing = false;
  late TextEditingController _nameCtrl;
  late TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wardrobeService = context.watch<WardrobeService>();
    final resolved = wardrobeService.getById(widget.itemId);

    if (resolved == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Item not found.')),
      );
    }

    if (!_editing) {
      _nameCtrl.text = resolved.name;
      _notesCtrl.text = resolved.notes ?? '';
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(resolved.name),
        actions: [
          IconButton(
            icon: Icon(resolved.isFavorite ? Icons.favorite : Icons.favorite_border),
            onPressed: () => wardrobeService.toggleFavorite(resolved),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                setState(() => _editing = true);
              } else if (value == 'archive') {
                await wardrobeService.toggleArchive(resolved);
                if (context.mounted) Navigator.of(context).pop();
              } else if (value == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete item?'),
                    content: const Text('This will permanently remove this item from your wardrobe.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                    ],
                  ),
                );
                if (confirm == true) {
                  await wardrobeService.deleteItem(resolved.id);
                  if (context.mounted) Navigator.of(context).pop();
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'archive', child: Text(resolved.isArchived ? 'Unarchive' : 'Archive')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              height: 260,
              decoration: BoxDecoration(
                color: AppColors.sandLight,
                borderRadius: BorderRadius.circular(18),
              ),
              clipBehavior: Clip.antiAlias,
              child: resolved.imagePath != null && File(resolved.imagePath!).existsSync()
                  ? Image.file(File(resolved.imagePath!), fit: BoxFit.cover)
                  : const Center(child: Icon(Icons.checkroom_outlined, size: 60, color: AppColors.mutedGray)),
            ),
            const SizedBox(height: 20),
            if (_editing) ...[
              TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'Name')),
              const SizedBox(height: 12),
              TextField(controller: _notesCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Notes')),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _editing = false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        resolved.name = _nameCtrl.text.trim();
                        resolved.notes = _notesCtrl.text.trim();
                        await wardrobeService.updateItem(resolved);
                        setState(() => _editing = false);
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              _DetailRow(label: 'Category', value: resolved.category),
              if (resolved.color != null) _DetailRow(label: 'Color', value: resolved.color!),
              if (resolved.formality != null) _DetailRow(label: 'Formality', value: resolved.formality!),
              if (resolved.brand != null) _DetailRow(label: 'Brand', value: resolved.brand!),
              if (resolved.occasions.isNotEmpty)
                _DetailRow(label: 'Occasions', value: resolved.occasions.join(', ')),
              _DetailRow(label: 'Times worn', value: '${resolved.wearCount}'),
              if (resolved.notes != null && resolved.notes!.isNotEmpty)
                _DetailRow(label: 'Notes', value: resolved.notes!),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => wardrobeService.markWorn(resolved),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Mark as worn today'),
              ),
            ],
          ],
        ),
      ),
    );
  }

}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: AppTextStyles.labelMuted)),
          Expanded(child: Text(value, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.charcoal))),
        ],
      ),
    );
  }
}
