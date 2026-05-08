import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:tailor_mate/database/order_model.dart';
import 'package:tailor_mate/pages/OrderDetails/order_details.dart';

class CompletedOrderPage extends StatelessWidget {
  const CompletedOrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Order> orders = Hive.box('orders').values.cast<Order>().toList();

    // final now = DateTime.now();
    // final today = DateTime(now.year, now.month, now.day);

    final completedOrders = orders.where((order) => order.isCompleted).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Completed Orders'), elevation: 0),
      body: completedOrders.isEmpty
          ? const Center(child: Text('No completed orders.'))
          : ListView.builder(
              itemCount: completedOrders.length,
              itemBuilder: (context, index) {
                final order = completedOrders.reversed.toList()[index];

                int totalItems = 0;
                double totalPrice = 0.0;

                for (var item in order.items) {
                  final qty = int.tryParse(item['qty']?.toString() ?? '') ?? 1;
                  final price =
                      double.tryParse(item['price']?.toString() ?? '') ?? 0.0;
                  totalItems += qty;
                  totalPrice += price * qty;

                  // Include bgitem in totals, without showing it in UI
                  if ((item['bgitem']?.toString().isNotEmpty ?? false)) {
                    final bq =
                        int.tryParse(item['bgqty']?.toString() ?? '') ?? 1;
                    final bp =
                        double.tryParse(
                          item['bgitemPrice']?.toString() ?? '',
                        ) ??
                        0.0;
                    totalItems += bq;
                    totalPrice += bp * bq;
                  }
                }

                final bookingDate =
                    '${order.bookingDate.day.toString().padLeft(2, '0')}-${order.bookingDate.month.toString().padLeft(2, '0')}-${(order.bookingDate.year % 100).toString().padLeft(2, '0')}';
                final deliveryDate =
                    '${order.deliveryDate.day.toString().padLeft(2, '0')}-${order.deliveryDate.month.toString().padLeft(2, '0')}-${(order.deliveryDate.year % 100).toString().padLeft(2, '0')}';

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
                        color: Colors.green[50],
                        border: Border.all(color: Colors.green, width: 2),
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
                                    order.customerName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                  Text('Items: $totalItems'),
                                  Text('B.Date: $bookingDate'),
                                  Text('D.Date: $deliveryDate'),
                                ],
                              ),
                            ),
                            Text(
                              '₹${totalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
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
