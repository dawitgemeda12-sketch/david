// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 0;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      id: fields[0] as String,
      name: fields[1] as String,
      email: fields[2] as String,
      username: fields[3] as String?,
      profileImagePath: fields[4] as String?,
      passwordHash: fields[5] as String,
      salt: fields[6] as String,
      isGuest: fields[7] as bool,
      gender: fields[8] as String?,
      favoriteColors: (fields[9] as List?)?.cast<String>(),
      preferredOccasions: (fields[10] as List?)?.cast<String>(),
      city: fields[11] as String,
      currency: fields[12] as String,
      monthlyBudget: fields[13] as double?,
      createdAt: fields[14] as DateTime?,
      emailVerified: fields[15] as bool,
      notificationsEnabled: fields[16] as bool,
      aiPersonalizationEnabled: fields[17] as bool,
      sizeInfo: fields[18] as String?,
      authProvider: fields[19] as String,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.username)
      ..writeByte(4)
      ..write(obj.profileImagePath)
      ..writeByte(5)
      ..write(obj.passwordHash)
      ..writeByte(6)
      ..write(obj.salt)
      ..writeByte(7)
      ..write(obj.isGuest)
      ..writeByte(8)
      ..write(obj.gender)
      ..writeByte(9)
      ..write(obj.favoriteColors)
      ..writeByte(10)
      ..write(obj.preferredOccasions)
      ..writeByte(11)
      ..write(obj.city)
      ..writeByte(12)
      ..write(obj.currency)
      ..writeByte(13)
      ..write(obj.monthlyBudget)
      ..writeByte(14)
      ..write(obj.createdAt)
      ..writeByte(15)
      ..write(obj.emailVerified)
      ..writeByte(16)
      ..write(obj.notificationsEnabled)
      ..writeByte(17)
      ..write(obj.aiPersonalizationEnabled)
      ..writeByte(18)
      ..write(obj.sizeInfo)
      ..writeByte(19)
      ..write(obj.authProvider);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
