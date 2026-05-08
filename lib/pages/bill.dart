// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:hive/hive.dart';
// import 'package:lottie/lottie.dart';
// import 'package:tailor_mate/utils/tmp_file_bill.dart';
// import 'package:url_launcher/url_launcher.dart';

// class BillImageView extends StatefulWidget {
//   final String orderId;

//   const BillImageView({super.key, required this.orderId});

//   @override
//   State<BillImageView> createState() => _BillImageViewState();
// }

// class _BillImageViewState extends State<BillImageView> {
//   bool _isGenerating = true;
//   File? _billImage;

//   final ordersBox = Hive.box('orders');

//   @override
//   void initState() {
//     super.initState();
//     Future.microtask(() => loadBillImage());
//   }

//   Future<void> loadBillImage() async {
//     final stillGenerating = await isBillStillGenerating(widget.orderId);

//     if (stillGenerating) {
//       setState(() {
//         _isGenerating = true;
//       });

//       // Keep checking until the bill is no longer being generated
//       while (await isBillStillGenerating(widget.orderId)) {
//         await Future.delayed(const Duration(seconds: 1));
//       }
//     }

//     // Once done, show the image
//     final imageFile = await getBillImageFile(widget.orderId);

//     setState(() {
//       _billImage = imageFile;
//       _isGenerating = false;
//     });
//   }

//   double totalAmount = 0.0;
//   Future<void> sendWhatsAppMessage() async {
//     final order = ordersBox.get(widget.orderId);
//     if (order == null) {
//       // Handle missing order
//       return;
//     }
//     double totalAmount = 0.0;

//     for (var item in order.items) {
//       final qty = int.tryParse(item['qty'].toString()) ?? 0;
//       final price = double.tryParse(item['price'].toString()) ?? 0.0;

//       final bgitemprice =
//           double.tryParse(item['bgitemPrice']?.toString() ?? '0') ?? 0.0;
//       final bgqty = int.tryParse(item['bgqty']?.toString() ?? '0') ?? 0;

//       debugPrint("Item: $item");
//       debugPrint(
//         "qty: $qty, price: $price, bgitemPrice: $bgitemprice, bgqty: $bgqty",
//       );

//       totalAmount += (qty * price) + (bgitemprice * bgqty);
//     }
//     final deliveryDate =
//         '${order.deliveryDate.day}-${order.deliveryDate.month}-${order.deliveryDate.year % 100}';
//     final discount = double.tryParse(order.discount.toString()) ?? 0.0;
//     totalAmount -= (order.advancePayment + discount);
//     totalAmount = totalAmount < 0 ? 0 : totalAmount;
//     String msg =
//         "${order.customerName}.\nYour Order id is: *${order.id}*.\nIts Amount Grand Total is: *$totalAmount*.\nIts Delivary Date is: *$deliveryDate*.\nThanks For Visit. *Aarti Beautique*";
//     String url = "whatsapp://send?phone=91${order.mobileNumber}&text=$msg";
//     launchUrl(Uri.parse(url));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Bill for Order ID: ${widget.orderId}'),
//         actions: [
//           _isGenerating
//               ? SizedBox()
//               : Padding(
//                   padding: const EdgeInsets.only(right: 5.0),
//                   child: IconButton(
//                     onPressed: sendWhatsAppMessage,
//                     icon: const Icon(Icons.share),
//                   ),
//                 ),
//         ],
//       ),
//       body: _isGenerating
//           ? Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Lottie.asset('assets/Sandy Loading.json'),
//                   Text(
//                     'Generating bill...',
//                     style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                   ),
//                 ],
//               ),
//             )
//           : _billImage != null && _billImage!.existsSync()
//           ? Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: FutureBuilder(
//                 future: _billImage!.readAsBytes(),
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return const CircularProgressIndicator();
//                   } else if (snapshot.hasError || !snapshot.hasData) {
//                     return const Text('Failed to load bill image.');
//                   }
//                   return Image.memory(snapshot.data!);
//                 },
//               ),
//             )
//           : const Center(child: Text("Bill image not found.")),
//     );
//   }
// }

