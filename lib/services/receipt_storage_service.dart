import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class ReceiptStorageService {
  static const String _receiptSubdir = 'receipt_thumbnails';

  /// Saves an image to the app's persistent storage and returns the local file path
  static Future<String> saveReceiptImage(File sourceFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final targetDir = Directory(p.join(appDir.path, _receiptSubdir));
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final ext = p.extension(sourceFile.path).isNotEmpty
        ? p.extension(sourceFile.path)
        : '.jpg';
    final fileName = 'receipt_${const Uuid().v4()}$ext';
    final targetPath = p.join(targetDir.path, fileName);

    final savedFile = await sourceFile.copy(targetPath);
    return savedFile.path;
  }

  /// Deletes a cached receipt image if exists
  static Future<void> deleteReceiptImage(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return;
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
