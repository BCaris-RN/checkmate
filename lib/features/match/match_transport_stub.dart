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
  Future<HostLaunchResult> startHost({
    required Future<MatchSession> Function() readSession,
    required Future<MatchSession> Function(ChessMove move) applyMove,
    required Future<MatchSession> Function() resetMatch,
    int preferredPort = 0,
  }) {
    throw UnsupportedError(
      'Local network match play is unavailable on this platform.',
    );
  }

  Future<MatchSession> fetchState(Uri baseUri) {
    throw UnsupportedError(
      'Local network match play is unavailable on this platform.',
    );
  }

  Future<MatchSession> submitMove(Uri baseUri, ChessMove move) {
    throw UnsupportedError(
      'Local network match play is unavailable on this platform.',
    );
  }

  Future<MatchSession> reset(Uri baseUri) {
    throw UnsupportedError(
      'Local network match play is unavailable on this platform.',
    );
  }

  Future<void> stop() async {}
}
