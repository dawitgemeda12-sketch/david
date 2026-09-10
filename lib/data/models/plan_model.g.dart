// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlanModelAdapter extends TypeAdapter<PlanModel> {
  @override
  final int typeId = 4;

  @override
  PlanModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlanModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      date: fields[2] as DateTime,
      outfitId: fields[3] as String,
      occasion: fields[4] as String?,
      notes: fields[5] as String?,
      reminderEnabled: fields[6] as bool,
      createdAt: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PlanModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.outfitId)
      ..writeByte(4)
      ..write(obj.occasion)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.reminderEnabled)
      ..writeByte(7)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
