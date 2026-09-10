// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wardrobe_item_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WardrobeItemModelAdapter extends TypeAdapter<WardrobeItemModel> {
  @override
  final int typeId = 1;

  @override
  WardrobeItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WardrobeItemModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      name: fields[2] as String,
      category: fields[3] as String,
      subcategory: fields[4] as String?,
      color: fields[5] as String?,
      secondaryColor: fields[6] as String?,
      pattern: fields[7] as String?,
      material: fields[8] as String?,
      style: fields[9] as String?,
      seasons: (fields[10] as List?)?.cast<String>(),
      occasions: (fields[11] as List?)?.cast<String>(),
      formality: fields[12] as String?,
      brand: fields[13] as String?,
      size: fields[14] as String?,
      purchaseDate: fields[15] as DateTime?,
      purchasePrice: fields[16] as double?,
      condition: fields[17] as String?,
      isFavorite: fields[18] as bool,
      notes: fields[19] as String?,
      imagePath: fields[20] as String?,
      tags: (fields[21] as List?)?.cast<String>(),
      isArchived: fields[22] as bool,
      createdAt: fields[23] as DateTime?,
      updatedAt: fields[24] as DateTime?,
      wearCount: fields[25] as int,
      lastWornAt: fields[26] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, WardrobeItemModel obj) {
    writer
      ..writeByte(27)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.subcategory)
      ..writeByte(5)
      ..write(obj.color)
      ..writeByte(6)
      ..write(obj.secondaryColor)
      ..writeByte(7)
      ..write(obj.pattern)
      ..writeByte(8)
      ..write(obj.material)
      ..writeByte(9)
      ..write(obj.style)
      ..writeByte(10)
      ..write(obj.seasons)
      ..writeByte(11)
      ..write(obj.occasions)
      ..writeByte(12)
      ..write(obj.formality)
      ..writeByte(13)
      ..write(obj.brand)
      ..writeByte(14)
      ..write(obj.size)
      ..writeByte(15)
      ..write(obj.purchaseDate)
      ..writeByte(16)
      ..write(obj.purchasePrice)
      ..writeByte(17)
      ..write(obj.condition)
      ..writeByte(18)
      ..write(obj.isFavorite)
      ..writeByte(19)
      ..write(obj.notes)
      ..writeByte(20)
      ..write(obj.imagePath)
      ..writeByte(21)
      ..write(obj.tags)
      ..writeByte(22)
      ..write(obj.isArchived)
      ..writeByte(23)
      ..write(obj.createdAt)
      ..writeByte(24)
      ..write(obj.updatedAt)
      ..writeByte(25)
      ..write(obj.wearCount)
      ..writeByte(26)
      ..write(obj.lastWornAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WardrobeItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
