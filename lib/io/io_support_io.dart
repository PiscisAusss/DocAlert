import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String?> copyToAppImages(String sourcePath, String docId) async {
  final dir = await getApplicationDocumentsDirectory();
  final destDir = Directory(p.join(dir.path, 'doc_images'));
  if (!await destDir.exists()) {
    await destDir.create(recursive: true);
  }
  var ext = p.extension(sourcePath);
  if (ext.isEmpty) ext = '.jpg';
  final dest = p.join(destDir.path, '$docId$ext');
  await File(sourcePath).copy(dest);
  return dest;
}

Future<void> deleteLocalFile(String? path) async {
  if (path == null || path.isEmpty) return;
  final file = File(path);
  if (await file.exists()) {
    await file.delete();
  }
}

Future<String?> writeTempTextFile(String filename, String contents) async {
  final dir = await getTemporaryDirectory();
  final file = File(p.join(dir.path, filename));
  await file.writeAsString(contents);
  return file.path;
}

Future<String?> readTextFile(String path) async {
  final file = File(path);
  if (await file.exists()) return file.readAsString();
  return null;
}
