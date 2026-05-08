import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tailor_mate/database/order_model.dart';
import 'package:tailor_mate/utils/bill_generator.dart';

class NewOrderProvider extends ChangeNotifier {
  NewOrderProvider() {
    _orderId = generateNewOrderId(); // Generate ID on provider creation
  }

  // -----------------------------
  // Controllers for Order Details
  // -----------------------------
  final billNoController = TextEditingController();
  final customerNameController = TextEditingController();
  final customerMobileController = TextEditingController();
  final customerAddressController = TextEditingController();
  final advanceAmountController = TextEditingController();
  final paidAmountController = TextEditingController();
  final bookingDateController = TextEditingController();
  final deliveryDateController = TextEditingController();
  final advanceAmountDateController = TextEditingController();
  final paidAmountDateController = TextEditingController();
  final notesController = TextEditingController();
  final discountController = TextEditingController();

  // -----------------------------
  // Payment Mode Toggle
  // -----------------------------
  // bool isCash = true;
  bool isAdvanceCash = true;
  bool isPaidCash = true;

  // void setPaymentMode(bool value) {
  //   isCash = value;
  //   notifyListeners();
  // }

  void setAdvancePaymentMode(bool value) {
    isAdvanceCash = value;
    notifyListeners();
  }

  void setPaidPaymentMode(bool value) {
    isPaidCash = value;
    notifyListeners();
  }

  // -----------------------------
  // Order ID Logic (New Version)
  // -----------------------------
  String _orderId = "";
  String get orderid => _orderId;

  String generateNewOrderId() {
    final now = DateTime.now();
    return "${now.millisecondsSinceEpoch}${now.microsecond}";
  }

  // -----------------------------
  // Suggestion Lists from Hive
  // -----------------------------
  List<String> itemNameSuggestions = [];
  List<String> workerSuggestions = [];
  List<String> bgItemSuggestions = [];

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

