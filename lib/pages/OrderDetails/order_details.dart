// ignore_for_file: use_build_context_synchronously

// OrderDetailsPage.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tailor_mate/database/order_model.dart';
import 'package:tailor_mate/pages/OrderDetails/items_details.dart';
import 'package:tailor_mate/pages/OrderDetails/notes_details.dart';
import 'package:tailor_mate/pages/OrderDetails/order_custmr_details.dart';
import 'package:tailor_mate/pages/OrderDetails/order_details_provider.dart';
import 'package:tailor_mate/pages/bill.dart';

class OrderDetailsPage extends StatefulWidget {
  final Order order;
  final bool autoEdit;

  const OrderDetailsPage({
    super.key,
    required this.order,
    required this.autoEdit,
  });

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  // ----------------- 🔹 DELETE ORDER -----------------
  void deleteOrder(Order order) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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

                      navigator.pop(); // Close the dialog
                      navigator.pop(); // Go back from OrderDetailsPage

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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<OrderDetailsProvider>(context, listen: false);
    provider.initialize(widget.order, widget.autoEdit);

    return DefaultTabController(
      length: 3,
      child: Consumer<OrderDetailsProvider>(
        builder: (context, provider, _) => Scaffold(
          appBar: AppBar(
            title: Text(
              provider.isEditing ? 'Editing Order' : 'Order Details',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.blue,
            elevation: 0,
            actions: [
              if (provider.isEditing)
                IconButton(
                  icon: Icon(Icons.check),
                  onPressed: () async {
                    await provider.saveChanges(context);
                  },
                )
              else
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert),
                  position: PopupMenuPosition.under,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      provider.toggleEdit();
                    } else if (value == 'bill') {
                      final status = await Permission.manageExternalStorage
                          .request();
                      if (!status.isGranted) {
                        print('❌ Storage permission not granted.');
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              BillImageView(orderId: widget.order.id),
                        ),
                      );
                    } else if (value == 'toggle_complete') {
                      final oldValue = widget.order.isCompleted;
                      setState(() {
                        widget.order.isCompleted = !widget.order.isCompleted;
                      });
                      await widget.order.save();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            widget.order.isCompleted
                                ? 'Order marked as completed'
                                : 'Order marked as pending',
                          ),
                          action: SnackBarAction(
                            label: 'Undo',
                            onPressed: () async {
                              setState(() {
                                widget.order.isCompleted = oldValue;
                              });
                              await widget.order.save();
                            },
                          ),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    } else if (value == 'delete') {
                      deleteOrder(widget.order);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'bill',
                      child: Row(
                        children: [
                          Icon(Icons.fact_check_outlined, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Bill'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'toggle_complete',
                      child: Row(
                        children: [
                          Icon(
                            widget.order.isCompleted
                                ? Icons.pending_actions
                                : Icons.check_circle,
                            color: widget.order.isCompleted
                                ? Colors.orange
                                : Colors.green,
                          ),
                          SizedBox(width: 8),
                          Text(
                            widget.order.isCompleted
                                ? 'Mark as pending'
                                : 'Mark as completed',
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          body: Column(
            children: [
              Container(
                color: Colors.blue,
                child: const TabBar(
                  indicatorColor: Colors.white,
                  indicatorWeight: 4,
                  unselectedLabelColor: Colors.white70,
                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                  tabs: [
                    Tab(text: 'Details'),
                    Tab(text: 'Items'),
                    Tab(text: 'Notes'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    OrderCustmrDetailsPage(orderId: widget.order.id),
                    ItemsDetails(),
                    NotesDetails(orderId: provider.order.id),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
