import 'package:flutter/foundation.dart';
import '../models/wardrobe_item_model.dart';
import 'local_db_service.dart';
import '../../core/utils/security_utils.dart';

/// Manages the user's digital wardrobe: create, edit, delete, archive,
/// favorite, search, filter, sort, tag. All data is scoped per user —
/// callers must always pass the authenticated userId; never trust a
/// client-supplied ID from anywhere outside the AuthService session.
class WardrobeService extends ChangeNotifier {
  WardrobeItemModel? getById(String id) => LocalDbService.wardrobe.get(id);

  List<WardrobeItemModel> itemsFor(String userId) {
    return LocalDbService.wardrobe.values.where((i) => i.userId == userId).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  List<WardrobeItemModel> activeItemsFor(String userId) {
    return itemsFor(userId).where((i) => !i.isArchived).toList();
  }

  List<WardrobeItemModel> favoritesFor(String userId) {
    return activeItemsFor(userId).where((i) => i.isFavorite).toList();
  }

  Future<WardrobeItemModel> addItem({
    required String userId,
    required String name,
    required String category,
    String? subcategory,
    String? color,
    String? secondaryColor,
    String? pattern,
    String? material,
    String? style,
    List<String>? seasons,
    List<String>? occasions,
    String? formality,
    String? brand,
    String? size,
    DateTime? purchaseDate,
    double? purchasePrice,
    String? condition,
    String? notes,
    String? imagePath,
    List<String>? tags,
  }) async {
    final item = WardrobeItemModel(
      id: SecurityUtils.generateId(),
      userId: userId,
      name: name,
      category: category,
      subcategory: subcategory,
      color: color,
      secondaryColor: secondaryColor,
      pattern: pattern,
      material: material,
      style: style,
      seasons: seasons,
      occasions: occasions,
      formality: formality,
      brand: brand,
      size: size,
      purchaseDate: purchaseDate,
      purchasePrice: purchasePrice,
      condition: condition,
      notes: notes,
      imagePath: imagePath,
      tags: tags,
    );
    await LocalDbService.wardrobe.put(item.id, item);
    notifyListeners();
    return item;
  }

  Future<void> updateItem(WardrobeItemModel item) async {
    item.updatedAt = DateTime.now();
    await item.save();
    notifyListeners();
  }

  Future<void> deleteItem(String id) async {
    await LocalDbService.wardrobe.delete(id);
    notifyListeners();
  }

  Future<void> toggleArchive(WardrobeItemModel item) async {
    item.isArchived = !item.isArchived;
    item.updatedAt = DateTime.now();
    await item.save();
    notifyListeners();
  }

  Future<void> toggleFavorite(WardrobeItemModel item) async {
    item.isFavorite = !item.isFavorite;
    item.updatedAt = DateTime.now();
    await item.save();
    notifyListeners();
  }

  Future<void> markWorn(WardrobeItemModel item) async {
    item.wearCount += 1;
    item.lastWornAt = DateTime.now();
    await item.save();
    notifyListeners();
  }

  List<WardrobeItemModel> search({
    required String userId,
    String query = '',
    String? category,
    List<String>? occasions,
    String? color,
    bool favoritesOnly = false,
    bool includeArchived = false,
  }) {
    var results = includeArchived ? itemsFor(userId) : activeItemsFor(userId);
    if (query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      results = results.where((i) {
        return i.name.toLowerCase().contains(q) ||
            (i.brand?.toLowerCase().contains(q) ?? false) ||
            i.tags.any((t) => t.toLowerCase().contains(q)) ||
            i.category.toLowerCase().contains(q);
      }).toList();
    }
    if (category != null && category != 'All') {
      results = results.where((i) => i.category == category).toList();
    }
    if (color != null && color.isNotEmpty) {
      results = results.where((i) => i.color == color).toList();
    }
    if (occasions != null && occasions.isNotEmpty) {
      results = results.where((i) => i.occasions.any((o) => occasions.contains(o))).toList();
    }
    if (favoritesOnly) {
      results = results.where((i) => i.isFavorite).toList();
    }
    return results;
  }

  /// Wardrobe analytics used by Home insights & Shop the Gap — computed
  /// from REAL user data only, never hardcoded statistics.
  Map<String, int> categoryCounts(String userId) {
    final counts = <String, int>{};
    for (final item in activeItemsFor(userId)) {
      counts[item.category] = (counts[item.category] ?? 0) + 1;
    }
    return counts;
  }

  List<String> distinctColors(String userId) {
    return activeItemsFor(userId).map((i) => i.color).whereType<String>().toSet().toList();
  }
}
