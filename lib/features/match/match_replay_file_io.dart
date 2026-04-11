import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<String> saveMatchReplayText({
  required String fileName,
  required String contents,
}) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}\\$fileName');
  await file.writeAsString(contents);
  return file.path;
}
