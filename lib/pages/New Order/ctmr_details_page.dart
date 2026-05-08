import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tailor_mate/pages/New%20Order/new_order_provider.dart';
import 'package:tailor_mate/widgets/input_fields.dart';

class CustomerDetailsPage extends StatefulWidget {
  const CustomerDetailsPage({super.key});

  @override
  State<CustomerDetailsPage> createState() => _CustomerDetailsPageState();
}

class _CustomerDetailsPageState extends State<CustomerDetailsPage> {
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
    return Consumer<NewOrderProvider>(
      builder: (context, provider, _) {
        final isAdvanceCash =
            provider.isAdvanceCash; // You can access this safely now
        final isPaidCash = provider.isPaidCash;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // InputField(
                //   label: 'Bill No',
                //   controller: provider.billNoController,
                //   keyboardType: TextInputType.number,
                // ),
                ExpansionTile(
                  title: Text(
                    "Customer Details",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  initiallyExpanded: false,
                  collapsedTextColor: Colors.black,
                  textColor: Colors.black,
                  collapsedIconColor: Colors.black,
                  iconColor: Colors.black,

                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15.0),
                      child: Consumer<NewOrderProvider>(
                        builder: (context, provider, _) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 5),
                              if (provider.billNoExists)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Text(
                                    "This Bill No already exists",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              TextField(
                                onTapOutside: (event) =>
                                    FocusScope.of(context).unfocus(),
                                onChanged: (value) {
                                  provider.checkBillNoExists(value);
                                },
                                controller: provider.billNoController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Bill No',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    InputField(
                      label: 'Customer Name',
                      controller: provider.customerNameController,
                      keyboardType: TextInputType.text,
                    ),
                    InputField(
                      label: 'Customer Mobile No',
                      controller: provider.customerMobileController,
                      keyboardType: TextInputType.phone,
                    ),
                    InputField(
                      label: 'Customer Address',
                      controller: provider.customerAddressController,
                      keyboardType: TextInputType.text,
                    ),
                    TextField(
                      readOnly: true,
                      onTapOutside: (event) => FocusScope.of(context).unfocus(),
                      onTap: () => _pickDate(provider.bookingDateController),
                      controller: provider.bookingDateController,
                      decoration: InputDecoration(
                        labelText: 'Booking Date',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 15),
                    TextField(
                      readOnly: true,
                      onTapOutside: (event) => FocusScope.of(context).unfocus(),
                      onTap: () => _pickDate(provider.deliveryDateController),
                      controller: provider.deliveryDateController,
                      decoration: InputDecoration(
                        labelText: 'Delivery Date',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 15),
                    InputField(
                      label: 'Notes',
                      controller: provider.notesController,
                      keyboardType: TextInputType.text,
                    ),
                  ],
                ),
                ExpansionTile(
                  title: Text(
                    'Payment Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  initiallyExpanded: false,
                  collapsedTextColor: Colors.black,
                  textColor: Colors.black,
                  collapsedIconColor: Colors.black,
                  iconColor: Colors.black,
                  children: [
                    SizedBox(height: 5),
                    InputField(
                      label: 'Discount',
                      controller: provider.discountController,
                      keyboardType: TextInputType.number,
                    ),
                    InputField(
                      label: 'Advance Amount',
                      controller: provider.advanceAmountController,
                      keyboardType: TextInputType.number,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: TextField(
                            readOnly: true,
                            onTapOutside: (event) =>
                                FocusScope.of(context).unfocus(),
                            onTap: () =>
                                _pickDate(provider.advanceAmountDateController),
                            controller: provider.advanceAmountDateController,
                            decoration: InputDecoration(
                              labelText: 'Advance Date',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(width: 20),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () {
                                provider.setAdvancePaymentMode(true);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 15,
                                ),
                                decoration: BoxDecoration(
                                  color: isAdvanceCash
                                      ? Colors.blue.shade400
                                      : Colors.grey.shade300,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(5),
                                    bottomLeft: Radius.circular(5),
                                  ),
                                ),
                                child: Text(
                                  'Cash',
                                  style: TextStyle(
                                    color: isAdvanceCash
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: isAdvanceCash
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                provider.setAdvancePaymentMode(false);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 15,
                                ),
                                decoration: BoxDecoration(
                                  color: !isAdvanceCash
                                      ? Colors.blue.shade400
                                      : Colors.grey.shade300,
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(5),
                                    bottomRight: Radius.circular(5),
                                  ),
                                ),
                                child: Text(
                                  'Online',
                                  style: TextStyle(
                                    color: !isAdvanceCash
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: !isAdvanceCash
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    InputField(
                      label: 'Paid Amount',
                      controller: provider.paidAmountController,
                      keyboardType: TextInputType.number,
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: TextField(
                            readOnly: true,
                            onTapOutside: (event) =>
                                FocusScope.of(context).unfocus(),
                            onTap: () =>
                                _pickDate(provider.paidAmountDateController),
                            controller: provider.paidAmountDateController,
                            decoration: InputDecoration(
                              labelText: 'Payment Date',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(width: 20),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () {
                                provider.setPaidPaymentMode(true);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 15,
                                ),
                                decoration: BoxDecoration(
                                  color: isPaidCash
                                      ? Colors.blue.shade400
                                      : Colors.grey.shade300,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(5),
                                    bottomLeft: Radius.circular(5),
                                  ),
                                ),
                                child: Text(
                                  'Cash',
                                  style: TextStyle(
                                    color: isPaidCash
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: isPaidCash
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                provider.setPaidPaymentMode(false);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 15,
                                ),
                                decoration: BoxDecoration(
                                  color: !isPaidCash
                                      ? Colors.blue.shade400
                                      : Colors.grey.shade300,
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(5),
                                    bottomRight: Radius.circular(5),
                                  ),
                                ),
                                child: Text(
                                  'Online',
                                  style: TextStyle(
                                    color: !isPaidCash
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: !isPaidCash
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
