import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<File> getTempFileForOrder(String orderId) async {
  final dir = await getApplicationDocumentsDirectory();
  return File('${dir.path}/bill_$orderId.tmp');
}

Future<void> markBillAsGenerating(String orderId) async {
  final tmpFile = await getTempFileForOrder(orderId);
  await tmpFile.writeAsString('generating');
}

Future<bool> isBillStillGenerating(String orderId) async {
  final tmpFile = await getTempFileForOrder(orderId);
  return await tmpFile.exists();
}


Future<void> markBillAsGenerated(String orderId) async {
  final tmpFile = await getTempFileForOrder(orderId);
  if (await tmpFile.exists()) {
    await tmpFile.delete();
  }
}
