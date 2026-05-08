// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tailor_mate/database/order_model.dart';
import 'package:tailor_mate/utils/bill_generator.dart';
import 'package:tailor_mate/utils/tmp_file_bill.dart';

enum PaymentStatus { paid, partial, unpaid }

class OrderDetailsProvider with ChangeNotifier {
  /// The order being viewed/edited
  late Order order;

  /// Controls if edit mode is enabled
  bool isEditing = false;

  /// Tracks if any changes were saved
  bool didEdit = false;

  // -----------------------------
  // Controllers for customer/order fields
  // -----------------------------
  late TextEditingController billNoController;
  late TextEditingController nameController;
  late TextEditingController mobileController;
  late TextEditingController addressController;
  late TextEditingController advanceController;
  late TextEditingController advanceAmountDateController;
  late TextEditingController modeController;
  late TextEditingController paidAmountController;
  late TextEditingController paidAmountDateController;
  late TextEditingController bookingDateController;
  late TextEditingController deliveryDateController;
  late TextEditingController noteController;
  late TextEditingController discountController;

  bool isAdvanceCash = true;
  bool isPaidCash = true;

  void setAdvancePaymentMode(bool value) {
    isAdvanceCash = value;
    notifyListeners();
  }

  void setPaidPaymentMode(bool value) {
    isPaidCash = value;
    notifyListeners();
  }

  // -----------------------------
  // Calculated Properties
  // -----------------------------
  double get totalAmount {
    double total = 0;
    for (var item in order.items) {
      final qty = int.tryParse(item['qty']?.toString() ?? '0') ?? 0;
      final price = double.tryParse(item['price']?.toString() ?? '0.0') ?? 0.0;
      final bgitemprice =
          double.tryParse(item['bgitemPrice']?.toString() ?? '0.0') ?? 0.0;
      final bgqty = int.tryParse(item['bgqty']?.toString() ?? '0') ?? 0;

      total += (qty * price) + (bgitemprice * bgqty);
    }
    return total;
  }

  double get remainingAmount {
    final discount = double.tryParse(discountController.text) ?? 0;
    final advance = double.tryParse(advanceController.text) ?? 0;
    final paid = double.tryParse(paidAmountController.text) ?? 0;
    return totalAmount - discount - advance - paid;
  }

  PaymentStatus get paymentStatus {
    if (remainingAmount <= 0) {
      return PaymentStatus.paid;
    } else if (remainingAmount < totalAmount) {
      return PaymentStatus.partial;
    } else {
      return PaymentStatus.unpaid;
    }
  }

  //------------------------------
  // Bill no check
  //------------------------------
  bool billNoExists = false;

  bool checkBillNoExists(String billNo) {
    final box = Hive.box('orders');
    final exists = box.values.cast<Order>().any(
      (order) => order.id != this.order.id && order.billNo.trim() == billNo.trim(),
    );
    billNoExists = exists;
    notifyListeners();
    return exists;
  }

  // -----------------------------
  // Controllers for items
  // -----------------------------
  late List<TextEditingController> itemNameControllers;
  late List<TextEditingController> qtyControllers;
  late List<TextEditingController> priceControllers;
  late List<TextEditingController> workerControllers;
  late List<TextEditingController> labourControllers;
  late List<TextEditingController> wdateControllers;
  late List<TextEditingController> bgitemControllers;
  late List<TextEditingController> bgqtyControllers;
  late List<TextEditingController> bgitemPriceControllers;

  List<String> itemNameSuggestions = [];
  List<String> workerSuggestions = [];
  List<String> bgItemSuggestions = [];

