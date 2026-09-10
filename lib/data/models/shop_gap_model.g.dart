// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop_gap_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ShopGapProductModelAdapter extends TypeAdapter<ShopGapProductModel> {
  @override
  final int typeId = 5;

  @override
  ShopGapProductModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ShopGapProductModel(
      id: fields[0] as String,
      productName: fields[1] as String,
      category: fields[2] as String,
      color: fields[3] as String?,
      size: fields[4] as String?,
      price: fields[5] as double,
      currency: fields[6] as String,
      retailerName: fields[7] as String,
      city: fields[8] as String,
      isAvailable: fields[9] as bool,
      productUrl: fields[10] as String?,
      imagePath: fields[11] as String?,
      updatedAt: fields[12] as DateTime?,
      gapReason: fields[13] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ShopGapProductModel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.productName)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.color)
      ..writeByte(4)
      ..write(obj.size)
      ..writeByte(5)
      ..write(obj.price)
      ..writeByte(6)
      ..write(obj.currency)
      ..writeByte(7)
      ..write(obj.retailerName)
      ..writeByte(8)
      ..write(obj.city)
      ..writeByte(9)
      ..write(obj.isAvailable)
      ..writeByte(10)
      ..write(obj.productUrl)
      ..writeByte(11)
      ..write(obj.imagePath)
      ..writeByte(12)
      ..write(obj.updatedAt)
      ..writeByte(13)
      ..write(obj.gapReason);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShopGapProductModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
