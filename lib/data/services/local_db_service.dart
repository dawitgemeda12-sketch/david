import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../models/wardrobe_item_model.dart';
import '../models/outfit_model.dart';
import '../models/plan_model.dart';
import '../models/shop_gap_model.dart';
import '../models/chat_message_model.dart';
import '../models/community_post_model.dart';
import '../models/notification_model.dart';

/// Central Hive database bootstrap. Registers all typed adapters and
/// opens the boxes used across the app. Acts as the local persistence
/// layer (production-safe, on-device relational-like document store)
/// while the backend/README documents the PostgreSQL production schema
/// for a connected server deployment.
class LocalDbService {
  LocalDbService._();

  static const String usersBox = 'users_box';
  static const String sessionBox = 'session_box';
  static const String wardrobeBox = 'wardrobe_box';
  static const String outfitsBox = 'outfits_box';
  static const String plansBox = 'plans_box';
  static const String shopGapBox = 'shop_gap_box';
  static const String chatBox = 'chat_box';
  static const String communityBox = 'community_box';
  static const String notificationsBox = 'notifications_box';
  static const String prefsBox = 'prefs_box';

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();

    Hive.registerAdapter(UserModelAdapter());
    Hive.registerAdapter(WardrobeItemModelAdapter());
    Hive.registerAdapter(OutfitSlotAdapter());
    Hive.registerAdapter(OutfitModelAdapter());
    Hive.registerAdapter(PlanModelAdapter());
    Hive.registerAdapter(ShopGapProductModelAdapter());
    Hive.registerAdapter(ChatMessageModelAdapter());
    Hive.registerAdapter(CommunityPostModelAdapter());
    Hive.registerAdapter(NotificationModelAdapter());

    await Future.wait([
      Hive.openBox<UserModel>(usersBox),
      Hive.openBox(sessionBox),
      Hive.openBox<WardrobeItemModel>(wardrobeBox),
      Hive.openBox<OutfitModel>(outfitsBox),
      Hive.openBox<PlanModel>(plansBox),
      Hive.openBox<ShopGapProductModel>(shopGapBox),
      Hive.openBox<ChatMessageModel>(chatBox),
      Hive.openBox<CommunityPostModel>(communityBox),
      Hive.openBox<NotificationModel>(notificationsBox),
      Hive.openBox(prefsBox),
    ]);

    _initialized = true;
  }

  static Box<UserModel> get users => Hive.box<UserModel>(usersBox);
  static Box get session => Hive.box(sessionBox);
  static Box<WardrobeItemModel> get wardrobe => Hive.box<WardrobeItemModel>(wardrobeBox);
  static Box<OutfitModel> get outfits => Hive.box<OutfitModel>(outfitsBox);
  static Box<PlanModel> get plans => Hive.box<PlanModel>(plansBox);
  static Box<ShopGapProductModel> get shopGap => Hive.box<ShopGapProductModel>(shopGapBox);
  static Box<ChatMessageModel> get chat => Hive.box<ChatMessageModel>(chatBox);
  static Box<CommunityPostModel> get community => Hive.box<CommunityPostModel>(communityBox);
  static Box<NotificationModel> get notifications => Hive.box<NotificationModel>(notificationsBox);
  static Box get prefs => Hive.box(prefsBox);
}
