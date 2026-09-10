import 'package:flutter/foundation.dart';
import '../models/outfit_model.dart';
import 'local_db_service.dart';
import '../../core/utils/security_utils.dart';

/// Manages outfits composed of real wardrobe items.
class OutfitService extends ChangeNotifier {
  OutfitModel? getById(String id) => LocalDbService.outfits.get(id);

  List<OutfitModel> outfitsFor(String userId) {
    return LocalDbService.outfits.values.where((o) => o.userId == userId).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  List<OutfitModel> favoritesFor(String userId) {
    return outfitsFor(userId).where((o) => o.isFavorite).toList();
  }

  Future<OutfitModel> createOutfit({
    required String userId,
    required String name,
    required List<OutfitSlot> items,
    String? occasion,
    String? weather,
    String? notes,
    String? coverImagePath,
    bool createdByAi = false,
  }) async {
    final outfit = OutfitModel(
      id: SecurityUtils.generateId(),
      userId: userId,
      name: name,
      items: items,
      occasion: occasion,
      weather: weather,
      notes: notes,
      coverImagePath: coverImagePath,
      createdByAi: createdByAi,
    );
    await LocalDbService.outfits.put(outfit.id, outfit);
    notifyListeners();
    return outfit;
  }

  Future<OutfitModel> duplicateOutfit(OutfitModel outfit) async {
    final copy = OutfitModel(
      id: SecurityUtils.generateId(),
      userId: outfit.userId,
      name: '${outfit.name} (Copy)',
      items: outfit.items
          .map((s) => OutfitSlot(slot: s.slot, wardrobeItemId: s.wardrobeItemId))
          .toList(),
      occasion: outfit.occasion,
      weather: outfit.weather,
      notes: outfit.notes,
      coverImagePath: outfit.coverImagePath,
    );
    await LocalDbService.outfits.put(copy.id, copy);
    notifyListeners();
    return copy;
  }

  Future<void> updateOutfit(OutfitModel outfit) async {
    outfit.updatedAt = DateTime.now();
    await outfit.save();
    notifyListeners();
  }

  Future<void> deleteOutfit(String id) async {
    await LocalDbService.outfits.delete(id);
    notifyListeners();
  }

  Future<void> toggleFavorite(OutfitModel outfit) async {
    outfit.isFavorite = !outfit.isFavorite;
    outfit.updatedAt = DateTime.now();
    await outfit.save();
    notifyListeners();
  }

  /// Outfit completeness score (0.0 - 1.0) based on core slot coverage.
  double completeness(OutfitModel outfit) {
    const coreSlots = ['Top', 'Bottom', 'Shoes'];
    final filled = coreSlots.where((s) => outfit.items.any((i) => i.slot == s)).length;
    return filled / coreSlots.length;
  }
}
