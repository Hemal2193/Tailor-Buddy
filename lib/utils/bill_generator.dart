// ignore_for_file: avoid_print, deprecated_member_use
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:media_scanner/media_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tailor_mate/database/order_model.dart';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tailor_mate/main.dart';
import 'package:tailor_mate/utils/app_notification.dart';

Future<String?> generateQrBase64(String upiLink) async {
  final qrValidationResult = QrValidator.validate(
    data: upiLink,
    version: QrVersions.auto,
    errorCorrectionLevel: QrErrorCorrectLevel.M,
  );

  if (qrValidationResult.status == QrValidationStatus.valid) {
    final painter = QrPainter.withQr(
      qr: qrValidationResult.qrCode!,
      color: const Color(0xFF000000),
      emptyColor: const Color(0xFFFFFFFF),
      gapless: true,
    );

    final image = await painter.toImage(300); // 300x300 size
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    return base64Encode(bytes);
  }

  return null;
}

Future<String?> generateSlideImageUrl(String orderId) async {
  try {
    final box = await Hive.openBox('orders');
    final order = box.get(orderId) as Order?;

    if (order == null) return null;

    final bookingDate =
        '${order.bookingDate.day.toString().padLeft(2, '0')}-${order.bookingDate.month.toString().padLeft(2, '0')}-${(order.bookingDate.year % 100).toString().padLeft(2, '0')}';

    final deliveryDate =
        '${order.deliveryDate.day.toString().padLeft(2, '0')}-${order.deliveryDate.month.toString().padLeft(2, '0')}-${(order.deliveryDate.year % 100).toString().padLeft(2, '0')}';

    final baseUrl =
        'https://script.google.com/macros/s/AKfycby-6OzlANrK6iVV0W7XqAGDCuHu3CP_N3S0upZSG0tzG43hXQLzVvn10IzgwNGnFXR9/exec';

    double totalAmount = 0;
    int totalQty = 0;

    String query =
        '?name=${Uri.encodeComponent(order.customerName)}'
        '&orderId=${Uri.encodeComponent(order.billNo)}'
        '&b.date=${Uri.encodeComponent(bookingDate)}'
        '&d.date=${Uri.encodeComponent(deliveryDate)}'
        '&address=${Uri.encodeComponent(order.address ?? '')}'
        '&number=${Uri.encodeComponent(order.mobileNumber)}'
        '&dis=${Uri.encodeComponent(order.discount.toString())}'
        '&mode=${Uri.encodeComponent(order.advanceMode)}'
        '&adv=${Uri.encodeComponent(order.advancePayment.toString())}';

    int i = 0;
    for (final item in order.items) {
      final handedName = item['name']?.toString() ?? '';
      final handedQtyStr = item['qty']?.toString() ?? '0';
      final handedRateStr = item['price']?.toString() ?? '0';

      final bgName = item['bgitem']?.toString() ?? '';
      final bgQtyStr = item['bgqty']?.toString() ?? '0';
      final bgRateStr = item['bgitemPrice']?.toString() ?? '0';

      final handedQty = double.tryParse(handedQtyStr) ?? 0;
      final handedRate = double.tryParse(handedRateStr) ?? 0;

      final bgQty = double.tryParse(bgQtyStr) ?? 0;
      final bgRate = double.tryParse(bgRateStr) ?? 0;

      if (handedName.isNotEmpty && handedQty > 0) {
        final amt = (handedQty * handedRate).toStringAsFixed(0);
        totalQty += handedQty.toInt();
        totalAmount += handedQty * handedRate;

        query +=
            '&q${i}0=${Uri.encodeComponent(handedQtyStr)}'
            '&q${i}1='
            '&des$i=${Uri.encodeComponent(handedName)}'
            '&rate$i=${Uri.encodeComponent(handedRateStr)}'
            '&amnt$i=${Uri.encodeComponent(amt)}';
        i++;
      }

      if (bgName.isNotEmpty && bgQty > 0) {
        final amt = (bgQty * bgRate).toStringAsFixed(0);
        totalAmount += bgQty * bgRate;

        query +=
            '&q${i}0='
            '&q${i}1=${Uri.encodeComponent(bgQtyStr)}'
            '&des$i=${Uri.encodeComponent(bgName)}'
            '&rate$i=${Uri.encodeComponent(bgRateStr)}'
            '&amnt$i=${Uri.encodeComponent(amt)}';
        i++;
      }
    }
    totalAmount = totalAmount - (order.discount ?? 0) - (order.advancePayment);
    query += '&totalqty=$totalQty&total=${totalAmount.toStringAsFixed(0)}';

    final upiLink =
        'upi://pay?pa=9033805398@okbizaxis&pn=AARATI%20BEAUTQUE&am=$totalAmount';
    final qrBase64 = await generateQrBase64(upiLink);
    query += '&qr=${Uri.encodeComponent(qrBase64 ?? '')}';

    final Uri url = Uri.parse(baseUrl + query);
    print("Final Slide URL: $url");

    final response = await http.get(url);
    if (response.statusCode == 200) {
      return response.body;
    } else {
      print("Slide generation failed. Status: ${response.statusCode}");
      return null;
    }
  } catch (e) {
    print("Slide generation error: $e");
    return null;
  }
}

Future<void> saveBillImageLocally(String orderId, String billNo) async {
  // Step 1: Generate Slide Image URL
  final imageUrl = await generateSlideImageUrl(orderId);
  print("this is image url $imageUrl");
  if (imageUrl == null || imageUrl.isEmpty) {
    print('❌ Image URL not generated.');
    return;
  }

  // Step 2: Request storage permission (for Android 13 and below)
  final status = await Permission.manageExternalStorage.request();
  if (!status.isGranted) {
    print('❌ Storage permission not granted.');
    return;
  }

  try {
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode != 200) {
      print('❌ Failed to download image. Status: ${response.statusCode}');
      return;
    }

    // Step 3: Create directory
    final folderPath = '/storage/emulated/0/DCIM/AartiBeautique/Bill';
    final dir = Directory(folderPath);
    if (!await dir.exists()) await dir.create(recursive: true);

    // Step 4: Write image to file
    final filePath = '$folderPath/$orderId.jpg';
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes, flush: true);
    await MediaScanner.loadMedia(path: filePath);

    print('✅ Image saved at $filePath');
    // scaffoldMessengerKey.currentState?.showSnackBar(
    //   SnackBar(
    //     content: Text('Bill No $billNo is ready and saved to your device!'),
    //     duration: const Duration(seconds: 3),
    //     behavior: SnackBarBehavior.fixed,
    //   ),
    // );
    AppNotification.show(navigatorKey.currentState?.overlay, "Order saved!");
  } catch (e) {
    print('❌ Exception saving image: $e');
  }
}
