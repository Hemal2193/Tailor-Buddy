import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class WorkerManagementPage extends StatefulWidget {
  const WorkerManagementPage({super.key});

  @override
  State<WorkerManagementPage> createState() => _WorkerManagementPageState();
}

class _WorkerManagementPageState extends State<WorkerManagementPage> {
  Map<String, WorkerStats> workerMap = {};

  @override
  void initState() {
    super.initState();
    loadWorkerStats();
  }

  void loadWorkerStats() {
    final ordersBox = Hive.box('orders');

    for (var order in ordersBox.values) {
      for (var item in order.items) {
        final worker = item['worker']?.toString().trim() ?? '';
        if (worker.isEmpty) continue;

        final qty = int.tryParse(item['qty'].toString()) ?? 0;
        final bgname = item['bgitem']?.toString().trim() ?? '';
        final bgqty = int.tryParse(item['bgqty'].toString()) ?? 0;
        final labour = double.tryParse(item['labour'].toString()) ?? 0.0;
        final name = item['name']?.toString().trim() ?? '';
        final wdate = item['wdate']?.toString() ?? '';

        workerMap.putIfAbsent(worker, () => WorkerStats(name: worker));
        final workerStats = workerMap[worker]!;

        workerStats.totalItems += qty + bgqty;
        qty == 0
            ? workerStats.totalLabour += labour * bgqty
            : workerStats.totalLabour += labour * qty;
        workerStats.dates.add(wdate);

        // Combine name and bgitem without duplication
        final itemNames = <String, int>{};
        if (name.isNotEmpty) {
          itemNames[name] = qty;
        }
        if (bgname.isNotEmpty) {
          itemNames[bgname] = (itemNames[bgname] ?? 0) + bgqty;
        }

        // Update final item breakdown
        itemNames.forEach((itemName, totalQty) {
          workerStats.itemsCount.update(
            itemName,
            (val) => val + totalQty,
            ifAbsent: () => totalQty,
          );
        });
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final workers = workerMap.values.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Worker Management')),
      body: workers.isEmpty
          ? const Center(child: Text("No worker data found."))
          : ListView.builder(
              itemCount: workers.length,
              itemBuilder: (context, index) {
                final worker = workers[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      border: Border.all(color: Colors.blue, width: 2),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade300,
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            worker.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text('Total items: ${worker.totalItems}'),
                          Text(
                            'Total labour: ₹${worker.totalLabour.toStringAsFixed(2)}',
                          ),
                          Text(
                            'Worked on ${worker.dates.length} ${worker.dates.length == 1 ? 'day' : 'days'}',
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Item Breakdown:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          ...worker.itemsCount.entries.map(
                            (e) => Text('• ${e.key}: ${e.value} pcs'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class WorkerStats {
  final String name;
  int totalItems = 0;
  double totalLabour = 0.0;
  List<String> dates = [];
  Map<String, int> itemsCount = {};

  WorkerStats({required this.name});
}
