import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tailor_mate/pages/OrderDetails/order_details_provider.dart';
import 'package:tailor_mate/widgets/my_input_field.dart';

// ItemsDetails.dart
class ItemsDetails extends StatelessWidget {
  const ItemsDetails({super.key});

  @override
  Widget build(BuildContext context) {
    void pickDate(BuildContext context, TextEditingController controller) {
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

    return Consumer<OrderDetailsProvider>(
      builder: (context, provider, _) => Scaffold(
        floatingActionButton: provider.isEditing
            ? FloatingActionButton(
                onPressed: provider.addItem,
                child: Icon(Icons.add),
              )
            : null,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(10),
          child: Visibility(
            visible:
                provider.itemNameControllers.isNotEmpty &&
                provider.bgitemControllers.isNotEmpty,
            replacement: Center(
              child: Text('No Items Added', style: TextStyle(fontSize: 20)),
            ),
            child: Column(
              children: List.generate(provider.itemNameControllers.length, (
                index,
              ) {
                return Column(
                  children: [
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Item ${index + 1}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (provider.isEditing)
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => provider.removeItem(index),
                          ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: MyInputField(
                            label: 'Item Name',
                            suggestions: [...provider.itemNameSuggestions],
                            controller: provider.itemNameControllers[index],
                            keyboardType: TextInputType.text,
                            readOnly: !provider.isEditing,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: MyInputField(
                            label: 'Quantity',
                            controller: provider.qtyControllers[index],
                            keyboardType: TextInputType.number,
                            readOnly: !provider.isEditing,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: MyInputField(
                            label: 'Price ₹',
                            controller: provider.priceControllers[index],
                            keyboardType: TextInputType.number,
                            readOnly: !provider.isEditing,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: MyInputField(
                            label: 'Extra item',
                            suggestions: [...provider.bgItemSuggestions],
                            controller: provider.bgitemControllers[index],
                            keyboardType: TextInputType.text,
                            readOnly: !provider.isEditing,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: MyInputField(
                            label: 'Quantity',
                            controller: provider.bgqtyControllers[index],
                            keyboardType: TextInputType.number,
                            readOnly: !provider.isEditing,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: MyInputField(
                            label: 'Price ₹',
                            controller: provider.bgitemPriceControllers[index],
                            keyboardType: TextInputType.number,
                            readOnly: !provider.isEditing,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: MyInputField(
                            suggestions: [...provider.workerSuggestions],
                            label: 'Worker',
                            controller: provider.workerControllers[index],
                            keyboardType: TextInputType.text,
                            readOnly: !provider.isEditing,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: MyInputField(
                            label: 'Date',
                            onTap: () {
                              // Handle onTap for Date field
                              if (provider.isEditing) {
                                pickDate(
                                  context,
                                  provider.wdateControllers[index],
                                );
                              }
                            },
                            controller: provider.wdateControllers[index],
                            keyboardType: TextInputType.datetime,
                            readOnly: true,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: MyInputField(
                            label: 'Labour ₹',
                            controller: provider.labourControllers[index],
                            keyboardType: TextInputType.number,
                            readOnly: !provider.isEditing,
                          ),
                        ),
                      ],
                    ),
                    const Divider(thickness: 1),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
