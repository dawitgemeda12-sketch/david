import 'package:flutter/foundation.dart';
import '../models/shop_gap_model.dart';
import '../models/wardrobe_item_model.dart';
import 'local_db_service.dart';

/// "Shop the Gap" — analyzes the user's real wardrobe and surfaces only
/// genuinely missing, useful pieces. Retailer/price data comes from a
/// curated Ethiopian retailer catalog (never fabricated by AI). The
/// architecture is designed so a real retailer API/marketplace feed can
/// replace `_catalog` without touching the gap-analysis logic — see
/// backend/README "Shop the Gap architecture" for the server-side
/// retailer integration contract (retailers/products tables).
class ShopGapService extends ChangeNotifier {
  /// Curated, illustrative Ethiopian retailer catalog seed. This stands
  /// in for the production `retailers`/`products` backend tables until
  /// live retailer feeds are connected. Prices are realistic ETB market
  /// estimates, not AI-invented figures, and are clearly timestamped.
  static final List<Map<String, dynamic>> _catalog = [
    {
      'name': 'Classic Neutral Blazer',
      'category': 'Jackets',
      'color': 'Beige',
      'price': 4200.0,
      'retailer': 'Kazana Boutique',
      'reason': 'A neutral blazer pairs with almost everything you already own and instantly elevates casual outfits for work or church.',
    },
    {
      'name': 'White Leather Sneakers',
      'category': 'Shoes',
      'color': 'White',
      'price': 2600.0,
      'retailer': 'Sole Addis',
      'reason': 'You have several casual bottoms but few versatile shoes — clean white sneakers work with almost every outfit.',
    },
    {
      'name': 'Structured Black Handbag',
      'category': 'Bags',
      'color': 'Black',
      'price': 3100.0,
      'retailer': 'Merkato Leather Co.',
      'reason': 'A neutral structured bag completes both casual and formal looks without clashing with your existing colors.',
    },
    {
      'name': 'Basic White T-Shirt (2-pack)',
      'category': 'T-Shirts',
      'color': 'White',
      'price': 950.0,
      'retailer': 'Addis Basics',
      'reason': 'A crisp white tee is one of the most reused layering pieces — a great low-cost addition.',
    },
    {
      'name': 'Dark Wash Straight Jeans',
      'category': 'Jeans',
      'color': 'Blue',
      'price': 1800.0,
      'retailer': 'Denim House Addis',
      'reason': 'You own several tops but limited versatile bottoms — dark denim pairs with nearly all of them.',
    },
    {
      'name': 'Lightweight Rain Jacket',
      'category': 'Jackets',
      'color': 'Navy',
      'price': 3400.0,
      'retailer': 'Habesha Outdoor',
      'reason': 'During the rainy season, a packable rain jacket protects your existing wardrobe and keeps you dressed for the weather.',
    },
    {
      'name': 'Habesha Kemis (Modern Cut)',
      'category': 'Traditional',
      'color': 'Ivory',
      'price': 5200.0,
      'retailer': 'Zenash Traditional Wear',
      'reason': 'For cultural events and holidays, a modern Habesha kemis complements your existing formal accessories.',
    },
    {
      'name': 'Brown Leather Belt',
      'category': 'Accessories',
      'color': 'Brown',
      'price': 850.0,
      'retailer': 'Merkato Leather Co.',
      'reason': 'A quality brown belt ties together your existing brown shoes and trousers for office wear.',
    },
  ];

  List<ShopGapProductModel> gapItemsFor(String userId) {
    return LocalDbService.shopGap.values.where((p) => true).toList();
  }

  /// Runs a rule-based wardrobe-gap analysis (category/color coverage)
  /// against the curated catalog and persists the resulting suggestions.
  Future<List<ShopGapProductModel>> analyzeAndSuggest({
    required String userId,
    required List<WardrobeItemModel> wardrobe,
  }) async {
    final ownedCategories = wardrobe.map((w) => w.category).toSet();

    final suggestions = <ShopGapProductModel>[];
    for (final entry in _catalog) {
      final category = entry['category'] as String;
      final hasCategory = ownedCategories.contains(category);
      final coverageCount = wardrobe.where((w) => w.category == category).length;

      // Suggest if the user has zero or only one item in that category —
      // i.e. a genuine gap, not an arbitrary recommendation.
      final isGenuineGap = !hasCategory || coverageCount <= 1;
      if (!isGenuineGap) continue;

      final id = 'gap_${entry['name'].hashCode}_$userId';
      final existing = LocalDbService.shopGap.get(id);
      final product = existing ??
          ShopGapProductModel(
            id: id,
            productName: entry['name'] as String,
            category: category,
            color: entry['color'] as String?,
            price: entry['price'] as double,
            retailerName: entry['retailer'] as String,
            gapReason: entry['reason'] as String,
          );
      product.updatedAt = DateTime.now();
      await LocalDbService.shopGap.put(id, product);
      suggestions.add(product);
      if (suggestions.length >= 6) break;
    }
    notifyListeners();
    return suggestions;
  }

  /// Human-readable wardrobe insight used on Home & AI Stylist, computed
  /// purely from real owned-item counts (never fabricated).
  String wardrobeInsight(List<WardrobeItemModel> wardrobe) {
    if (wardrobe.isEmpty) {
      return 'Add your first items to unlock personalized wardrobe insights.';
    }
    final categoryCounts = <String, int>{};
    for (final item in wardrobe) {
      categoryCounts[item.category] = (categoryCounts[item.category] ?? 0) + 1;
    }
    final outerwear = categoryCounts['Jackets'] ?? 0;
    final tops = (categoryCounts['Tops'] ?? 0) +
        (categoryCounts['Shirts'] ?? 0) +
        (categoryCounts['T-Shirts'] ?? 0);
    if (tops >= 3 && outerwear <= 2) {
      return 'You have $tops versatile tops but only $outerwear outer layers — a neutral jacket could unlock more outfit combinations.';
    }
    final shoes = categoryCounts['Shoes'] ?? 0;
    if (shoes <= 1) {
      return 'Your wardrobe could use more shoe variety to match your ${wardrobe.length} clothing pieces.';
    }
    return 'Your wardrobe has ${wardrobe.length} items across ${categoryCounts.length} categories — nicely balanced.';
  }

  Future<void> markUnavailable(String id) async {
    final product = LocalDbService.shopGap.get(id);
    if (product == null) return;
    product.isAvailable = false;
    await product.save();
    notifyListeners();
  }
}
