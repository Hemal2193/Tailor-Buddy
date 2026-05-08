import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tailor_mate/pages/New%20Order/new_order_provider.dart';
import 'package:tailor_mate/widgets/input_fields.dart';

class ItemsPage extends StatefulWidget {
  const ItemsPage({super.key});

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<NewOrderProvider>(context, listen: false);
      provider.loadSuggestions();
    });
  }

  void _pickDate(TextEditingController controller) {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    ).then((selectedDate) {
      if (selectedDate != null) {
        controller.text =
            '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${(selectedDate.year % 100).toString().padLeft(2, '0')}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NewOrderProvider>(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: provider.nameControllers.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Item ${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: InputField(
                                suggestions: [...provider.itemNameSuggestions],
                                label: 'Item Name',
                                controller: provider.nameControllers[index],
                                keyboardType: TextInputType.text,
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: InputField(
                                label: 'Quantity',
                                controller: provider.qtyControllers[index],
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: InputField(
                                label: 'Price ₹',
                                controller: provider.priceControllers[index],
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: InputField(
                                suggestions: [...provider.bgItemSuggestions],
                                label: 'Extra item',
                                controller: provider.bgitemControllers[index],
                                keyboardType: TextInputType.text,
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: InputField(
                                label: 'Quantity',
                                controller: provider.bgqtyControllers[index],
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: InputField(
                                label: 'Price ₹',
                                controller:
                                    provider.bgitemPriceControllers[index],
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: InputField(
                                suggestions: [...provider.workerSuggestions],
                                label: 'Worker',
                                controller: provider.workerControllers[index],
                                keyboardType: TextInputType.text,
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 15),
                                child: TextField(
                                  readOnly: true,
                                  onTapOutside: (event) =>
                                      FocusScope.of(context).unfocus(),
                                  onTap: () => _pickDate(
                                    provider.wdateControllers[index],
                                  ),
                                  controller: provider.wdateControllers[index],
                                  decoration: InputDecoration(
                                    labelText: 'Date',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: InputField(
                                label: 'Labour ₹',
                                controller: provider.labourControllers[index],
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        Container(height: 1, color: Colors.black),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: ElevatedButton(
                onPressed: provider.addItem,
                child: Text('Add New Item'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
