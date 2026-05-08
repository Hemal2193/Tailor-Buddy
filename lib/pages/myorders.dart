import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tailor_mate/database/order_model.dart';
import 'package:tailor_mate/pages/OrderDetails/order_details.dart';
import 'package:tailor_mate/widgets/all_order_tile.dart';
import 'package:tailor_mate/widgets/cmlted_order_tile.dart';
import 'package:tailor_mate/widgets/pending_order_tile.dart';

class MyOrders extends StatefulWidget {
  const MyOrders({super.key});

  @override
  State<MyOrders> createState() => _MyOrdersState();
}

class _MyOrdersState extends State<MyOrders> {
  List<Order> allOrders = [];
  List<Order> completedOrders = [];
  List<Order> pendingOrders = [];

  late TextEditingController _searchController;
  String _searchTerm = '';

  Map<String, bool> updatedOrders = {};
  Timer? _debounceTimer;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ----------------- 🔹 DELETE ORDER -----------------
  void deleteOrder(Order order) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: SizedBox(
          height: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Delete Order?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Are you sure you want to delete this order? This action cannot be undone.',
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  TextButton(
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      final box = Hive.box('orders');
                      final supabase = Supabase.instance.client;

                      try {
                        final userId = supabase.auth.currentUser?.id;
                        if (userId != null) {
                          await supabase
                              .from('orders')
                              .delete()
                              .eq('id', order.id)
                              .eq('user_id', userId);
                        }
                      } catch (e) {
                        print('Error deleting order from Supabase: $e');
                      }

                      await box.delete(order.id);

                      loadOrders();

                      navigator.pop();

                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('Order deleted successfully'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------- 🔹 LOAD ORDERS -----------------
  void loadOrders() {
    final box = Hive.box('orders');
    List<Order> all = [];
    List<Order> pending = [];
    List<Order> completed = [];

    // Pre-process search term for efficiency
    final searchTerm = _searchTerm.trim().toLowerCase();
    final isSearching = searchTerm.isNotEmpty;

    for (var order in box.values.cast<Order>()) {
      // Apply search filter if needed
      if (isSearching) {
        final billNoMatch = order.billNo.toString().toLowerCase().contains(
          searchTerm,
        );
        final customerNameMatch = order.customerName.toLowerCase().contains(
          searchTerm,
        );
        final mobileNumberMatch = order.mobileNumber.toLowerCase().contains(
          searchTerm,
        );

        // Skip if no search match
        if (!billNoMatch && !customerNameMatch && !mobileNumberMatch) {
          continue;
        }
      }

      all.add(order);
      if (order.isCompleted) {
        completed.add(order);
      } else {
        pending.add(order);
      }
    }

    setState(() {
      allOrders = all;
      pendingOrders = pending;
      completedOrders = completed;
    });
  }

  //   // ----------------- 🔹 LOAD ORDERS -----------------
  // void loadOrders() {
  //   final box = Hive.box('orders');
  //   final List<Order> all = [];
  //   final List<Order> pending = [];
  //   final List<Order> completed = [];

  //   // Pre-process search term for efficiency
  //   final searchTerm = _searchTerm.toLowerCase().trim();
  //   final isSearching = searchTerm.isNotEmpty;

  //   for (var order in box.values.cast<Order>()) {
  //     // Apply search filter if needed
  //     if (isSearching) {
  //       final billNoMatch = order.billNo.toString().contains(_searchTerm);
  //       final customerNameMatch = order.customerName.toLowerCase().contains(searchTerm);
  //       final mobileNumberMatch = order.mobileNumber.toLowerCase().contains(searchTerm);

  //       // Skip if no search match
  //       if (!billNoMatch && !customerNameMatch && !mobileNumberMatch) {
  //         continue;
  //       }
  //     }

  //     all.add(order);
  //     if (order.isCompleted) {
  //       completed.add(order);
  //     } else {
  //       pending.add(order);
  //     }
  //   }

  //   setState(() {
  //     allOrders = all;
  //     pendingOrders = pending;
  //     completedOrders = completed;
  //   });
  // }

  // ----------------- 🔹 REFRESH + BATCH SYNC TO SUPABASE -----------------
  void onOrderCheckChanged(String orderId, bool isChecked) {
    loadOrders();
    // 1. update the map
    updatedOrders[orderId] = isChecked;

    // 2. reset debounce timer
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 3), () {
      _syncCheckedOrdersToSupabase();
    });
  }

  Future<void> _syncCheckedOrdersToSupabase() async {
    if (_isSyncing || updatedOrders.isEmpty) return;
    _isSyncing = true;

    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      for (final entry in updatedOrders.entries) {
        await supabase
            .from('orders')
            .update({'isCompleted': entry.value})
            .eq('id', entry.key)
            .eq('user_id', userId);
      }

      print("✅ Synced ${updatedOrders.length} orders");
      updatedOrders.clear();
    } catch (e) {
      print("❌ Error syncing batch orders: $e");
    } finally {
      _isSyncing = false;
    }
  }

  // ----------------- 🔹 UI -----------------
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Orders'),
          elevation: 0,
          toolbarHeight: 40,
        ),
        body: Column(
          children: [
            // Search box
            Container(
              color: Colors.blue,
              child: Padding(
                padding: const EdgeInsets.only(left: 12, right: 12, bottom: 14),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.search),
                        const SizedBox(width: 5),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() {
                                _searchTerm = value;
                              });
                              loadOrders();
                            },
                            decoration: const InputDecoration(
                              hintText: 'Search orders',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Tabs
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 10, right: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: TabBar(
                  indicatorAnimation: TabIndicatorAnimation.elastic,
                  indicatorSize: TabBarIndicatorSize.tab,
                  automaticIndicatorColorAdjustment: false,
                  unselectedLabelColor: Colors.black,
                  indicator: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  labelColor: Colors.white,
                  tabs: const [
                    Tab(text: 'All Orders'),
                    Tab(text: 'Pending'),
                    Tab(text: 'Completed'),
                  ],
                ),
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                children: [
                  AllOrderTile(
                    orders: allOrders,
                    onDelete: deleteOrder,
                    onTap: (order) async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              OrderDetailsPage(order: order, autoEdit: false),
                        ),
                      );
                      loadOrders();
                    },
                    onOrderUpdated: onOrderCheckChanged,
                  ),
                  PendingOrderTile(
                    orders: pendingOrders,
                    onDelete: deleteOrder,
                    onTap: (order) async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              OrderDetailsPage(order: order, autoEdit: false),
                        ),
                      );
                      loadOrders();
                    },
                    onOrderUpdated: onOrderCheckChanged,
                  ),
                  CompletedOrderTile(
                    orders: completedOrders,
                    onDelete: deleteOrder,
                    onTap: (order) async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              OrderDetailsPage(order: order, autoEdit: false),
                        ),
                      );
                      loadOrders();
                    },
                    onOrderUpdated: onOrderCheckChanged,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