    notifyListeners();
  }

  // -----------------------------
  // Item Controllers
  // -----------------------------
  List<TextEditingController> nameControllers = [TextEditingController()];
  List<TextEditingController> qtyControllers = [TextEditingController()];
  List<TextEditingController> priceControllers = [TextEditingController()];
  List<TextEditingController> workerControllers = [TextEditingController()];
  List<TextEditingController> labourControllers = [TextEditingController()];
  List<TextEditingController> bgitemControllers = [TextEditingController()];
  List<TextEditingController> bgqtyControllers = [TextEditingController()];
  List<TextEditingController> bgitemPriceControllers = [
    TextEditingController(),
  ];
  List<TextEditingController> wdateControllers = [TextEditingController()];

  void addItem() {
    nameControllers.add(TextEditingController());
    qtyControllers.add(TextEditingController());
    priceControllers.add(TextEditingController());
    workerControllers.add(TextEditingController());
    labourControllers.add(TextEditingController());
    bgitemControllers.add(TextEditingController());
    bgqtyControllers.add(TextEditingController());
    bgitemPriceControllers.add(TextEditingController());
    wdateControllers.add(TextEditingController());
    notifyListeners();
  }

  //------------------------------
  // Bill no check
  //------------------------------
  bool billNoExists = false;

  bool checkBillNoExists(String billNo) {
    final box = Hive.box('orders');
    final exists = box.values.cast<Order>().any(
      (order) => order.billNo.trim() == billNo.trim(),
    );
    billNoExists = exists;
    notifyListeners();
    return exists;
  }


  // -----------------------------
  // Save Order (Hive + Supabase)
  // -----------------------------
  Future<void> saveOrder(BuildContext context) async {
  final name = customerNameController.text.trim();
  String number = customerMobileController.text.trim();

    // -----------------------------
    // BASIC VALIDATION
    // -----------------------------
  if (number.startsWith('+91')) {
    number = number.replaceFirst(RegExp(r'^\+91[-\s]?'), '');
  }

  final billNo = billNoController.text.trim();
  final booking = bookingDateController.text.trim();
  final delivery = deliveryDateController.text.trim();
  final aDate = advanceAmountDateController.text.trim();
  final pDate = paidAmountDateController.text.trim();
  final wdate = wdateControllers.map((c) => c.text.trim()).toList();

  if (billNo.isEmpty ||
      name.isEmpty ||
      number.isEmpty ||
      booking.isEmpty ||
      delivery.isEmpty) {
    _showSnackBar(
      context,
      'Missing Fields!',
      'Please fill Bill No, Customer Name, Mobile No, Booking Date, and Delivery Date.',
      ContentType.failure,
    );
    return;
  }

  if (number.length != 10) {
    _showSnackBar(
      context,
      'Invalid Mobile No!',
      'Please enter a valid 10-digit mobile number.',
      ContentType.failure,
    );
    return;
  }

  // BILL NO DUPLICATE CHECK
  final box = Hive.box('orders');
  if (box.values.cast<Order>().any((order) => order.billNo.trim() == billNo)) {
    _showSnackBar(
      context,
      'Bill No Already Exists!',
      'Please use a different Bill No.',
      ContentType.failure,
    );
    return;
  }

    // -----------------------------
    // SAFE DATE PARSING HELPERS
    // -----------------------------
  DateTime parseRequiredDate(String value) {
    final p = value.split('/');
    return DateTime(
      int.parse(p[2].length == 2 ? '20${p[2]}' : p[2]),
      int.parse(p[1]),
      int.parse(p[0]),
    );
  }

  DateTime? parseOptionalDate(String value) {
    if (value.isEmpty) return null;
    final p = value.split('/');
    if (p.length != 3) return null;
    return DateTime(
      int.parse(p[2].length == 2 ? '20${p[2]}' : p[2]),
      int.parse(p[1]),
      int.parse(p[0]),
    );
  }

    // -----------------------------
    // PARSE DATES SAFELY
    // -----------------------------
  final bookingDate = parseRequiredDate(booking);
  final deliveryDate = parseRequiredDate(delivery);
  final advanceDate = parseOptionalDate(aDate);
  final paidDate = parseOptionalDate(pDate);

  final parsedWDates = wdate.map(parseOptionalDate).toList();

    // -----------------------------
    // PARSE ORDER ITEMS
    // -----------------------------
  List<Map<String, dynamic>> items = [];

  for (int i = 0; i < nameControllers.length; i++) {
    final itemName = _capitalizeWords(nameControllers[i].text.trim());
    final qtyText = qtyControllers[i].text.trim();
    final priceText = priceControllers[i].text.trim();
    final bgItem = _capitalizeWords(bgitemControllers[i].text.trim());
    final bgQtyText = bgqtyControllers[i].text.trim();
    final bgPriceText = bgitemPriceControllers[i].text.trim();

    if (itemName.isEmpty &&
        qtyText.isEmpty &&
        priceText.isEmpty &&
        bgItem.isEmpty &&
        bgQtyText.isEmpty &&
        bgPriceText.isEmpty) {
      continue;
    }

    items.add({
      'name': itemName,
      'qty': int.tryParse(qtyText) ?? 0,
      'price': double.tryParse(priceText) ?? 0.0,
      'bgitem': bgItem,
      'bgqty': int.tryParse(bgQtyText) ?? 0,
      'bgitemPrice': double.tryParse(bgPriceText) ?? 0.0,
      'worker': workerControllers[i].text.trim(),
      'labour': labourControllers[i].text.trim(),
      'wdate': parsedWDates[i]?.toIso8601String(),
    });
  }

    // -----------------------------
    // CREATE ORDER MODEL
    // -----------------------------
  final currentOrderId = _orderId;

  final order = Order(
    billNo: billNo,
    id: currentOrderId.toString(),
    customerName: name,
    mobileNumber: number,
    address: customerAddressController.text.trim(),
    advancePayment: double.tryParse(advanceAmountController.text.trim()) ?? 0.0,
    paidAmount: double.tryParse(paidAmountController.text.trim()) ?? 0.0,
    bookingDate: bookingDate,
    deliveryDate: deliveryDate,
    advanceDate: advanceDate,
    paidDate: paidDate,
    advanceMode: isAdvanceCash ? 'Cash' : 'Online',
    paidMode: isPaidCash ? 'Cash' : 'Online',
    items: items,
    notes: notesController.text.trim(),
    discount: double.tryParse(discountController.text.trim()) ?? 0.0,
  );

    // -----------------------------
    // SAVE ORDER
    // -----------------------------
  await box.put(order.id, order);

  // RESET FORM & GENERATE NEW ID
  clearControlers();
  _orderId = generateNewOrderId();
  print('✅ New Order ID generated: $_orderId');

  // SUCCESS SNACKBAR
  if (context.mounted) {
    _showSnackBar(
      context,
      'Yaaayy!!!',
      'New Order Has Been Saved Successfully!',
      ContentType.success,
    );
  }

  // BACKGROUND TASKS
  _syncOrderToSupabase(order);
  if (items.isNotEmpty) {
    _generateBillInBackground(currentOrderId.toString(), order.billNo);
  }
}


  // -----------------------------
  // Utility Methods
  // -----------------------------
  /// Syncs order to Supabase in background (non-blocking)
  /// If sync fails, adds order to sync queue for retry
  Future<void> _syncOrderToSupabase(Order order) async {
    final supabase = Supabase.instance.client;
    try {
      final userId = supabase.auth.currentUser;
      if (userId == null) {
        print('⚠️ User not logged in. Adding order to sync queue.');
        await _addToSyncQueue(order.id);
        return;
      }

      await supabase.from('orders').insert({
        'id': order.id,
        'billNo': order.billNo,
        'customer_name': order.customerName,
        'mobile_number': order.mobileNumber,
        'address': order.address,
        'advance_payment': order.advancePayment,
        'paid_amount': order.paidAmount,
        'booking_date': order.bookingDate.toIso8601String(),
        'delivery_date': order.deliveryDate.toIso8601String(),
        'advance_payment_date': order.advanceDate?.toIso8601String(),
        'paid_amount_date': order.paidDate?.toIso8601String(),
        'advance_mode': order.advanceMode,
        'paid_amount_mode': order.paidMode,
        'items': order.items,
        'notes': order.notes,
        'discount': order.discount,
        'user_id': userId.id,
      });

      // Remove from sync queue if successfully synced
      await _removeFromSyncQueue(order.id);
      print('✅ Order synced to Supabase: ${order.id}');
    } catch (e) {
      print('❌ Supabase sync failed for order ${order.id}: $e');
      // Add to sync queue for retry later
      await _addToSyncQueue(order.id);
      // Order is still safely stored in Hive, will be synced later
    }
  }

  /// Adds an order ID to the sync queue for retry
  Future<void> _addToSyncQueue(String orderId) async {
    try {
      final syncQueueBox = await Hive.openBox('syncQueue');
      final retryCount = syncQueueBox.get(orderId, defaultValue: 0) as int;
      await syncQueueBox.put(orderId, retryCount + 1);
      print(
        '📋 Added order $orderId to sync queue (retry count: ${retryCount + 1})',
      );
    } catch (e) {
      print('❌ Error adding to sync queue: $e');
    }
  }

  /// Removes an order ID from the sync queue after successful sync
  Future<void> _removeFromSyncQueue(String orderId) async {
    try {
      final syncQueueBox = await Hive.openBox('syncQueue');
      await syncQueueBox.delete(orderId);
    } catch (e) {
      print('❌ Error removing from sync queue: $e');
    }
  }

  /// Retries syncing all orders in the sync queue
  /// Should be called on app start, network reconnect, or manually
  static Future<void> retryUnsyncedOrders() async {
    try {
      final syncQueueBox = await Hive.openBox('syncQueue');
      final ordersBox = Hive.box('orders');
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser;

      if (userId == null) {
        print('⚠️ User not logged in. Cannot retry sync.');
        return;
      }

      final unsyncedOrderIds = syncQueueBox.keys.toList();
      if (unsyncedOrderIds.isEmpty) {
        print('✅ No unsynced orders to retry.');
        return;
      }

      print(
        '🔄 Retrying sync for ${unsyncedOrderIds.length} unsynced orders...',
      );

      int successCount = 0;
      int failCount = 0;

      for (final orderId in unsyncedOrderIds) {
        try {
          final order = ordersBox.get(orderId.toString()) as Order?;
          if (order == null) {
            // Order doesn't exist, remove from queue
            await syncQueueBox.delete(orderId);
            continue;
          }

          final retryCount = syncQueueBox.get(orderId, defaultValue: 0) as int;
          // Exponential backoff: wait if retry count is high
          if (retryCount > 3) {
            // Skip orders with too many retries (might be invalid)
            print('⚠️ Skipping order $orderId (too many retries: $retryCount)');
            continue;
          }

          await supabase.from('orders').insert({
            'id': order.id,
            'billNo': order.billNo,
            'customer_name': order.customerName,
            'mobile_number': order.mobileNumber,
            'address': order.address,
            'advance_payment': order.advancePayment,
            'paid_amount': order.paidAmount,
            'booking_date': order.bookingDate.toIso8601String(),
            'delivery_date': order.deliveryDate.toIso8601String(),
            'advance_payment_date': order.advanceDate?.toIso8601String(),
            'paid_amount_date': order.paidDate?.toIso8601String(),
            'advance_mode': order.advanceMode,
            'paid_amount_mode': order.paidMode,
            'items': order.items,
            'notes': order.notes,
            'discount': order.discount,
            'user_id': userId.id,
          });

          // Successfully synced, remove from queue
          await syncQueueBox.delete(orderId);
          successCount++;
          print('✅ Retry sync successful for order: ${order.id}');
        } catch (e) {
          failCount++;
          print('❌ Retry sync failed for order $orderId: $e');
          // Keep in queue for next retry
        }
      }

      print(
        '📊 Sync retry complete: $successCount succeeded, $failCount failed',
      );
    } catch (e) {
      print('❌ Error during sync retry: $e');
    }
  }

  /// Gets the count of unsynced orders
  static Future<int> getUnsyncedOrderCount() async {
    try {
      final syncQueueBox = await Hive.openBox('syncQueue');
      return syncQueueBox.length;
    } catch (e) {
      return 0;
    }
  }

  /// Generates bill image in background (non-blocking)
  Future<void> _generateBillInBackground(String orderId, String billNo) async {
    try {
      await saveBillImageLocally(orderId, billNo);
    } catch (e) {
      print('❌ Bill generation failed for order $orderId: $e');
      // Non-critical - order is saved, bill can be regenerated later
    }
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

  void clearControlers() {
    billNoController.clear();
    customerNameController.clear();
    customerMobileController.clear();
    customerAddressController.clear();
    advanceAmountController.clear();
    paidAmountController.clear();
    bookingDateController.clear();
    deliveryDateController.clear();
    advanceAmountDateController.clear();
    paidAmountDateController.clear();
    notesController.clear();
    discountController.clear();

    for (var list in [
      nameControllers,
      qtyControllers,
      priceControllers,
      workerControllers,
      labourControllers,
      wdateControllers,
      bgitemControllers,
      bgqtyControllers,
      bgitemPriceControllers,
    ]) {
      for (var controller in list) {
        controller.clear();
      }
    }
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
