// import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import 'package:tailor_mate/database/order_model.dart';
import 'package:tailor_mate/pages/OrderDetails/order_details.dart';

class TodaysDelivery extends StatelessWidget {
  final List<Order> orders;

  const TodaysDelivery({super.key, required this.orders});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Filter only today's deliveries
    final todaysOrders = orders.where((order) {
      final delivery = DateTime(
        order.deliveryDate.year,
        order.deliveryDate.month,
        order.deliveryDate.day,
      );
      return delivery == today;
    }).toList();

    // If no deliveries today, show your old box
    if (todaysOrders.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue),
            borderRadius: BorderRadius.circular(8),
            color: Colors.blue.shade50,
          ),
          child: const Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 10),
                Text(
                  'No deliveries scheduled for today.',
                  style: TextStyle(color: Colors.blue),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Otherwise, show a list of today's deliveries

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListView.builder(
            itemCount: todaysOrders.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final order = todaysOrders.reversed.toList()[index];

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
                  final bq = int.tryParse(item['bgqty']?.toString() ?? '') ?? 1;
                  final bp =
                      double.tryParse(item['bgitemPrice']?.toString() ?? '') ??
                      0.0;
                  totalItems += bq;
                  totalPrice += bp * bq;
                }
              }

              final bookingDate =
                  '${order.bookingDate.day.toString().padLeft(2, '0')}-${order.bookingDate.month.toString().padLeft(2, '0')}-${(order.bookingDate.year % 100).toString().padLeft(2, '0')}';
              final deliveryDate =
                  '${order.deliveryDate.day.toString().padLeft(2, '0')}-${order.deliveryDate.month.toString().padLeft(2, '0')}-${(order.deliveryDate.year % 100).toString().padLeft(2, '0')}';
              final isChecked = order.isCompleted;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5.0),
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
                      color: isChecked ? Colors.green[50] : Colors.red[50],
                      border: Border.all(
                        color: isChecked ? Colors.green : Colors.red,
                        width: 2,
                      ),
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
        ],
      ),
    );
  }
}
