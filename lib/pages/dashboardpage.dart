import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tailor_mate/database/order_model.dart';
import 'package:tailor_mate/pages/cmlted_orders_page.dart';
import 'package:tailor_mate/pages/customers_page.dart';
import 'package:tailor_mate/pages/pending_orders_page.dart';
import 'package:tailor_mate/widgets/card.dart';
import 'package:tailor_mate/widgets/todays_delivery.dart';
import 'package:tailor_mate/widgets/upcoming_order_tile.dart';

class DashBoardPage extends StatefulWidget {
  const DashBoardPage({super.key});

  @override
  State<DashBoardPage> createState() => _DashBoardPageState();
}

class _DashBoardPageState extends State<DashBoardPage> {
  final List<Order> orders = Hive.box('orders').values.cast<Order>().toList();
  // ✅ Filter options: "All", "This Month", "This Week", "Today", "Custom"
  String selectedFilter = "All";
  DateTimeRange? customRange;

  int totalItems = 0;
  int pendingDeliveries = 0;
  int deliveredToday = 0;
  int totalCustomers = 0;
  double totalAdvance = 0.0;
  double totalIncome = 0.0;
  double totalCash = 0.0;
  double totalOnline = 0.0;
  double profit = 0.0;

  @override
  void initState() {
    super.initState();
    loadDashboardData();
  }

  void loadDashboardData() {
    final box = Hive.box('orders');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // ✅ Filter range setup
    DateTime? fromDate;
    DateTime? toDate;

    if (selectedFilter == "Today") {
      fromDate = today;
      toDate = today;
    } else if (selectedFilter == "This Week") {
      final weekday = today.weekday;
      fromDate = today.subtract(Duration(days: weekday - 1));
      toDate = today;
    } else if (selectedFilter == "This Month") {
      fromDate = DateTime(today.year, today.month, 1);
      toDate = today;
    } else if (selectedFilter == "Custom" && customRange != null) {
      fromDate = customRange!.start;
      toDate = customRange!.end;
    }

    // ✅ Reset all values
    totalIncome = 0.0;
    profit = 0.0;
    totalCash = 0.0;
    totalOnline = 0.0;
    pendingDeliveries = 0;
    deliveredToday = 0;
    totalAdvance = 0.0;
    totalItems = 0;
    totalCustomers = 0;
    double totalLabour = 0.0;

    final Set<String> customerMobiles = {};

    for (var order in box.values.cast<Order>()) {
      final bookingDate = DateTime(
        order.bookingDate.year,
        order.bookingDate.month,
        order.bookingDate.day,
      );

      // final deliveryDate = DateTime(
      //   order.deliveryDate.year,
      //   order.deliveryDate.month,
      //   order.deliveryDate.day,
      // );

      // ✅ Apply filter on booking date instead of delivery date
      if (fromDate != null && toDate != null) {
        if (bookingDate.isBefore(fromDate) || bookingDate.isAfter(toDate)) {
          continue;
        }
      }

      // 👕 Income, Profit, Items
      for (var item in order.items) {
        final qty = int.tryParse(item['qty'].toString()) ?? 0;
        final price = double.tryParse(item['price'].toString()) ?? 0.0;
        final bgqty = int.tryParse(item['bgqty'].toString()) ?? 0;
        final bgprice = double.tryParse(item['bgitemPrice'].toString()) ?? 0.0;
        final labour = double.tryParse(item['labour'].toString()) ?? 0.0;

        // Skip if both are 0
        if (qty == 0 && bgqty == 0) continue;

        final mainTotal = price * qty;
        final bgTotal = bgprice * bgqty;
        final subtotal = mainTotal + bgTotal;

        totalIncome += subtotal;
        totalItems += qty + bgqty;

        // Deduct labour for both qty and bgqty
        totalLabour += labour * (qty + bgqty);
      }

      // 💵 Payment modes
      if (order.advanceMode == 'Cash') {
        totalCash += order.advancePayment;
      } else if (order.advanceMode == 'Online') {
        totalOnline += order.advancePayment;
      }

      // 📅 Delivery status
      if (!order.isCompleted) pendingDeliveries++;
      if (order.isCompleted) deliveredToday++;

      // 💰 Advance
      totalAdvance += order.advancePayment;

      // 👥 Unique customers
      customerMobiles.add(order.mobileNumber.trim());
    }
    profit = totalIncome - totalLabour;
    totalCustomers = customerMobiles.length;

    // 🔄 Update UI
    setState(() {});
  }

