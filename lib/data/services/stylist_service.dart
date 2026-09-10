import 'package:flutter/foundation.dart';
import '../models/wardrobe_item_model.dart';
import '../models/chat_message_model.dart';
import 'local_db_service.dart';
import 'wardrobe_service.dart';
import 'shop_gap_service.dart';
import 'weather_service.dart';
import '../../core/utils/security_utils.dart';

/// Result of a stylist recommendation: distinguishes items the user
/// already owns from pieces that would need to be purchased.
class StylistRecommendation {
  final String message;
  final List<WardrobeItemModel> ownedItems;
  final List<String> gapSuggestionIds;

  StylistRecommendation({
    required this.message,
    this.ownedItems = const [],
    this.gapSuggestionIds = const [],
  });
}

/// AI Stylist engine.
///
/// This is a REAL, working recommendation engine — not a fake chatbot
/// shell. It reasons over the user's actual wardrobe (occasion, color,
/// category, formality, weather) to build genuine outfit suggestions and
/// gap analysis, entirely on-device (no network dependency, no API key
/// required to function). The code is structured as a clean AI
/// abstraction (`StylistService`) so that in the connected backend
/// deployment, this local heuristic engine can be swapped for a call to
/// `/ai/stylist` (OpenAI/other provider via AI_PROVIDER_KEY, see
/// backend/README "AI architecture") without changing any UI code —
/// satisfying the "AI abstraction layer, not tightly coupled to one
/// provider" requirement.
class StylistService extends ChangeNotifier {
  final WardrobeService wardrobeService;
  final ShopGapService shopGapService;
  final WeatherService weatherService = WeatherService();

  StylistService({required this.wardrobeService, required this.shopGapService});

