import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tailor_mate/pages/New%20Order/ctmr_details_page.dart';
import 'package:tailor_mate/pages/New%20Order/items_page.dart';
import 'package:tailor_mate/pages/New%20Order/new_order_provider.dart';
import 'package:tailor_mate/pages/New%20Order/notes_page.dart';

class NewOrderPage extends StatefulWidget {
  const NewOrderPage({super.key});

  @override
  State<NewOrderPage> createState() => _NewOrderPageState();
}

class _NewOrderPageState extends State<NewOrderPage> {
  @override
  void initState() {
    super.initState();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   final provider = Provider.of<NewOrderProvider>(context, listen: false);
    //   provider.generateNewOrderId(); // async call AFTER build context is ready
    // });
  }

  @override
  Widget build(BuildContext context) {
    final providerMethods = context.read<NewOrderProvider>();
    return Consumer<NewOrderProvider>(
      builder: (context, provider, child) => DefaultTabController(
        length: 3,
        initialIndex: 0,
        child: Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                icon: Icon(Icons.save, color: Colors.white),
                onPressed: () {
                  providerMethods.saveOrder(context);
                },
              ),
            ],
            title: Text(
              'Create New Order',
              style: const TextStyle(color: Colors.white),
            ),
            centerTitle: false,
            backgroundColor: Colors.blue,
            elevation: 0,
          ),
          body: Column(
            children: [
              Container(
                color: Colors.blue,
                child: TabBar(
                  indicatorAnimation: TabIndicatorAnimation.elastic,
                  unselectedLabelColor: Colors.grey.shade300,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  indicatorColor: Colors.white,
                  indicatorWeight: 4,
                  tabs: const [
                    Tab(
                      child: Text(
                        'Details',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    Tab(
                      child: Text(
                        'Items',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    Tab(
                      child: Text(
                        'Notes',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    CustomerDetailsPage(),
                    ItemsPage(),
                    NotesPage(orderId: provider.orderid),
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
