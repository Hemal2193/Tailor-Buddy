import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:tailor_mate/pages/OrderDetails/order_details_provider.dart';
import 'package:tailor_mate/widgets/my_input_field.dart';
import 'package:url_launcher/url_launcher.dart';

// OrderCustmrDetailsPage.dart
class OrderCustmrDetailsPage extends StatefulWidget {
  final String orderId;
  const OrderCustmrDetailsPage({super.key, required this.orderId});

  @override
  State<OrderCustmrDetailsPage> createState() => _OrderCustmrDetailsPageState();
}

class _OrderCustmrDetailsPageState extends State<OrderCustmrDetailsPage> {
  @override
  void initState() {
    super.initState();
    // Delay to ensure context is ready for provider access
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box = Hive.box('orders');
      final latestOrder = box.get(widget.orderId);
      if (latestOrder != null) {
        final provider = Provider.of<OrderDetailsProvider>(
          context,
          listen: false,
        );
        provider.initialize(
          latestOrder,
          false,
        ); // or true if you want auto-editing
      }
    });
  }

  void _pickDate(BuildContext context, TextEditingController controller) {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    ).then((selectedDate) {
      if (selectedDate != null) {
        controller.text =
            '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderDetailsProvider>(
      builder: (context, provider, _) {
        final isAdvanceCash =
            provider.isAdvanceCash; // You can access this safely now
        final isPaidCash = provider.isPaidCash;
        return Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                ExpansionTile(
                  collapsedIconColor: Colors.black,
                  collapsedTextColor: Colors.black,
                  iconColor: Colors.black,
                  textColor: Colors.black,
                  title: const Text(
                    'Customer Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  children: [
                    // SizedBox(height: 5,),
                    // MyInputField(
                    //   label: 'Bill No',
                    //   controller: provider.billNoController,
                    //   keyboardType: TextInputType.number,
                    //   readOnly: !provider.isEditing,
                    // ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15.0),
                      child: Consumer<OrderDetailsProvider>(
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
                    MyInputField(
                      label: 'Customer Name',
                      controller: provider.nameController,
                      keyboardType: TextInputType.text,
                      readOnly: !provider.isEditing,
                    ),
                    MyInputField(
                      label: 'Customer Mobile No',
                      controller: provider.mobileController,
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.contacts_outlined),
                            onPressed: () async {
                              String raw = provider.mobileController.text
                                  .trim();
                              String name = provider.nameController.text.trim();

                              if (raw.isEmpty || name.isEmpty) return;

                              // Clean the mobile number
                              String mobile = raw.replaceFirst(
                                RegExp(r'^\+91[-\s]?'),
                                '',
                              );
                              mobile = mobile.replaceAll(
                                RegExp(r'\D'),
                                '',
                              ); // remove non-digits

                              // Ask for contact permissions
                              if (!await FlutterContacts.requestPermission()) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Contacts permission denied'),
                                  ),
                                );
                                return;
                              }
                              // Skip contact existence check
                              // Just open contact saver UI directly
                              final newContact = Contact()
                                ..name.first = name
                                ..phones = [Phone(mobile)];
                              await FlutterContacts.openExternalInsert(
                                newContact,
                              );
                            },
                          ),

                          IconButton(
                            icon: const Icon(Icons.call_outlined),
                            tooltip: 'Call Customer',
                            onPressed: () async {
                              String number = provider.mobileController.text
                                  .trim();
                              // Clean number (same logic as your contact save)
                              number = number.replaceFirst(
                                RegExp(r'^\+91[-\s]?'),
                                '',
                              );
                              number = number.replaceAll(RegExp(r'\D'), '');

                              if (number.isEmpty) return;

                              final Uri callUri = Uri(
                                scheme: 'tel',
                                path: number,
                              );
                              if (await canLaunchUrl(callUri)) {
                                await launchUrl(callUri);
                              } else {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Could not launch dialer'),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      keyboardType: TextInputType.phone,
                      readOnly: !provider.isEditing,
                    ),
                    MyInputField(
                      label: 'Customer Address',
                      controller: provider.addressController,
                      keyboardType: TextInputType.text,
                      readOnly: !provider.isEditing,
                    ),
                    TextField(
                      controller: provider.bookingDateController,
                      readOnly: true,
                      onTap: () {
                        if (provider.isEditing) {
                          _pickDate(context, provider.bookingDateController);
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Booking Date',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: provider.deliveryDateController,
                      readOnly: true,
                      onTap: () {
                        if (provider.isEditing) {
                          _pickDate(context, provider.deliveryDateController);
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Delivery Date',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    MyInputField(
                      label: 'Notes',
                      controller: provider.noteController,
                      keyboardType: TextInputType.text,
                      readOnly: !provider.isEditing,
                    ),
                  ],
                ),
                ExpansionTile(
                  collapsedIconColor: Colors.black,
                  collapsedTextColor: Colors.black,
                  iconColor: Colors.black,
                  textColor: Colors.black,
                  title: const Text(
                    'Payment Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  children: [
                    const SizedBox(height: 5),
                    MyInputField(
                      label: 'Discount',
                      controller: provider.discountController,
                      keyboardType: TextInputType.number,
                      readOnly: !provider.isEditing,
                    ),
                    MyInputField(
                      label: 'Advance Amount',
                      controller: provider.advanceController,
                      keyboardType: TextInputType.number,
                      readOnly: !provider.isEditing,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: TextField(
                            controller: provider.advanceAmountDateController,
                            readOnly: true,
                            onTap: () {
                              if (provider.isEditing) {
                                _pickDate(
                                  context,
                                  provider.advanceAmountDateController,
                                );
                              }
                            },
                            decoration: InputDecoration(
                              labelText: 'Advance Date',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (provider.isEditing) {
                                  provider.setAdvancePaymentMode(true);
                                }
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
                                if (provider.isEditing) {
                                  provider.setAdvancePaymentMode(false);
                                }
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
                    MyInputField(
                      label: 'Paid Amount',
                      controller: provider.paidAmountController,
                      keyboardType: TextInputType.number,
                      readOnly: !provider.isEditing,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: TextField(
                            readOnly: true,
                            onTapOutside: (event) =>
                                FocusScope.of(context).unfocus(),
                            onTap: () {
                              if (provider.isEditing) {
                                _pickDate(
                                  context,
                                  provider.paidAmountDateController,
                                );
                              }
                            },
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
                                if (provider.isEditing) {
                                  provider.setPaidPaymentMode(true);
                                }
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
                                if (provider.isEditing) {
                                  provider.setPaidPaymentMode(false);
                                }
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

                    //Payment status
                    if (provider.paymentStatus == PaymentStatus.paid)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Amount: ₹${provider.totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(Icons.check, color: Colors.green),
                              SizedBox(width: 5),
                              Text('Fully Paid'),
                            ],
                          ),
                        ],
                      ),
                    if (provider.paymentStatus != PaymentStatus.paid)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Remaining Amount: ₹${provider.remainingAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                provider.paymentStatus == PaymentStatus.partial
                                    ? Icons.warning
                                    : Icons.cancel,
                                color:
                                    provider.paymentStatus ==
                                        PaymentStatus.partial
                                    ? Colors.blue
                                    : Colors.red,
                              ),
                              SizedBox(width: 5),
                              Text(
                                provider.paymentStatus == PaymentStatus.partial
                                    ? 'Partially Paid'
                                    : 'Unpaid',
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