  Future<void> logOut(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.logout_rounded,
                  size: 45,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 15),

                const Text(
                  "Logging out?",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                const Text(
                  "Are you sure you want to log out?",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.black54),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context); // close dialog first

                          Navigator.pushReplacementNamed(context, '/login');
                          await Supabase.instance.client.auth.signOut();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Log out",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'Dashboard',
            style: TextStyle(color: Colors.black, fontSize: 30),
          ),
          leadingWidth: 0,
          actions: [
            IconButton(
              onPressed: () async {
                logOut(context);
                // await Supabase.instance.client.auth.signOut();
                // Navigator.pushReplacementNamed(context, '/login');
              },
              icon: Icon(Icons.logout, color: Colors.black),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCustomChip("All"),
                      _buildCustomChip("Today"),
                      _buildCustomChip("This Week"),
                      _buildCustomChip("This Month"),
                      _buildCustomChip("Custom"),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10),

              // Dashboard Cards Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 1.4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  padding: EdgeInsets.all(5),
                  physics:
                      NeverScrollableScrollPhysics(), // Disable inner scroll
                  shrinkWrap: true, // Important!
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => CompletedOrderPage(),
                          ),
                        );
                      },
                      child: CustomCard(
                        cardTitle: 'Completed Orders',
                        cardValue: '$deliveredToday',
                        cardColor: Colors.green,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => PendingOrdersPage(),
                          ),
                        );
                      },
                      child: CustomCard(
                        cardTitle: 'Pending Orders',
                        cardValue: '$pendingDeliveries',
                        cardColor: Colors.orange,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const CustomersPage(),
                          ),
                        );
                      },
                      child: CustomCard(
                        cardTitle: 'Customers',
                        cardValue: '$totalCustomers',
                        cardColor: Colors.purple,
                      ),
                    ),
                    CustomCard(
                      cardTitle: 'Advance Payments',
                      cardValue: '₹$totalAdvance',
                      cardColor: Colors.red,
                    ),
                    CustomCard(
                      cardTitle: 'Total Income',
                      cardValue: '₹$totalIncome',
                      cardColor: Colors.teal,
                    ),
                    CustomCard(
                      cardTitle: 'Total Profit',
                      cardValue: '₹$profit',
                      cardColor: Colors.indigo,
                    ),
                    CustomCard(
                      cardTitle: 'Cash Payments',
                      cardValue: '₹$totalCash',
                      cardColor: Colors.cyan,
                    ),
                    CustomCard(
                      cardTitle: 'Online Payments',
                      cardValue: '₹$totalOnline',
                      cardColor: Colors.pink,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: const Text(
                  "Today's Deliveries",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                ),
              ),
              const SizedBox(height: 8),
              // New Section: Today's Deliveries
              TodaysDelivery(orders: orders),
              SizedBox(height: 15),
              // New Section: Upcoming Orders
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: const Text(
                  'Upcoming Orders',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 10),
              UpcomingOrderTile(orders: orders),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomChip(String label) {
    final isSelected = selectedFilter == label;

    return GestureDetector(
      onTap: () async {
        if (selectedFilter != label) {
          setState(() {
            selectedFilter = label;
          });

          if (label == "Custom") {
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2023),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              setState(() {
                customRange = picked;
              });
            } else {
              setState(() => selectedFilter = "All");
            }
          }
          loadDashboardData();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Container(
          // margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.white,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              // color: isSelected ? Colors.blueAccent : Colors.grey,
              color: Colors.blue,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
