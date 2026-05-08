import 'package:hive/hive.dart';
part 'order_model.g.dart';

@HiveType(typeId: 0)
class Order extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String customerName;

  @HiveField(2)
  String mobileNumber;

  @HiveField(3)
  String? address;

  @HiveField(4)
  double advancePayment;

  @HiveField(5)
  DateTime bookingDate;

  @HiveField(6)
  DateTime deliveryDate;

  @HiveField(7)
  String advanceMode; // 'Cash' or 'Online'

  @HiveField(8)
  List<Map<String, dynamic>> items;

  @HiveField(9)
  String? notes;

  @HiveField(10)
  double? discount;

  @HiveField(11)
  String billNo;

  @HiveField(12)
  bool isCompleted;

  @HiveField(13)
  DateTime? advanceDate;

  @HiveField(14)
  double? paidAmount;

  @HiveField(15)
  String paidMode; // 'Cash' or 'Online'

  @HiveField(16)
  DateTime? paidDate;

  Order({
    required this.id,
    required this.billNo,
    required this.customerName,
    required this.mobileNumber,
    required this.advancePayment,
    required this.bookingDate,
    required this.deliveryDate,
    required this.advanceMode,
    required this.items,
    this.address,
    this.notes,
    this.discount,
    this.isCompleted = false,
    this.paidAmount,
    this.advanceDate,
    this.paidMode = 'Cash',
    this.paidDate,
  });
}
