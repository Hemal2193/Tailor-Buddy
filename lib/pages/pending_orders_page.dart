import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:tailor_mate/database/order_model.dart';
import 'package:tailor_mate/pages/OrderDetails/order_details.dart';

class PendingOrdersPage extends StatelessWidget {
  const PendingOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Order> orders = Hive.box('orders').values.cast<Order>().toList();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final upcomingOrders = orders.where((order) => !order.isCompleted).toList();

    // Sort by nearest delivery
    upcomingOrders.sort((a, b) => a.deliveryDate.compareTo(b.deliveryDate));

    return Scaffold(
      appBar: AppBar(title: Text('Pending Orders'), elevation: 0),
      body: upcomingOrders.isEmpty
          ? const Center(child: Text('No upcoming orders.'))
          : ListView.builder(
              itemCount: upcomingOrders.length,
              itemBuilder: (context, index) {
                final order = upcomingOrders[index];

                int totalItems = 0;
                double totalPrice = 0.0;

                for (var item in order.items) {
                  final qty = int.tryParse(item['qty'].toString()) ?? 1;
                  final price =
                      double.tryParse(item['price'].toString()) ?? 0.0;
                  totalItems += qty;
                  totalPrice += price * qty;
                }

                final deliveryDate = DateTime(
                  order.deliveryDate.year,
                  order.deliveryDate.month,
                  order.deliveryDate.day,
                );
                final bookingDate =
                    '${order.bookingDate.day.toString().padLeft(2, '0')}-${order.bookingDate.month.toString().padLeft(2, '0')}-${(order.bookingDate.year % 100).toString().padLeft(2, '0')}';
                final deliveryStr =
                    '${order.deliveryDate.day.toString().padLeft(2, '0')}-${order.deliveryDate.month.toString().padLeft(2, '0')}-${(order.deliveryDate.year % 100).toString().padLeft(2, '0')}';

                final daysLeft = deliveryDate.difference(today).inDays;

                return Padding(
                  padding: const EdgeInsets.only(
                    top: 10,
                    left: 10,
                    right: 10,
                    bottom: 5,
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              OrderDetailsPage(order: order, autoEdit: false),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        border: Border.all(color: Colors.red, width: 2),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade400,
                            spreadRadius: 1,
                            blurRadius: 2,
                            offset: const Offset(4, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${order.customerName} | ${daysLeft < 0 ? '${-daysLeft} day${-daysLeft == 1 ? '' : 's'} overdue' : '$daysLeft day${daysLeft == 1 ? '' : 's'} left'}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                  Text('Items: $totalItems'),
                                  Text('B.Date: $bookingDate'),
                                  Text('D.Date: $deliveryStr'),
                                ],
                              ),
                            ),
                            Text(
                              '₹${totalPrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
