import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String> copyFileToAppDir(String sourcePath, String fileName) async {
  final appDoc = await getApplicationDocumentsDirectory();
  final audioDir = Directory('${appDoc.path}${Platform.pathSeparator}audio');
  if (!await audioDir.exists()) await audioDir.create(recursive: true);
  final dest = File('${audioDir.path}${Platform.pathSeparator}$fileName');
  final copied = await File(sourcePath).copy(dest.path);
  return copied.path;
}

Future<void> deleteIfInAppDir(String filePath) async {
  final appDoc = await getApplicationDocumentsDirectory();
  final audioDirPath = '${appDoc.path}${Platform.pathSeparator}audio${Platform.pathSeparator}';
  if (filePath.startsWith(audioDirPath)) {
    final f = File(filePath);
    if (await f.exists()) await f.delete();
  }
}
