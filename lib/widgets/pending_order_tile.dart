import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tailor_mate/database/order_model.dart';
import 'package:tailor_mate/pages/OrderDetails/order_details_provider.dart';
import 'package:tailor_mate/pages/bill.dart';

class PendingOrderTile extends StatefulWidget {
  final List<Order> orders;
  final Function(Order) onTap;
  final Function(Order) onDelete;
  final void Function(String, bool) onOrderUpdated;

  const PendingOrderTile({
    super.key,
    required this.orders,
    required this.onTap,
    required this.onDelete,
    required this.onOrderUpdated,
  });

  @override
  State<PendingOrderTile> createState() => _PendingOrderTileState();
}

class _PendingOrderTileState extends State<PendingOrderTile> {
  // Track which order ids are currently animating out
  final Set<dynamic> _animatingIds = {};

  // animation duration used in multiple places
  static const Duration _animationDuration = Duration(milliseconds: 350);

  @override
  Widget build(BuildContext context) {
    // only orders that are not completed should be shown as pending
    final pendingOrders = widget.orders;

    if (pendingOrders.isEmpty) {
      return const Center(child: Text('No pending orders.'));
    }

    // reverse pendingOrders if you want latest first (same behaviour as before but correct)
    final reversedPendingOrders = pendingOrders.reversed.toList();

    return ListView.builder(
      itemCount: reversedPendingOrders.length,
      itemBuilder: (context, index) {
        final order = reversedPendingOrders[index];

        final isAnimating = _animatingIds.contains(order.id);
        final isChecked = order.isCompleted;

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

        return AnimatedOpacity(
          key: ValueKey(order.id),
          duration: _animationDuration,
          opacity: isAnimating ? 0.0 : 1.0,
          curve: Curves.easeInOut,
          child: AnimatedSlide(
            duration: _animationDuration,
            curve: Curves.easeInOut,
            offset: isAnimating ? const Offset(0.3, 0) : Offset.zero,
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
                          // permission not granted, bail out
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
                      color: Colors.red.shade50,
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

                                // mark this item as animating so Animated widgets use that state
                                setState(() {
                                  _animatingIds.add(order.id);
                                });

                                // play fade/slide animation delay
                                await Future.delayed(_animationDuration);

                                // update the order, save
                                setState(() {
                                  order.isCompleted = checked;
                                });
                                await order.save();

                                // Show snackbar with Undo option
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

                                // notify parent after animation
                                widget.onOrderUpdated(
                                  order.id,
                                  order.isCompleted,
                                );

                                if (mounted) {
                                  setState(() {
                                    _animatingIds.remove(order.id);
                                  });
                                }
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
