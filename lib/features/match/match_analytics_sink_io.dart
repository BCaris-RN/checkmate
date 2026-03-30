import 'dart:convert';
import 'dart:io';

class MatchAnalyticsSink {
  Future<void> appendRow(Uri endpoint, Map<String, Object?> row) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
    try {
      final request = await client.postUrl(endpoint);
      request.headers.contentType = ContentType.json;
      request.add(utf8.encode(jsonEncode(<String, Object?>{'row': row})));
      final response = await request.close();
      if (response.statusCode >= 400) {
        throw HttpException(
          'Analytics sink responded with HTTP ${response.statusCode}.',
          uri: endpoint,
        );
      }
      await response.drain<void>();
    } finally {
      client.close(force: true);
    }
  }
}