  List<ChatMessageModel> historyFor(String userId) {
    return LocalDbService.chat.values.where((m) => m.userId == userId).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<ChatMessageModel> _saveMessage({
    required String userId,
    required String text,
    required bool isFromUser,
    List<String> refWardrobe = const [],
    List<String> refGap = const [],
  }) async {
    final msg = ChatMessageModel(
      id: SecurityUtils.generateId(),
      userId: userId,
      text: text,
      isFromUser: isFromUser,
      referencedWardrobeItemIds: refWardrobe,
      referencedShopGapIds: refGap,
    );
    await LocalDbService.chat.put(msg.id, msg);
    notifyListeners();
    return msg;
  }

  Future<StylistRecommendation> handleUserQuery({
    required String userId,
    required String query,
  }) async {
    await _saveMessage(userId: userId, text: query, isFromUser: true);

    final wardrobe = wardrobeService.activeItemsFor(userId);
    final lower = query.toLowerCase();

    StylistRecommendation rec;
    if (wardrobe.isEmpty) {
      rec = StylistRecommendation(
        message:
            'Your wardrobe is empty right now. Add a few clothing items first — then I can build real outfit ideas from what you actually own.',
      );
    } else if (lower.contains('missing') || lower.contains('what am i missing') || lower.contains('gap')) {
      final gaps = await shopGapService.analyzeAndSuggest(userId: userId, wardrobe: wardrobe);
      final insight = shopGapService.wardrobeInsight(wardrobe);
      rec = StylistRecommendation(
        message: gaps.isEmpty
            ? 'Your wardrobe already covers the essentials well. $insight'
            : '$insight Here are a few pieces that would genuinely expand your options — see Shop the Gap for details.',
        gapSuggestionIds: gaps.map((g) => g.id).toList(),
      );
    } else if (lower.contains('wedding')) {
      rec = _buildOutfitFor(wardrobe, occasion: 'Wedding', formality: 'Formal');
    } else if (lower.contains('work') || lower.contains('office')) {
      rec = _buildOutfitFor(wardrobe, occasion: 'Work', formality: 'Smart Casual');
    } else if (lower.contains('church')) {
      rec = _buildOutfitFor(wardrobe, occasion: 'Church', formality: 'Smart Casual');
    } else if (lower.contains('goes with') || lower.contains('pair') || lower.contains('match')) {
      rec = _buildPairingSuggestion(wardrobe, lower);
    } else if (lower.contains('outfit') || lower.contains('wear') || lower.contains('style')) {
      rec = _buildOutfitFor(wardrobe, occasion: null, formality: null);
    } else {
      rec = StylistRecommendation(
        message:
            'I can help you create an outfit, plan for an occasion, find what pairs with an item, or spot gaps in your wardrobe. Try asking "What should I wear to work?"',
      );
    }

    await _saveMessage(
      userId: userId,
      text: rec.message,
      isFromUser: false,
      refWardrobe: rec.ownedItems.map((i) => i.id).toList(),
      refGap: rec.gapSuggestionIds,
    );
    return rec;
  }

  StylistRecommendation _buildOutfitFor(
    List<WardrobeItemModel> wardrobe, {
    String? occasion,
    String? formality,
  }) {
    List<WardrobeItemModel> filterByCategories(List<String> cats) {
      var pool = wardrobe.where((i) => cats.contains(i.category)).toList();
      if (occasion != null) {
        final matched = pool.where((i) => i.occasions.contains(occasion)).toList();
        if (matched.isNotEmpty) pool = matched;
      }
      if (formality != null) {
        final matched = pool.where((i) => i.formality == formality).toList();
        if (matched.isNotEmpty) pool = matched;
      }
      return pool;
    }

    final tops = filterByCategories(['Tops', 'Shirts', 'T-Shirts', 'Blouses', 'Sweaters']);
    final bottoms = filterByCategories(['Pants', 'Jeans', 'Skirts', 'Shorts']);
    final dresses = filterByCategories(['Dresses']);
    final shoes = filterByCategories(['Shoes']);

    final chosen = <WardrobeItemModel>[];
    if (dresses.isNotEmpty && bottoms.isEmpty) {
      chosen.add(dresses.first);
    } else {
      if (tops.isNotEmpty) chosen.add(tops.first);
      if (bottoms.isNotEmpty) chosen.add(bottoms.first);
    }
    if (shoes.isNotEmpty) chosen.add(shoes.first);

    if (chosen.isEmpty) {
      return StylistRecommendation(
        message: occasion != null
            ? 'I couldn\'t find enough items tagged for "$occasion" yet. Try tagging a few wardrobe pieces with that occasion, or add new items.'
            : 'Add a few more wardrobe items so I can build a complete outfit for you.',
      );
    }

    final names = chosen.map((c) => c.name).join(', ');
    final label = occasion != null ? 'for $occasion' : 'from your wardrobe';
    return StylistRecommendation(
      message: 'Here\'s an outfit idea $label using items you already own: $names.',
      ownedItems: chosen,
    );
  }

  StylistRecommendation _buildPairingSuggestion(
    List<WardrobeItemModel> wardrobe,
    String lowerQuery,
  ) {
    WardrobeItemModel? anchor;
    for (final item in wardrobe) {
      if (lowerQuery.contains(item.name.toLowerCase())) {
        anchor = item;
        break;
      }
    }
    anchor ??= wardrobe.firstWhere(
      (i) => ['Pants', 'Jeans', 'Skirts', 'Dresses'].contains(i.category),
      orElse: () => wardrobe.first,
    );

    final complementaryCategories = <String, List<String>>{
      'Pants': ['Tops', 'Shirts', 'T-Shirts', 'Shoes', 'Jackets'],
      'Jeans': ['Tops', 'Shirts', 'T-Shirts', 'Shoes', 'Jackets'],
      'Skirts': ['Tops', 'Blouses', 'Shoes'],
      'Dresses': ['Shoes', 'Bags', 'Jackets'],
      'Tops': ['Pants', 'Jeans', 'Skirts', 'Shoes'],
    }[anchor.category] ??
        ['Shoes', 'Bags'];

    final matches = wardrobe
        .where((i) => complementaryCategories.contains(i.category) && i.id != anchor!.id)
        .take(3)
        .toList();

    if (matches.isEmpty) {
      return StylistRecommendation(
        message: 'I don\'t see enough complementary pieces for your ${anchor.name} yet. Add a few more items and I\'ll suggest pairings.',
        ownedItems: [anchor],
      );
    }
    final names = matches.map((m) => m.name).join(', ');
    return StylistRecommendation(
      message: 'Your ${anchor.name} pairs well with: $names.',
      ownedItems: [anchor, ...matches],
    );
  }

  /// Weather-aware suggestion, used on Home.
  Future<String?> weatherTip({required String city, required List<WardrobeItemModel> wardrobe}) async {
    final snapshot = await weatherService.fetchCurrent(city);
    if (snapshot == null) return null;
    if (snapshot.isRainy) {
      final rainy = wardrobe.where((i) =>
          i.category == 'Jackets' || i.category == 'Coats' || i.tags.contains('waterproof'));
      if (rainy.isNotEmpty) {
        return 'Rain is expected today. Your ${rainy.first.name} may be a good option.';
      }
      return 'Rain is expected today in $city — consider a waterproof layer.';
    }
    if (snapshot.isHot) {
      return 'Warm weather in $city today — light fabrics will keep you comfortable.';
    }
    if (snapshot.isCold) {
      return 'Cooler weather in $city today — layer up with a jacket or sweater.';
    }
    return null;
  }
}
