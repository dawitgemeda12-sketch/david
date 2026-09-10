import 'package:hive/hive.dart';

part 'shop_gap_model.g.dart';

/// A recommended missing wardrobe piece, backed by verified retailer data
/// where available. Prices/retailers are NEVER fabricated by AI — this
/// model is only populated from the local retailer catalog service.
@HiveType(typeId: 5)
class ShopGapProductModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String productName;

  @HiveField(2)
  String category;

  @HiveField(3)
  String? color;

  @HiveField(4)
  String? size;

  @HiveField(5)
  double price;

  @HiveField(6)
  String currency; // ETB

  @HiveField(7)
  String retailerName;

  @HiveField(8)
  String city;

  @HiveField(9)
  bool isAvailable;

  @HiveField(10)
  String? productUrl;

  @HiveField(11)
  String? imagePath; // local/network asset reference

  @HiveField(12)
  DateTime updatedAt;

  @HiveField(13)
  String gapReason; // why Stylish thinks this fills a wardrobe gap

  ShopGapProductModel({
    required this.id,
    required this.productName,
    required this.category,
    this.color,
    this.size,
    required this.price,
    this.currency = 'ETB',
    required this.retailerName,
    this.city = 'Addis Ababa',
    this.isAvailable = true,
    this.productUrl,
    this.imagePath,
    DateTime? updatedAt,
    this.gapReason = '',
  }) : updatedAt = updatedAt ?? DateTime.now();
}
