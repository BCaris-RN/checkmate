import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

Future<String> saveMatchReplayText({
  required String fileName,
  required String contents,
}) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File(path.join(directory.path, fileName));
  await file.writeAsString(contents);
  return file.path;
}