  /// Initializes this provider with a passed ['Order'] and sets up controllers.
  /// Also sets `isEditing` based on ['autoEdit'].
  void initialize(Order passedOrder, bool autoEdit) {
    order = passedOrder;
    isEditing = autoEdit;

    // Set payment modes
    isAdvanceCash = order.advanceMode == 'Cash';
    isPaidCash = order.paidMode == 'Cash';

    // Initialize basic info controllers
    billNoController = TextEditingController(text: order.billNo);
    nameController = TextEditingController(text: order.customerName);
    mobileController = TextEditingController(text: order.mobileNumber);
    addressController = TextEditingController(text: order.address ?? '');
    advanceController = TextEditingController(
      text: order.advancePayment.toString(),
    );
    modeController = TextEditingController(text: order.advanceMode);
    advanceAmountDateController = TextEditingController(
      text: order.advanceDate != null
          ? '${order.advanceDate!.day.toString().padLeft(2, '0')}/${order.advanceDate!.month.toString().padLeft(2, '0')}/${(order.advanceDate!.year % 100).toString().padLeft(2, '0')}'
          : '',
    );
    paidAmountController = TextEditingController(
      text: order.paidAmount?.toString() ?? '0',
    );
    paidAmountDateController = TextEditingController(
      text: order.paidDate != null
          ? '${order.paidDate!.day.toString().padLeft(2, '0')}/${order.paidDate!.month.toString().padLeft(2, '0')}/${(order.paidDate!.year % 100).toString().padLeft(2, '0')}'
          : '',
    );

    bookingDateController = TextEditingController(
      text:
          '${order.bookingDate.day.toString().padLeft(2, '0')}/${order.bookingDate.month.toString().padLeft(2, '0')}/${(order.bookingDate.year % 100).toString().padLeft(2, '0')}',
    );
    deliveryDateController = TextEditingController(
      text:
          '${order.deliveryDate.day.toString().padLeft(2, '0')}/${order.deliveryDate.month.toString().padLeft(2, '0')}/${(order.deliveryDate.year % 100).toString().padLeft(2, '0')}',
    );
    noteController = TextEditingController(text: order.notes ?? '');
    discountController = TextEditingController(text: order.discount?.toString() ?? '0');

    // Initialize item controllers
    itemNameControllers = [];
    qtyControllers = [];
    priceControllers = [];
    workerControllers = [];
    labourControllers = [];
    wdateControllers = [];
    bgitemControllers = [];
    bgqtyControllers = [];
    bgitemPriceControllers = [];

    // Populate item fields from existing order
    for (var item in order.items) {
      itemNameControllers.add(TextEditingController(text: item['name'] ?? ''));
      qtyControllers.add(TextEditingController(text: item['qty'].toString()));
      priceControllers.add(
        TextEditingController(text: item['price'].toString()),
      );
      workerControllers.add(TextEditingController(text: item['worker'] ?? ''));
      labourControllers.add(
        TextEditingController(text: item['labour'].toString()),
      );
      wdateControllers.add(
        TextEditingController(
          text: () {
            if (item['wdate'] == null) return '';
            if (item['wdate'] is DateTime) {
              final d = item['wdate'] as DateTime;
              return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${(d.year % 100).toString().padLeft(2, '0')}';
            }
            final parsed = DateTime.tryParse(item['wdate'].toString());
            if (parsed != null) {
              return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${(parsed.year % 100).toString().padLeft(2, '0')}';
            }
            return item['wdate'].toString(); // fallback
          }(),
        ),
      );

      bgitemControllers.add(TextEditingController(text: item['bgitem'] ?? ''));
      bgqtyControllers.add(
        TextEditingController(text: item['bgqty']?.toString() ?? '0'),
      );
      bgitemPriceControllers.add(
        TextEditingController(text: item['bgitemPrice'].toString()),
      );
    }

    // Trigger UI update after build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) notifyListeners();
    });

    loadSuggestions();
  }

  /// If Hive is empty, fetch orders from Supabase to sync.
  Future<void> loadOrSyncOrders() async {
    final box = Hive.box('orders');
    final all = box.values.cast<Order>().toList();

    if (all.isEmpty) {
      await fetchOrdersFromSupabase();
    }
  }

  /// Fetch orders from Supabase and store them in Hive
  Future<void> fetchOrdersFromSupabase() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final List<dynamic> response = await supabase
          .from('orders')
          .select()
          .eq('user_id', user.id);

      final box = Hive.box('orders');

      for (var row in response) {
        print('Fetched row: $row');
        final order = Order(
          id: row['id'].toString(),
          billNo: row['billNo'].toString(),
          customerName: row['customer_name'] as String,
          mobileNumber: row['mobile_number'] as String,
          address: row['address'] as String?,
          advancePayment: (row['advance_payment'] as num).toDouble(),
          bookingDate: DateTime.parse(row['booking_date'] as String),
          deliveryDate: DateTime.parse(row['delivery_date'] as String),
          advanceMode: row['advance_mode'] as String,
          items: List<Map<String, dynamic>>.from(row['items']),
          notes: row['notes'] as String?,
          discount: (row['discount'] as num).toDouble(),
          isCompleted: row['isCompleted'] as bool,
          advanceDate: row['advance_payment_date'] != null ? DateTime.parse(row['advance_payment_date'] as String) : null,
          paidAmount: (row['paid_amount'] as num?)?.toDouble(),
          paidMode: row['paid_amount_mode'] as String? ?? 'Cash',
          paidDate: row['paid_amount_date'] != null ? DateTime.parse(row['paid_amount_date'] as String) : null,
        );

        await box.put(order.id, order);
        print('user id: ${user.id}');
        print('✅ Order fetched from Supabase: ${order.id} & ${order.billNo}');
      }
    } catch (e, stackTrace) {
      print('❌ Error fetching orders: $e');
      print(stackTrace); // Optional for debugging
    }
  }

  void loadSuggestions() {
    final orderBox = Hive.box('orders');

    final Set<String> itemNames = {};
    final Set<String> workers = {};
    final Set<String> bgItems = {};

    for (var order in orderBox.values) {
      for (var item in order.items) {
        if (item['name'] != null && item['name'].toString().trim().isNotEmpty) {
          itemNames.add(item['name'].toString().trim());
        }

        if (item['worker'] != null &&
            item['worker'].toString().trim().isNotEmpty) {
          workers.add(item['worker'].toString().trim());
        }

        if (item['bgitem'] != null &&
            item['bgitem'].toString().trim().isNotEmpty) {
          bgItems.add(item['bgitem'].toString().trim());
        }
      }
    }

    itemNameSuggestions = itemNames.toList();
    workerSuggestions = workers.toList();
    bgItemSuggestions = bgItems.toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) notifyListeners();
    });
  }

  /// Toggle editing mode
  void toggleEdit() {
    isEditing = !isEditing;
    if (hasListeners) notifyListeners();
  }

  /// Add a new empty item to the list
  void addItem() {
    itemNameControllers.add(TextEditingController());
    qtyControllers.add(TextEditingController());
    priceControllers.add(TextEditingController());
    workerControllers.add(TextEditingController());
    labourControllers.add(TextEditingController());
    wdateControllers.add(TextEditingController());
    bgitemControllers.add(TextEditingController());
    bgqtyControllers.add(TextEditingController());
    bgitemPriceControllers.add(TextEditingController());
    if (hasListeners) notifyListeners();
  }

  /// Remove item at given index
  void removeItem(int index) {
    itemNameControllers.removeAt(index);
    qtyControllers.removeAt(index);
    priceControllers.removeAt(index);
    workerControllers.removeAt(index);
    labourControllers.removeAt(index);
    wdateControllers.removeAt(index);
    bgitemControllers.removeAt(index);
    bgqtyControllers.removeAt(index);
    bgitemPriceControllers.removeAt(index);
    if (hasListeners) notifyListeners();
  }

  /// Save changes to order in Hive and Supabase
  Future<void> saveChanges(BuildContext context) async {
    // Convert string to DateTime
    List<String> bDateParts = bookingDateController.text.split('/');
    List<String> dDateParts = deliveryDateController.text.split('/');
    List<String> aDateParts = advanceAmountDateController.text.isNotEmpty ? advanceAmountDateController.text.split('/') : [];
    List<String> pDateParts = paidAmountDateController.text.isNotEmpty ? paidAmountDateController.text.split('/') : [];
    final wdate = wdateControllers.map((c) => c.text.trim()).toList();
    final wDateParts = wdate.map((d) => d.split('/')).toList();

    DateTime? parsedAdvanceDate;
    DateTime? parsedPaidDate;

    if (aDateParts.length == 3) {
      parsedAdvanceDate = DateTime(
        int.parse(aDateParts[2].length == 2 ? '20${aDateParts[2]}' : aDateParts[2]),
        int.parse(aDateParts[1]),
        int.parse(aDateParts[0]),
      );
    }

    if (pDateParts.length == 3) {
      parsedPaidDate = DateTime(
        int.parse(pDateParts[2].length == 2 ? '20${pDateParts[2]}' : pDateParts[2]),
        int.parse(pDateParts[1]),
        int.parse(pDateParts[0]),
      );
    }

    List<DateTime?> parsedWDates = [];

    for (var part in wDateParts) {
      if (part.length == 3) {
        parsedWDates.add(
          DateTime(
            int.parse(part[2].length == 2 ? '20${part[2]}' : part[2]),
            int.parse(part[1]),
            int.parse(part[0]),
          ),
        );
      } else {
        parsedWDates.add(null); // In case of invalid/missing date
      }
    }

    // ✅ NEW: Bill No duplication check (Hive)
    final enteredBillNo = billNoController.text.trim();
    if (enteredBillNo.isNotEmpty) {
      final existingBillNo = Hive.box('orders').values.cast<Order>().any(
        (order) =>
            order.billNo.trim() == enteredBillNo && order.id != this.order.id,
      );
      if (existingBillNo) {
        _showSnackBar(
          context,
          'Bill No Already Exists!',
          'Please use a different Bill No.',
          ContentType.failure,
        );
        return;
      }
    }

    // Check if mobile number length is less than 10
    if (mobileController.text.trim().length < 10 || mobileController.text.trim().length > 10) {
      _showSnackBar(
        context,
        'Invalid Mobile Number',
        'Mobile number must be at least 10 digits long.',
        ContentType.failure,
      );
      return;
    }

    final updatedOrder = Order(
      id: order.id,
      billNo: billNoController.text,
      customerName: nameController.text,
      mobileNumber: mobileController.text,
      address: addressController.text,
      advancePayment: double.tryParse(advanceController.text) ?? 0.0,
      advanceMode: isAdvanceCash ? 'Cash' : 'Online',
      bookingDate: DateTime(
        int.parse(
          bDateParts[2].length == 2 ? '20${bDateParts[2]}' : bDateParts[2],
        ),
        int.parse(bDateParts[1]),
        int.parse(bDateParts[0]),
      ),
      deliveryDate: DateTime(
        int.parse(
          dDateParts[2].length == 2 ? '20${dDateParts[2]}' : dDateParts[2],
        ),
        int.parse(dDateParts[1]),
        int.parse(dDateParts[0]),
      ),
      advanceDate: parsedAdvanceDate,
      paidDate: parsedPaidDate,
      notes: noteController.text,
      discount: double.tryParse(discountController.text) ?? 0.0,
      paidAmount: double.tryParse(paidAmountController.text) ?? 0.0,
      paidMode: isPaidCash ? 'Cash' : 'Online',
      isCompleted: order.isCompleted,
      items: List.generate(itemNameControllers.length, (index) {
        return {
          'name': _capitalizeWords(itemNameControllers[index].text.trim()),
          'qty': int.tryParse(qtyControllers[index].text) ?? 0,
          'price': double.tryParse(priceControllers[index].text) ?? 0.0,
          'worker': workerControllers[index].text.trim(),
          'wdate': parsedWDates[index]?.toIso8601String(),
          'labour': labourControllers[index].text.trim(),
          'bgitem': _capitalizeWords(bgitemControllers[index].text.trim()),
          'bgqty': int.tryParse(bgqtyControllers[index].text) ?? 0,
          'bgitemPrice': double.tryParse(bgitemPriceControllers[index].text) ?? 0.0,
        };
      }),
    );
    _showSnackBar(
      context,
      'Edited',
      'Successfully Edited Order',
      ContentType.success,
    );

    final supabase = Supabase.instance.client;

    try {
      final userId = supabase.auth.currentUser;

      if (userId == null) {
        _showSnackBar(
          context,
          'Uhh Ohh!!!',
          'You are not logged in. Please login first.',
          ContentType.failure,
        );
        return;
      }

      // Update order on Supabase
      final insertResponse = await supabase.from('orders').upsert({
        'id': order.id,
        'billNo': updatedOrder.billNo,
        'customer_name': updatedOrder.customerName,
        'mobile_number': updatedOrder.mobileNumber,
        'address': updatedOrder.address,
        'advance_payment': updatedOrder.advancePayment,
        'paid_amount': updatedOrder.paidAmount,
        'booking_date': updatedOrder.bookingDate.toIso8601String(),
        'delivery_date': updatedOrder.deliveryDate.toIso8601String(),
        'advance_payment_date': updatedOrder.advanceDate?.toIso8601String(),
        'paid_amount_date': updatedOrder.paidDate?.toIso8601String(),
        'advance_mode': updatedOrder.advanceMode,
        'paid_amount_mode': updatedOrder.paidMode,
        'items': updatedOrder.items,
        'notes': updatedOrder.notes,
        'discount': updatedOrder.discount,
        'isCompleted': updatedOrder.isCompleted,
        'user_id': userId.id, // required for multi-user support
      });

      print('✅ Order inserted into Supabase: $insertResponse');
    } catch (e) {
      // Handle Supabase failure
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error updating order: $e')));
      return;
    }

    // Save updated order locally
    final box = Hive.box('orders');
    await box.put(order.id, updatedOrder);

    // Update flags and notify UI
    didEdit = true;
    isEditing = false;
    if (hasListeners) notifyListeners();

    // Save bill image locally
    // Determine if bill-related fields have changed
    bool hasRelevantChanges = false;

    // Compare top-level fields
    if (order.customerName != nameController.text.trim() ||
        order.mobileNumber != mobileController.text.trim() ||
        (order.address ?? '') != addressController.text.trim() ||
        order.advancePayment !=
            double.tryParse(advanceController.text.trim()) ||
        order.advanceMode != modeController.text.trim() ||
        order.bookingDate.day != updatedOrder.bookingDate.day ||
        order.bookingDate.month != updatedOrder.bookingDate.month ||
        order.bookingDate.year != updatedOrder.bookingDate.year ||
        order.deliveryDate.day != updatedOrder.deliveryDate.day ||
        order.deliveryDate.month != updatedOrder.deliveryDate.month ||
        order.deliveryDate.year != updatedOrder.deliveryDate.year ||
        order.discount != double.tryParse(discountController.text.trim())) {
      hasRelevantChanges = true;
    }

    // Compare each item (name, qty, price, bgitem, bgqty, bgitemPrice)
    if (!hasRelevantChanges) {
      for (int i = 0; i < updatedOrder.items.length; i++) {
        final oldItem = order.items.length > i ? order.items[i] : {};
        final newItem = updatedOrder.items[i];

        if (oldItem['name'] != newItem['name'] ||
            (oldItem['qty']?.toString() ?? '') != newItem['qty'].toString() ||
            (oldItem['price']?.toString() ?? '') !=
                newItem['price'].toString() ||
            oldItem['bgitem'] != newItem['bgitem'] ||
            (oldItem['bgqty']?.toString() ?? '') !=
                newItem['bgqty'].toString() ||
            (oldItem['bgitemPrice']?.toString() ?? '') !=
                newItem['bgitemPrice'].toString()) {
          hasRelevantChanges = true;
          break;
        }
      }
    }

    // Save bill image locally only if bill-relevant fields changed
    if (hasRelevantChanges) {
      await markBillAsGenerating(order.id);
      await saveBillImageLocally(order.id.toString(), order.billNo);
      await markBillAsGenerated(order.id);
    }
  }

  /// Dispose all controllers when done
  void disposeAll() {
    billNoController.dispose();
    nameController.dispose();
    mobileController.dispose();
    addressController.dispose();
    advanceController.dispose();
    modeController.dispose();
    bookingDateController.dispose();
    deliveryDateController.dispose();
    noteController.dispose();
    discountController.dispose();

    for (var c in [
      ...itemNameControllers,
      ...qtyControllers,
      ...priceControllers,
      ...workerControllers,
      ...labourControllers,
      ...wdateControllers,
      ...bgitemControllers,
      ...bgqtyControllers,
      ...bgitemPriceControllers,
    ]) {
      c.dispose();
    }
  }

  @override
  void dispose() {
    disposeAll();
    super.dispose();
  }

  /// Capitalizes the first letter of each word in a string
  String _capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join(' ');
  }

  void _showSnackBar(
    BuildContext context,
    String title,
    String message,
    ContentType type,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        content: AwesomeSnackbarContent(
          title: title,
          message: message,
          contentType: type,
        ),
      ),
    );
  }
}