// Future<File?> getBillImageFile(String orderId) async {
//   final imagePath = '/storage/emulated/0/DCIM/AartiBeautique/Bill/$orderId.jpg';
//   final file = File(imagePath);
//   return file.existsSync() ? file : null;
// }

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:lottie/lottie.dart';
import 'package:tailor_mate/utils/bill_generator.dart';
import 'package:tailor_mate/utils/tmp_file_bill.dart';
import 'package:url_launcher/url_launcher.dart';

class BillImageView extends StatefulWidget {
  final String orderId;

  const BillImageView({super.key, required this.orderId});

  @override
  State<BillImageView> createState() => _BillImageViewState();
}

class _BillImageViewState extends State<BillImageView> {
  bool _isGenerating = true;
  File? _billImage;

  final ordersBox = Hive.box('orders');

  @override
  void initState() {
    super.initState();
    Future.microtask(() => loadBillImage());
  }

  Future<void> loadBillImage() async {
    final stillGenerating = await isBillStillGenerating(widget.orderId);

    if (stillGenerating) {
      setState(() => _isGenerating = true);

      // Keep checking until the bill is no longer being generated
      while (await isBillStillGenerating(widget.orderId)) {
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    // Once done, show the image
    final imageFile = await getBillImageFile(widget.orderId);

    setState(() {
      _billImage = imageFile;
      _isGenerating = false;
    });
  }

  double totalAmount = 0.0;

  Future<void> sendWhatsAppMessage() async {
    final order = ordersBox.get(widget.orderId);
    if (order == null) return;

    double totalAmount = 0.0;
    for (var item in order.items) {
      final qty = int.tryParse(item['qty'].toString()) ?? 0;
      final price = double.tryParse(item['price'].toString()) ?? 0.0;
      final bgitemprice =
          double.tryParse(item['bgitemPrice']?.toString() ?? '0') ?? 0.0;
      final bgqty = int.tryParse(item['bgqty']?.toString() ?? '0') ?? 0;

      totalAmount += (qty * price) + (bgitemprice * bgqty);
    }

    final deliveryDate =
        '${order.deliveryDate.day}-${order.deliveryDate.month}-${order.deliveryDate.year % 100}';
    final discount = double.tryParse(order.discount.toString()) ?? 0.0;
    totalAmount -= (order.advancePayment + discount);
    totalAmount = totalAmount < 0 ? 0 : totalAmount;

    String msg =
        "${order.customerName}.\nYour Bill No is: *${order.billNo}*.\nIts Amount Grand Total is: *$totalAmount*.\nIts Delivary Date is: *$deliveryDate*.\nThanks For Visit. *Aarti Beautique*";

    String url = "whatsapp://send?phone=91${order.mobileNumber}&text=$msg";
    launchUrl(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bill No: ${(ordersBox.get(widget.orderId)?.billNo ?? '')}',
        ),
        actions: [
          _isGenerating
              ? const SizedBox()
              : Padding(
                  padding: const EdgeInsets.only(right: 5.0),
                  child: IconButton(
                    onPressed: sendWhatsAppMessage,
                    icon: const Icon(Icons.share),
                  ),
                ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final existingImage = await getBillImageFile(widget.orderId);

          if (existingImage == null || !existingImage.existsSync()) {
            // No image yet → generate it
            setState(() => _isGenerating = true);
            await saveBillImageLocally(
              widget.orderId,
              ordersBox.get(widget.orderId)?.billNo,
            );
            await loadBillImage();
          } else {
            // Already stored → just reload it in case it changed
            await loadBillImage();
          }
        },

        child: _isGenerating
            ? ListView(
                // Needed so pull-to-refresh works even with loader
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Lottie.asset('assets/Sandy Loading.json'),
                          const SizedBox(height: 10),
                          const Text(
                            'Generating bill...',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : _billImage != null && _billImage!.existsSync()
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FutureBuilder(
                      future: _billImage!.readAsBytes(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (snapshot.hasError || !snapshot.hasData) {
                          return const Text('Failed to load bill image.');
                        }
                        return Image.memory(snapshot.data!);
                      },
                    ),
                  ),
                ],
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 300),
                  Center(child: Text("Bill image not found.\nPull to Refresh")),
                ],
              ),
      ),
    );
  }
}

Future<File?> getBillImageFile(String orderId) async {
  final imagePath = '/storage/emulated/0/DCIM/AartiBeautique/Bill/$orderId.jpg';
  final file = File(imagePath);
  return file.existsSync() ? file : null;
}
