// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:convert';
import 'dart:html' as html;
import 'dart:math';

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
  static const String _roomPrefix = 'checkmate.browser.room.';
  static final Random _random = Random();

  Future<HostLaunchResult> startHost({
    required Future<MatchSession> Function() readSession,
    required Future<MatchSession> Function(ChessMove move) applyMove,
    required Future<MatchSession> Function() resetMatch,
    int preferredPort = 0,
  }) async {
    final roomCode = _generateRoomCode();
    final session = await readSession();
    await _writeRoomState(roomCode, session);

    return HostLaunchResult(
      uri: _roomUri(roomCode),
      port: 0,
      lanAddress: roomCode,
    );
  }

  Future<MatchSession> fetchState(Uri baseUri) async {
    final roomCode = _roomCodeFromUri(baseUri);
    if (roomCode == null) {
      throw const MatchRuleError('Missing browser room code.');
    }
    return _readRoomState(roomCode);
  }

  Future<MatchSession> submitMove(Uri baseUri, ChessMove move) async {
    final roomCode = _roomCodeFromUri(baseUri);
    if (roomCode == null) {
      throw const MatchRuleError('Missing browser room code.');
    }

    final current = await _readRoomState(roomCode);
    final updated = current.playMove(move);
    await _writeRoomState(roomCode, updated);
    return updated;
  }

  Future<MatchSession> reset(Uri baseUri) async {
    final roomCode = _roomCodeFromUri(baseUri);
    if (roomCode == null) {
      throw const MatchRuleError('Missing browser room code.');
    }

    final resetSession = MatchSession.initial();
    await _writeRoomState(roomCode, resetSession);
    return resetSession;
  }

  Future<void> stop() async {}

  Future<void> _writeRoomState(String roomCode, MatchSession session) async {
    html.window.localStorage[_stateKey(roomCode)] = jsonEncode(session.toJson());
  }

  Future<MatchSession> _readRoomState(String roomCode) async {
    final raw = html.window.localStorage[_stateKey(roomCode)];
    if (raw == null || raw.trim().isEmpty) {
      throw const MatchRuleError('The browser room is not active.');
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Unexpected browser room payload.');
    }
    return MatchSession.fromJson(decoded);
  }

  Uri _roomUri(String roomCode) {
    final normalized = roomCode.trim();
    return Uri.base.replace(
      queryParameters: <String, String>{'room': normalized},
    );
  }

  String? _roomCodeFromUri(Uri uri) {
    final queryRoom = uri.queryParameters['room']?.trim();
    if (queryRoom != null && queryRoom.isNotEmpty) {
      return queryRoom;
    }

    if (uri.pathSegments.isNotEmpty) {
      final lastSegment = uri.pathSegments.last.trim();
      if (lastSegment.isNotEmpty) {
        return lastSegment;
      }
    }

    return null;
  }

  String _stateKey(String roomCode) => '$_roomPrefix${roomCode.trim()}';

  String _generateRoomCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List<String>.generate(
      8,
      (_) => alphabet[_random.nextInt(alphabet.length)],
      growable: false,
    ).join();
  }
}
