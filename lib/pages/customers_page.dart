import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tailor_mate/database/order_model.dart';
import 'package:tailor_mate/pages/OrderDetails/order_details.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  late TextEditingController _searchController;
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MapEntry<String, List<Order>>> _getFilteredCustomers(Box ordersBox) {
    final List<Order> orders = ordersBox.values.cast<Order>().toList();

    // Group orders by customer mobile number
    final Map<String, List<Order>> customerOrdersMap = {};

    for (var order in orders) {
      final mobileKey = order.mobileNumber.trim();
      if (!customerOrdersMap.containsKey(mobileKey)) {
        customerOrdersMap[mobileKey] = [];
      }
      customerOrdersMap[mobileKey]!.add(order);
    }

    // Convert to list of customer entries, sorted by most recent order
    List<MapEntry<String, List<Order>>> customerEntries = customerOrdersMap
        .entries
        .toList();

    // Apply search filter
    if (_searchTerm.isNotEmpty) {
      customerEntries = customerEntries.where((entry) {
        final customerName = entry.value.first.customerName.toLowerCase();
        final mobileNumber = entry.key.toLowerCase();
        final searchLower = _searchTerm.toLowerCase();
        return customerName.contains(searchLower) ||
            mobileNumber.contains(searchLower);
      }).toList();
    }

    customerEntries.sort((a, b) {
      // Sort by most recent order date (booking date)
      final aLatest = a.value
          .map((o) => o.bookingDate)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      final bLatest = b.value
          .map((o) => o.bookingDate)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      return bLatest.compareTo(aLatest);
    });

    return customerEntries;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box>(
      valueListenable: Hive.box('orders').listenable(),
      builder: (context, box, _) {
        final customerEntries = _getFilteredCustomers(box);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Customers'),
            elevation: 0,
            toolbarHeight: 50,
          ),
          body: Column(
            children: [
              // Search box
              Container(
                color: Colors.blue,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 12,
                    right: 12,
                    bottom: 14,
                  ),
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
                              },
                              decoration: const InputDecoration(
                                hintText: 'Search customers',
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
              // Customer list
              Expanded(
                child: customerEntries.isEmpty
                    ? const Center(child: Text('No customers found.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: customerEntries.length,
                        itemBuilder: (context, index) {
                          final entry = customerEntries[index];
                          final customerOrders = entry.value;
                          final customerName =
                              customerOrders.first.customerName;
                          final mobileNumber = entry.key;

                          // Sort orders by booking date (most recent first)
                          customerOrders.sort(
                            (a, b) => b.bookingDate.compareTo(a.bookingDate),
                          );

                          // Calculate total orders
                          final totalOrders = customerOrders.length;
                          final completedOrders = customerOrders
                              .where((o) => o.isCompleted)
                              .length;
                          final pendingOrders = totalOrders - completedOrders;

                          // Get most recent order date
                          final mostRecentOrder = customerOrders.first;
                          final mostRecentDate =
                              '${mostRecentOrder.bookingDate.day.toString().padLeft(2, '0')}-${mostRecentOrder.bookingDate.month.toString().padLeft(2, '0')}-${(mostRecentOrder.bookingDate.year % 100).toString().padLeft(2, '0')}';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.purple[50],
                                border: Border.all(
                                  color: Colors.purple,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ExpansionTile(
                                collapsedIconColor: Colors.black,
                                iconColor: Colors.black,
                                textColor: Colors.black,
                                collapsedTextColor: Colors.black,
                                leading: CircleAvatar(
                                  backgroundColor: Colors.purple,
                                  child: Text(
                                    customerName.isNotEmpty
                                        ? customerName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  customerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      mobileNumber,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Total Orders: $totalOrders | Completed: $completedOrders | Pending: $pendingOrders',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Last Order: $mostRecentDate',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Previous Orders:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ...customerOrders.map((order) {
                                          int totalItems = 0;
                                          double totalPrice = 0.0;

                                          for (var item in order.items) {
                                            final qty =
                                                int.tryParse(
                                                  item['qty']?.toString() ?? '',
                                                ) ??
                                                0;
                                            final price =
                                                double.tryParse(
                                                  item['price']?.toString() ??
                                                      '',
                                                ) ??
                                                0.0;
                                            final bgqty =
                                                int.tryParse(
                                                  item['bgqty']?.toString() ??
                                                      '',
                                                ) ??
                                                0;
                                            final bgprice =
                                                double.tryParse(
                                                  item['bgitemPrice']
                                                          ?.toString() ??
                                                      '',
                                                ) ??
                                                0.0;

                                            totalItems += qty + bgqty;
                                            totalPrice +=
                                                (price * qty) +
                                                (bgprice * bgqty);
                                          }

                                          final bookingDate =
                                              '${order.bookingDate.day.toString().padLeft(2, '0')}-${order.bookingDate.month.toString().padLeft(2, '0')}-${(order.bookingDate.year % 100).toString().padLeft(2, '0')}';
                                          final deliveryDate =
                                              '${order.deliveryDate.day.toString().padLeft(2, '0')}-${order.deliveryDate.month.toString().padLeft(2, '0')}-${(order.deliveryDate.year % 100).toString().padLeft(2, '0')}';

                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 8,
                                            ),
                                            child: InkWell(
                                              onTap: () async {
                                                await Navigator.of(
                                                  context,
                                                ).push(
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        OrderDetailsPage(
                                                          order: order,
                                                          autoEdit: false,
                                                        ),
                                                  ),
                                                );
                                                setState(() {});
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: order.isCompleted
                                                      ? Colors.green[100]
                                                      : Colors.red[100],
                                                  border: Border.all(
                                                    color: order.isCompleted
                                                        ? Colors.green
                                                        : Colors.red,
                                                    width: 1.5,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Text(
                                                                'Bill No: ${order.billNo}',
                                                                style: const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 14,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 8,
                                                              ),
                                                              Container(
                                                                padding:
                                                                    const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          6,
                                                                      vertical:
                                                                          2,
                                                                    ),
                                                                decoration: BoxDecoration(
                                                                  color:
                                                                      order
                                                                          .isCompleted
                                                                      ? Colors
                                                                            .green
                                                                      : Colors
                                                                            .red,
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        4,
                                                                      ),
                                                                ),
                                                                child: Text(
                                                                  order.isCompleted
                                                                      ? 'Completed'
                                                                      : 'Pending',
                                                                  style: const TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        10,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                            height: 4,
                                                          ),
                                                          Text(
                                                            'Items: $totalItems',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 12,
                                                                ),
                                                          ),
                                                          Text(
                                                            'B.Date: $bookingDate | D.Date: $deliveryDate',
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              color: Colors
                                                                  .grey[700],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Text(
                                                      '₹${totalPrice.toStringAsFixed(0)}',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
