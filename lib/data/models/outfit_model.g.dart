// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outfit_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OutfitSlotAdapter extends TypeAdapter<OutfitSlot> {
  @override
  final int typeId = 2;

  @override
  OutfitSlot read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OutfitSlot(
      slot: fields[0] as String,
      wardrobeItemId: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, OutfitSlot obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.slot)
      ..writeByte(1)
      ..write(obj.wardrobeItemId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OutfitSlotAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OutfitModelAdapter extends TypeAdapter<OutfitModel> {
  @override
  final int typeId = 3;

  @override
  OutfitModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OutfitModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      name: fields[2] as String,
      items: (fields[3] as List?)?.cast<OutfitSlot>(),
      occasion: fields[4] as String?,
      weather: fields[5] as String?,
      notes: fields[6] as String?,
      isFavorite: fields[7] as bool,
      createdAt: fields[8] as DateTime?,
      updatedAt: fields[9] as DateTime?,
      coverImagePath: fields[10] as String?,
      createdByAi: fields[11] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, OutfitModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.items)
      ..writeByte(4)
      ..write(obj.occasion)
      ..writeByte(5)
      ..write(obj.weather)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.isFavorite)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.coverImagePath)
      ..writeByte(11)
      ..write(obj.createdByAi);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OutfitModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
