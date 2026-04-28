import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
//File hỗ trợ xử lý logic cho màn hình viết (lưu dữ liệu, chọn ảnh/video...)
/// Lưu ảnh vào thư mục app, trả về path đã lưu.
/// Trên web trả về path gốc (không lưu được).
Future<String> saveImageToAppDir(String originalPath) async {
  if (kIsWeb) return originalPath;

  final appDir = await getApplicationDocumentsDirectory();
  final fileName =
      '${DateTime.now().millisecondsSinceEpoch}_${p.basename(originalPath)}';
  final savedFile =
  await File(originalPath).copy('${appDir.path}/$fileName');
  return savedFile.path;
}