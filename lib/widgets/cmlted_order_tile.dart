import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tailor_mate/database/order_model.dart';
import 'package:tailor_mate/pages/OrderDetails/order_details_provider.dart';
import 'package:tailor_mate/pages/bill.dart'; // BillImageView assumed here

class CompletedOrderTile extends StatefulWidget {
  final List<Order> orders;
  final Function(Order) onTap;
  final Function(Order) onDelete;
  final void Function(String, bool) onOrderUpdated;

  const CompletedOrderTile({
    super.key,
    required this.orders,
    required this.onTap,
    required this.onDelete,
    required this.onOrderUpdated,
  });

  @override
  State<CompletedOrderTile> createState() => _CompletedOrderTileState();
}

class _CompletedOrderTileState extends State<CompletedOrderTile> {
  @override
  Widget build(BuildContext context) {
    if (widget.orders.isEmpty) {
      return const Center(child: Text('No completed orders.'));
    }

    // Reverse the list for latest orders first
    final reversedOrders = widget.orders.reversed.toList();

    return ListView.builder(
      itemCount: reversedOrders.length,
      itemBuilder: (context, index) {
        final order = reversedOrders[index];

        int totalItems = 0;
        double totalPrice = 0.0;

        for (var item in order.items) {
          final qty = int.tryParse(item['qty']?.toString() ?? '0') ?? 0;
          final price =
              double.tryParse(item['price']?.toString() ?? '0.0') ?? 0.0;
          final bgitemprice =
              double.tryParse(item['bgitemPrice']?.toString() ?? '0.0') ?? 0.0;
          final bgqty = int.tryParse(item['bgqty']?.toString() ?? '0') ?? 0;

          totalItems += qty + bgqty;
          totalPrice += (qty * price) + (bgitemprice * bgqty);
        }

        final discount = order.discount ?? 0.0;

        totalPrice = totalPrice - discount;
        totalPrice = totalPrice < 0 ? 0.0 : totalPrice;

        double fullTotal = totalPrice + discount;
        double remainingAmount =
            fullTotal -
            discount -
            (order.advancePayment) -
            (order.paidAmount ?? 0);
        PaymentStatus paymentStatus = remainingAmount <= 0
            ? PaymentStatus.paid
            : remainingAmount < fullTotal
            ? PaymentStatus.partial
            : PaymentStatus.unpaid;

        final orderDeliveryDate = order.deliveryDate;
        final orderBookingDate = order.bookingDate;

        final deliveryDate =
            '${orderDeliveryDate.day.toString().padLeft(2, '0')}-${orderDeliveryDate.month.toString().padLeft(2, '0')}-${(orderDeliveryDate.year % 100).toString().padLeft(2, '0')}';
        final bookingDate =
            '${orderBookingDate.day.toString().padLeft(2, '0')}-${orderBookingDate.month.toString().padLeft(2, '0')}-${(orderBookingDate.year % 100).toString().padLeft(2, '0')}';
        final isChecked = order.isCompleted;

        // Animation duration used for both opacity/slide and the delayed refresh
        const animationDuration = Duration(milliseconds: 350);

        return AnimatedOpacity(
          key: ValueKey(order.id),
          duration: animationDuration,
          opacity: order.isCompleted
              ? 1.0
              : 0.0, // show while completed, fade out when unchecked
          curve: Curves.easeInOut,
          child: AnimatedSlide(
            duration: animationDuration,
            curve: Curves.easeInOut,
            // Slide to left when unchecked (negative x offset)
            offset: order.isCompleted ? Offset.zero : const Offset(-0.3, 0),
            child: Padding(
              padding: const EdgeInsets.only(
                top: 10,
                left: 10,
                right: 10,
                bottom: 5,
              ),
              child: Slidable(
                closeOnScroll: true,
                endActionPane: ActionPane(
                  extentRatio: 0.3,
                  motion: const BehindMotion(),
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.fact_check_outlined,
                        color: Colors.blue,
                        size: 30,
                      ),
                      onPressed: () async {
                        final status = await Permission.manageExternalStorage
                            .request();
                        if (!status.isGranted) {
                          print('❌ Storage permission not granted.');
                          return;
                        }
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                BillImageView(orderId: order.id),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.redAccent,
                        size: 30,
                      ),
                      onPressed: () {
                        widget.onDelete(order);
                        Slidable.of(context)?.close();
                      },
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () => widget.onTap(order),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
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
                          Container(
                            height: 60,
                            width: 4,
                            color: paymentStatus == PaymentStatus.paid
                                ? Colors.green
                                : paymentStatus == PaymentStatus.partial
                                ? Colors.blue
                                : Colors.red,
                          ),
                          SizedBox(width: 10),
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
                          Transform.scale(
                            scale: 1.1,
                            child: Checkbox(
                              value: isChecked,
                              onChanged: (checked) async {
                                if (checked == null) return;
                                final oldValue = order.isCompleted;

                                // Update state to animating if you have such logic
                                setState(() {
                                  order.isCompleted = checked;
                                });

                                await order.save(); // save changes to Hive

                                // Show Undo Snackbar
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      checked
                                          ? 'Order marked as completed'
                                          : 'Order marked as pending',
                                    ),
                                    action: SnackBarAction(
                                      label: 'Undo',
                                      onPressed: () async {
                                        setState(() {
                                          order.isCompleted = oldValue;
                                        });
                                        await order.save();
                                        widget.onOrderUpdated(
                                          order.id,
                                          order.isCompleted,
                                        );
                                      },
                                    ),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );

                                // Delay parent refresh to let animation play (same timing as pending tile)
                                Future.delayed(animationDuration, () {
                                  widget.onOrderUpdated(
                                    order.id,
                                    order.isCompleted,
                                  );
                                });
                              },
                              activeColor: Colors.green,
                              side: BorderSide(
                                color: isChecked ? Colors.green : Colors.red,
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.padded,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
