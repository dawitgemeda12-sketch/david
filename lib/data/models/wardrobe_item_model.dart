import 'package:hive/hive.dart';

part 'wardrobe_item_model.g.dart';

@HiveType(typeId: 1)
class WardrobeItemModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userId;

  @HiveField(2)
  String name;

  @HiveField(3)
  String category; // Tops, Shirts, Dresses, Pants, Shoes, ...

  @HiveField(4)
  String? subcategory;

  @HiveField(5)
  String? color;

  @HiveField(6)
  String? secondaryColor;

  @HiveField(7)
  String? pattern;

  @HiveField(8)
  String? material;

  @HiveField(9)
  String? style;

  @HiveField(10)
  List<String> seasons; // Summer, Winter, Rainy, Dry...

  @HiveField(11)
  List<String> occasions; // Work, Church, Wedding, Casual...

  @HiveField(12)
  String? formality; // Casual, Smart Casual, Formal

  @HiveField(13)
  String? brand;

  @HiveField(14)
  String? size;

  @HiveField(15)
  DateTime? purchaseDate;

  @HiveField(16)
  double? purchasePrice;

  @HiveField(17)
  String? condition; // New, Good, Worn, Needs Repair

  @HiveField(18)
  bool isFavorite;

  @HiveField(19)
  String? notes;

  @HiveField(20)
  String? imagePath; // local path to processed image

  @HiveField(21)
  List<String> tags;

  @HiveField(22)
  bool isArchived;

  @HiveField(23)
  DateTime createdAt;

  @HiveField(24)
  DateTime updatedAt;

  @HiveField(25)
  int wearCount;

  @HiveField(26)
  DateTime? lastWornAt;

  WardrobeItemModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    this.subcategory,
    this.color,
    this.secondaryColor,
    this.pattern,
    this.material,
    this.style,
    List<String>? seasons,
    List<String>? occasions,
    this.formality,
    this.brand,
    this.size,
    this.purchaseDate,
    this.purchasePrice,
    this.condition,
    this.isFavorite = false,
    this.notes,
    this.imagePath,
    List<String>? tags,
    this.isArchived = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.wearCount = 0,
    this.lastWornAt,
  })  : seasons = seasons ?? [],
        occasions = occasions ?? [],
        tags = tags ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();
}
