import 'dart:async';

import 'package:flutter/foundation.dart';

import 'match_models.dart';
import 'match_storage.dart';
import 'match_transport.dart';

class MatchController extends ChangeNotifier {
  MatchController({
    MatchStorage? storage,
    LocalMatchTransport? transport,
  })  : _storage = storage ?? MatchStorage(),
        _transport = transport ?? LocalMatchTransport();

  final MatchStorage _storage;
  final LocalMatchTransport _transport;

  MatchSession _session = MatchSession.initial();
  MatchRole _role = MatchRole.local;
  String? _hostAddress;
  int? _hostPort;
  Uri? _hostUri;
  String? _joinAddress;
  int? _joinPort;
  Uri? _joinUri;
  String? _notice = 'Start a local match, host this device, or join a host.';
  String? _lastError;
  bool _busy = false;
  bool _pollErrorShown = false;
  Timer? _pollTimer;

  MatchSession get session => _session;
  MatchRole get role => _role;
  String? get hostAddress => _hostAddress;
  int? get hostPort => _hostPort;
  String? get joinAddress => _joinAddress;
  int? get joinPort => _joinPort;
  String? get notice => _notice;
  String? get lastError => _lastError;
  bool get busy => _busy;
  bool get isHosted => _role == MatchRole.host && _hostUri != null;
  bool get isJoined => _role == MatchRole.guest && _joinUri != null;
  bool get isLocal => _role == MatchRole.local;

  String get connectionSummary {
    return switch (_role) {
      MatchRole.local => 'Local hot-seat on this device',
      MatchRole.host => _hostUri == null
          ? 'Host setup ready'
          : _hostAddress == null
              ? 'Hosting on port ${_hostPort ?? _hostUri!.port}'
              : 'Hosting $_hostAddress:${_hostPort ?? _hostUri!.port}',
      MatchRole.guest => _joinUri == null
          ? 'Join setup ready'
          : 'Joined ${_joinAddress ?? _joinUri!.host}:${_joinPort ?? _joinUri!.port}',
    };
  }

  String get seatSummary {
    return switch (_role) {
      MatchRole.local => 'Both seats on one screen',
      MatchRole.host => 'Blue seat on this device',
      MatchRole.guest => 'Ink seat on this device',
    };
  }

  String get turnSummary => _session.statusLabel;

  bool get canLocalMove {
    if (_session.isComplete) {
      return false;
    }
    return switch (_role) {
      MatchRole.local => true,
      MatchRole.host => _hostUri != null && _session.activePlayer == MatchToken.blue,
      MatchRole.guest => _joinUri != null && _session.activePlayer == MatchToken.ink,
    };
  }

  List<String> get historyLines {
    final moves = _session.moves.reversed.take(8);
    return moves
        .map((move) => '${move.player.shortLabel}  column ${move.column + 1}')
        .toList(growable: false);
  }

  Future<void> bootstrap() async {
    final saved = await _storage.load();
    if (saved == null) {
      _notice = 'Ready for a fresh match.';
      notifyListeners();
      return;
    }

    _session = saved.session;
    _role = saved.role;
    _hostAddress = saved.hostAddress;
    _hostPort = saved.hostPort;
    _joinAddress = saved.joinAddress;
    _joinPort = saved.joinPort;
    _hostUri = null;
    _joinUri = null;
    _notice = 'Saved match restored. Start host or join again to resume networking.';
    notifyListeners();
  }

  Future<void> startLocalMatch() async {
    await _runBusy(() async {
      await _stopNetwork();
      _role = MatchRole.local;
      _session = MatchSession.initial();
      _notice = 'Local hot-seat match started.';
      await _persist();
    });
  }

  Future<void> hostMatch() async {
    await _runBusy(() async {
      await _stopNetwork();
      final launch = await _transport.startHost(
        readSession: () async => _session,
        applyMove: _applyColumn,
        resetMatch: _resetMatch,
      );

      _role = MatchRole.host;
      _hostAddress = launch.lanAddress;
      _hostPort = launch.port;
      _hostUri = launch.uri;
      _joinUri = null;
      _notice = launch.lanAddress == null
          ? 'Host is live on port ${launch.port}, but no LAN address was detected.'
          : 'Share ${launch.lanAddress}:${launch.port} with the other device.';
      _pollErrorShown = false;
      await _persist();
    });
  }

