// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:convert';
import 'dart:html' as html;

class MatchAnalyticsSink {
  Future<void> appendRow(Uri endpoint, Map<String, Object?> row) async {
    final request = await html.HttpRequest.request(
      endpoint.toString(),
      method: 'POST',
      sendData: jsonEncode(<String, Object?>{'row': row}),
      requestHeaders: const <String, String>{
        'Content-Type': 'application/json',
      },
    );
    if (request.status != 200 && request.status != 204) {
      throw StateError(
        'Analytics sink responded with HTTP ${request.status}.',
      );
    }
  }
}
