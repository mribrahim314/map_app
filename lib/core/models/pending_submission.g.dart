// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_submission.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PendingSubmissionAdapter extends TypeAdapter<PendingSubmission> {
  @override
  final int typeId = 0;

  @override
  PendingSubmission read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PendingSubmission(
      district: fields[0] as String?,
      gouvernante: fields[1] as String?,
      coordinates: fields[2] as dynamic,
      type: fields[3] as String?,
      message: fields[4] as String?,
      imageURL: fields[5] as String?,
      userId: fields[6] as String,
      isAdopted: fields[7] as bool,
      parcelSize: fields[8] as String?,
      date: fields[9] as String,
      collection: fields[10] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PendingSubmission obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.district)
      ..writeByte(1)
      ..write(obj.gouvernante)
      ..writeByte(2)
      ..write(obj.coordinates)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.message)
      ..writeByte(5)
      ..write(obj.imageURL)
      ..writeByte(6)
      ..write(obj.userId)
      ..writeByte(7)
      ..write(obj.isAdopted)
      ..writeByte(8)
      ..write(obj.parcelSize)
      ..writeByte(9)
      ..write(obj.date)
      ..writeByte(10)
      ..write(obj.collection);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingSubmissionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
