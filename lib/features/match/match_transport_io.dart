import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'match_models.dart';

class HostLaunchResult {
  const HostLaunchResult({
    required this.uri,
    required this.port,
    this.lanAddress,
  });

  final Uri uri;
  final int port;
  final String? lanAddress;
}

class LocalMatchTransport {
  HttpServer? _server;

  Future<HostLaunchResult> startHost({
    required Future<MatchSession> Function() readSession,
    required Future<MatchSession> Function(int column) applyMove,
    required Future<MatchSession> Function() resetMatch,
    int preferredPort = 0,
  }) async {
    await stop();

    final server = await HttpServer.bind(
      InternetAddress.anyIPv4,
      preferredPort,
    );
    _server = server;

    server.listen((request) async {
      try {
        await _handleRequest(
          request,
          readSession: readSession,
          applyMove: applyMove,
          resetMatch: resetMatch,
        );
      } catch (error) {
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode(<String, Object?>{'error': error.toString()}),
        );
        await request.response.close();
      }
    });

    final address = await _discoverLocalAddress();
    final uri = Uri.parse('http://${address ?? '127.0.0.1'}:${server.port}');
    return HostLaunchResult(
      uri: uri,
      port: server.port,
      lanAddress: address,
    );
  }

  Future<void> _handleRequest(
    HttpRequest request, {
    required Future<MatchSession> Function() readSession,
    required Future<MatchSession> Function(int column) applyMove,
    required Future<MatchSession> Function() resetMatch,
  }) async {
    final path = request.uri.path;
    final method = request.method.toUpperCase();

    if (method == 'GET' && path == '/ping') {
      await _writeJson(request.response, <String, Object?>{'ok': true});
      return;
    }

    if (method == 'GET' && path == '/state') {
      await _writeJson(request.response, (await readSession()).toJson());
      return;
    }

    if (method == 'POST' && path == '/move') {
      final payload = await _readJson(request);
      final column = (payload['column'] as num?)?.toInt();
      if (column == null) {
        throw const MatchRuleError('Move payload must include a column.');
      }
      await _writeJson(request.response, (await applyMove(column)).toJson());
      return;
    }

    if (method == 'POST' && path == '/reset') {
      await _writeJson(request.response, (await resetMatch()).toJson());
      return;
    }

    request.response.statusCode = HttpStatus.notFound;
    await _writeJson(request.response, <String, Object?>{'error': 'Not found'});
  }

  Future<Map<String, dynamic>> _readJson(HttpRequest request) async {
    final body = await utf8.decoder.bind(request).join();
    if (body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Expected a JSON object.');
    }
    return decoded;
  }

  Future<void> _writeJson(HttpResponse response, Map<String, Object?> payload) async {
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(payload));
    await response.close();
  }

  Future<MatchSession> fetchState(Uri baseUri) {
    return _requestSession('GET', baseUri.resolve('/state'));
  }

  Future<MatchSession> submitMove(Uri baseUri, int column) {
    return _requestSession(
      'POST',
      baseUri.resolve('/move'),
      body: <String, Object?>{'column': column},
    );
  }

  Future<MatchSession> reset(Uri baseUri) {
    return _requestSession('POST', baseUri.resolve('/reset'));
  }

  Future<MatchSession> _requestSession(
    String method,
    Uri uri, {
    Map<String, Object?>? body,
  }) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
    try {
      final request = await client.openUrl(method, uri);
      request.headers.contentType = ContentType.json;
      if (body != null) {
        request.add(utf8.encode(jsonEncode(body)));
      }
      final response = await request.close();
      final responseText = await utf8.decoder.bind(response).join();
      final decoded = jsonDecode(responseText);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Unexpected match state response.');
      }
      return MatchSession.fromJson(decoded);
    } finally {
      client.close(force: true);
    }
  }

  Future<String?> _discoverLocalAddress() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLinkLocal: true,
    );

    String? fallback;
    for (final interface in interfaces) {
      for (final address in interface.addresses) {
        if (address.isLoopback) {
          continue;
        }
        fallback ??= address.address;
        if (_isPrivateIpv4(address.address)) {
          return address.address;
        }
      }
    }

    return fallback;
  }

  bool _isPrivateIpv4(String address) {
    final parts = address.split('.');
    if (parts.length != 4) {
      return false;
    }

    final first = int.tryParse(parts[0]) ?? -1;
    final second = int.tryParse(parts[1]) ?? -1;

    if (first == 10) {
      return true;
    }
    if (first == 192 && second == 168) {
      return true;
    }
    return first == 172 && second >= 16 && second <= 31;
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;
    if (server != null) {
      await server.close(force: true);
    }
  }
}
