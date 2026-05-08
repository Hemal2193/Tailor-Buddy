// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OrderAdapter extends TypeAdapter<Order> {
  @override
  final int typeId = 0;

  @override
  Order read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Order(
      id: fields[0] as String,
      billNo: fields[11] as String,
      customerName: fields[1] as String,
      mobileNumber: fields[2] as String,
      advancePayment: fields[4] as double,
      bookingDate: fields[5] as DateTime,
      deliveryDate: fields[6] as DateTime,
      advanceMode: fields[7] as String,
      items: (fields[8] as List)
          .map((dynamic e) => (e as Map).cast<String, dynamic>())
          .toList(),
      address: fields[3] as String?,
      notes: fields[9] as String?,
      discount: fields[10] as double?,
      isCompleted: fields[12] as bool,
      paidAmount: fields[14] as double?,
      advanceDate: fields[13] as DateTime?,
      paidMode: fields[15] as String,
      paidDate: fields[16] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Order obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.customerName)
      ..writeByte(2)
      ..write(obj.mobileNumber)
      ..writeByte(3)
      ..write(obj.address)
      ..writeByte(4)
      ..write(obj.advancePayment)
      ..writeByte(5)
      ..write(obj.bookingDate)
      ..writeByte(6)
      ..write(obj.deliveryDate)
      ..writeByte(7)
      ..write(obj.advanceMode)
      ..writeByte(8)
      ..write(obj.items)
      ..writeByte(9)
      ..write(obj.notes)
      ..writeByte(10)
      ..write(obj.discount)
      ..writeByte(11)
      ..write(obj.billNo)
      ..writeByte(12)
      ..write(obj.isCompleted)
      ..writeByte(13)
      ..write(obj.advanceDate)
      ..writeByte(14)
      ..write(obj.paidAmount)
      ..writeByte(15)
      ..write(obj.paidMode)
      ..writeByte(16)
      ..write(obj.paidDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
