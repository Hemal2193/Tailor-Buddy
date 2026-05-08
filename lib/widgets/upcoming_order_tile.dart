import 'package:flutter/material.dart';
import 'package:tailor_mate/database/order_model.dart';
import 'package:tailor_mate/pages/OrderDetails/order_details.dart';

class UpcomingOrderTile extends StatelessWidget {
  final List<Order> orders;

  const UpcomingOrderTile({super.key, required this.orders});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Filter only upcoming orders
    final upcomingOrders = orders.where((order) => !order.isCompleted).toList();

    if (upcomingOrders.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue),
            borderRadius: BorderRadius.circular(8),
            color: Colors.blue.shade50,
          ),
          child: Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 10),
                Text(
                  'No upcoming orders.',
                  style: TextStyle(color: Colors.blue),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Sort by nearest delivery date
    upcomingOrders.sort((a, b) => a.deliveryDate.compareTo(b.deliveryDate));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        children: upcomingOrders.take(3).map<Widget>((order) {
          int totalItems = 0;
          double totalPrice = 0.0;

          // Calculate totals with bgqty + bgitemPrice
          for (var item in order.items) {
            final qty = int.tryParse(item['qty']?.toString() ?? '0') ?? 0;
            final price =
                double.tryParse(item['price']?.toString() ?? '0.0') ?? 0.0;

            final bgqty = int.tryParse(item['bgqty']?.toString() ?? '0') ?? 0;
            final bgitemPrice =
                double.tryParse(item['bgitemPrice']?.toString() ?? '0.0') ??
                0.0;

            totalItems += qty + bgqty;
            totalPrice += (qty * price) + (bgqty * bgitemPrice);
          }

          // Apply discount and advance payment
          final discount = order.discount ?? 0.0;
          final advancePayment = order.advancePayment;
          totalPrice = totalPrice - discount - advancePayment;
          if (totalPrice < 0) totalPrice = 0.0;

          // Format dates
          final bookingDate =
              '${order.bookingDate.day.toString().padLeft(2, '0')}-${order.bookingDate.month.toString().padLeft(2, '0')}-${(order.bookingDate.year % 100).toString().padLeft(2, '0')}';
          final deliveryStr =
              '${order.deliveryDate.day.toString().padLeft(2, '0')}-${order.deliveryDate.month.toString().padLeft(2, '0')}-${(order.deliveryDate.year % 100).toString().padLeft(2, '0')}';

          // Days left until delivery
          final daysLeft = order.deliveryDate.difference(today).inDays;

          return Padding(
            padding: const EdgeInsets.only(left: 5.0, right: 5.0, bottom: 12),
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
                              style: const TextStyle(
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
        }).toList(),
      ),
    );
  }
}
