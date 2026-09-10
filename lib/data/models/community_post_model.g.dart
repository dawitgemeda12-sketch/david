// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'community_post_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CommunityPostModelAdapter extends TypeAdapter<CommunityPostModel> {
  @override
  final int typeId = 7;

  @override
  CommunityPostModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CommunityPostModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      userName: fields[2] as String,
      userAvatarPath: fields[3] as String?,
      outfitId: fields[4] as String?,
      imagePath: fields[5] as String?,
      caption: fields[6] as String,
      likedByUserIds: (fields[7] as List?)?.cast<String>(),
      commentCount: fields[8] as int,
      createdAt: fields[9] as DateTime?,
      isRemoved: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, CommunityPostModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.userName)
      ..writeByte(3)
      ..write(obj.userAvatarPath)
      ..writeByte(4)
      ..write(obj.outfitId)
      ..writeByte(5)
      ..write(obj.imagePath)
      ..writeByte(6)
      ..write(obj.caption)
      ..writeByte(7)
      ..write(obj.likedByUserIds)
      ..writeByte(8)
      ..write(obj.commentCount)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.isRemoved);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommunityPostModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
