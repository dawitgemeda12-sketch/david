import 'package:hive/hive.dart';

part 'user_model.g.dart';

/// Represents an authenticated (or guest) Stylish user profile.
@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String email;

  @HiveField(3)
  String? username;

  @HiveField(4)
  String? profileImagePath;

  @HiveField(5)
  String passwordHash; // salted SHA-256 hash; never store plaintext

  @HiveField(6)
  String salt;

  @HiveField(7)
  bool isGuest;

  @HiveField(8)
  String? gender; // women, men, child, other

  @HiveField(9)
  List<String> favoriteColors;

  @HiveField(10)
  List<String> preferredOccasions;

  @HiveField(11)
  String city; // e.g. Addis Ababa

  @HiveField(12)
  String currency; // ETB by default

  @HiveField(13)
  double? monthlyBudget;

  @HiveField(14)
  DateTime createdAt;

  @HiveField(15)
  bool emailVerified;

  @HiveField(16)
  bool notificationsEnabled;

  @HiveField(17)
  bool aiPersonalizationEnabled;

  @HiveField(18)
  String? sizeInfo;

  @HiveField(19)
  String authProvider; // 'email' | 'google' | 'guest'

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.username,
    this.profileImagePath,
    this.passwordHash = '',
    this.salt = '',
    this.isGuest = false,
    this.gender,
    List<String>? favoriteColors,
    List<String>? preferredOccasions,
    this.city = 'Addis Ababa',
    this.currency = 'ETB',
    this.monthlyBudget,
    DateTime? createdAt,
    this.emailVerified = false,
    this.notificationsEnabled = true,
    this.aiPersonalizationEnabled = true,
    this.sizeInfo,
    this.authProvider = 'email',
  })  : favoriteColors = favoriteColors ?? [],
        preferredOccasions = preferredOccasions ?? [],
        createdAt = createdAt ?? DateTime.now();
}