  Future<void> joinHost({
    required String address,
    required int port,
  }) async {
    await _runBusy(() async {
      final cleanedAddress = address.trim();
      if (cleanedAddress.isEmpty) {
        throw const MatchRuleError('Enter the host address first.');
      }
      if (port <= 0 || port > 65535) {
        throw const MatchRuleError('Enter a valid port number.');
      }

      final baseUri = Uri.parse('http://$cleanedAddress:$port');
      final initialState = await _transport.fetchState(baseUri);
      _session = initialState;
      _role = MatchRole.guest;
      _joinAddress = cleanedAddress;
      _joinPort = port;
      _joinUri = baseUri;
      _hostUri = null;
      _notice = 'Connected to $cleanedAddress:$port.';
      _pollErrorShown = false;
      _startPolling();
      await _persist();
    });
  }

  Future<void> refreshFromHost({bool silent = false}) async {
    final uri = _joinUri;
    if (uri == null) {
      return;
    }

    try {
      final fresh = await _transport.fetchState(uri);
      if (fresh.updatedAt.isAfter(_session.updatedAt)) {
        _session = fresh;
        _notice = 'Match synchronized from host.';
        await _persist();
        notifyListeners();
      }
      _pollErrorShown = false;
    } catch (error) {
      if (!silent || !_pollErrorShown) {
        _lastError = _friendlyError(error);
        _notice = 'Connection to host is unstable.';
        _pollErrorShown = true;
        notifyListeners();
      }
    }
  }

  Future<void> playColumn(int column) async {
    await _runBusy(() async {
      if (!canLocalMove) {
        throw const MatchRuleError('Wait for the other seat or start a local match.');
      }

      if (_role == MatchRole.guest && _joinUri != null) {
        final fresh = await _transport.submitMove(_joinUri!, column);
        _session = fresh;
        _notice = fresh.note;
        _pollErrorShown = false;
        await _persist();
        return;
      }

      _session = _session.playColumn(column);
      _notice = _session.note;
      await _persist();
    });
  }

  Future<void> resetMatch() async {
    await _runBusy(() async {
      final remote = _role == MatchRole.guest && _joinUri != null;
      _session = remote ? await _transport.reset(_joinUri!) : _session.reset();
      _notice = _session.note;
      _pollErrorShown = false;
      await _persist();
    });
  }

  Future<MatchSession> _resetMatch() async {
    _session = _session.reset();
    _notice = _session.note;
    await _persist();
    notifyListeners();
    return _session;
  }

  Future<MatchSession> _applyColumn(int column) async {
    _session = _session.playColumn(column);
    _notice = _session.note;
    await _persist();
    notifyListeners();
    return _session;
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    if (_busy) {
      return;
    }
    _busy = true;
    notifyListeners();
    try {
      await action();
      _lastError = null;
    } catch (error) {
      _lastError = _friendlyError(error);
      _notice = _lastError;
      notifyListeners();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    await _storage.save(
      MatchPersistedState(
        session: _session,
        role: _role,
        hostAddress: _hostAddress,
        hostPort: _hostPort,
        joinAddress: _joinAddress,
        joinPort: _joinPort,
      ),
    );
  }

  Future<void> _stopNetwork() async {
    _pollTimer?.cancel();
    _pollTimer = null;
    _hostUri = null;
    _joinUri = null;
    await _transport.stop();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(milliseconds: 850),
      (_) => unawaited(refreshFromHost(silent: true)),
    );
  }

  String _friendlyError(Object error) {
    if (error is MatchRuleError) {
      return error.message;
    }
    if (error is TimeoutException) {
      return 'The match host did not answer in time.';
    }
    return 'Match action failed: $error';
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    unawaited(_transport.stop());
    super.dispose();
  }
}
