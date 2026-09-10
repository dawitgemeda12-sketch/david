import 'package:hive/hive.dart';

part 'outfit_model.g.dart';

/// A slot in the outfit builder: top, bottom, shoes, outerwear, bag, accessory.
@HiveType(typeId: 2)
class OutfitSlot extends HiveObject {
  @HiveField(0)
  String slot; // Top, Bottom, Shoes, Outerwear, Bag, Accessories

  @HiveField(1)
  String wardrobeItemId;

  OutfitSlot({required this.slot, required this.wardrobeItemId});
}

@HiveType(typeId: 3)
class OutfitModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userId;

  @HiveField(2)
  String name;

  @HiveField(3)
  List<OutfitSlot> items;

  @HiveField(4)
  String? occasion;

  @HiveField(5)
  String? weather;

  @HiveField(6)
  String? notes;

  @HiveField(7)
  bool isFavorite;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime updatedAt;

  @HiveField(10)
  String? coverImagePath;

  @HiveField(11)
  bool createdByAi;

  OutfitModel({
    required this.id,
    required this.userId,
    required this.name,
    List<OutfitSlot>? items,
    this.occasion,
    this.weather,
    this.notes,
    this.isFavorite = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.coverImagePath,
    this.createdByAi = false,
  })  : items = items ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();
}
