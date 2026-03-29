import 'dart:async';

import 'package:flutter/foundation.dart';

import 'chess_set_themes.dart';
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
  int _careerXp = 0;
  String _selectedThemeId = ChessSetCatalog.chrome.id;
  String? _hostAddress;
  int? _hostPort;
  Uri? _hostUri;
  String? _joinAddress;
  int? _joinPort;
  Uri? _joinUri;
  ChessSquare? _selectedSquare;
  String? _notice = 'White moves first. Tap a piece, then a highlighted square.';
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
  ChessSquare? get selectedSquare => _selectedSquare;
  String? get notice => _notice;
  String? get lastError => _lastError;
  bool get busy => _busy;
  bool get isHosted => _role == MatchRole.host && _hostUri != null;
  bool get isJoined => _role == MatchRole.guest && _joinUri != null;
  bool get isLocal => _role == MatchRole.local;
  bool get isBrowserRoomHost => kIsWeb && _role == MatchRole.host && _hostUri != null;
  bool get isBrowserRoomGuest => kIsWeb && _role == MatchRole.guest && _joinUri != null;
  int get careerXp => _careerXp;
  static const int _xpPerLevel = 8;

  int get playerLevel => 1 + (_careerXp ~/ _xpPerLevel);

  int get xpIntoLevel => _careerXp % _xpPerLevel;

  int get xpToNextLevel => _xpPerLevel - xpIntoLevel;

  List<ChessSetTheme> get availableThemes => ChessSetCatalog.all;

  List<ChessSetTheme> get unlockedThemes =>
      ChessSetCatalog.unlockedForLevel(playerLevel);

  ChessSetTheme get activeTheme => ChessSetCatalog.byId(_selectedThemeId);

  String get levelSummary => 'Level $playerLevel - $xpIntoLevel/$_xpPerLevel XP';

  String get unlockSummary =>
      '${unlockedThemes.length}/${availableThemes.length} sets unlocked';

  String get nextUnlockSummary {
    final nextTheme = ChessSetCatalog.nextLockedTheme(playerLevel);
    if (nextTheme == null) {
      return 'All sets unlocked.';
    }
    return 'Next unlock: ${nextTheme.name} at level ${nextTheme.unlockLevel}.';
  }

  String? get hostShareText {
    if (_hostUri != null && kIsWeb) {
      return _hostUri.toString();
    }
    if (_hostAddress != null && _hostPort != null) {
      return '$_hostAddress:$_hostPort';
    }
    return null;
  }

  List<ChessSquare> get legalTargets {
    final square = _selectedSquare;
    if (square == null) {
      return const <ChessSquare>[];
    }
    return _session
        .legalMovesFrom(square)
        .map((move) => move.to)
        .toList(growable: false);
  }

  String get connectionSummary {
    switch (_role) {
      case MatchRole.local:
        return 'Local chess on this device';
      case MatchRole.host:
        if (_hostUri == null) {
          return 'Host setup ready';
        }
        if (kIsWeb) {
          return 'Browser room ready';
        }
        if (_hostAddress == null) {
          return 'Hosting white side on port ${_hostPort ?? _hostUri!.port}';
        }
        return 'Hosting white side at $_hostAddress:${_hostPort ?? _hostUri!.port}';
      case MatchRole.guest:
        if (_joinUri == null) {
          return 'Join setup ready';
        }
        if (kIsWeb) {
          return 'Joined browser room';
        }
        return 'Joined black side at ${_joinAddress ?? _joinUri!.host}:${_joinPort ?? _joinUri!.port}';
    }
  }

  String get seatSummary {
    return switch (_role) {
      MatchRole.local => 'Both sides on one screen',
      MatchRole.host => 'White seat on this device',
      MatchRole.guest => 'Black seat on this device',
    };
  }

  String get turnSummary => _session.statusLabel;

  bool get canLocalMove {
    if (_session.isComplete) {
      return false;
    }

    return switch (_role) {
      MatchRole.local => true,
      MatchRole.host => _hostUri != null &&
          _session.activeColor == ChessColor.white,
      MatchRole.guest => _joinUri != null &&
          _session.activeColor == ChessColor.black,
    };
  }

  bool isThemeUnlocked(ChessSetTheme theme) {
    return playerLevel >= theme.unlockLevel;
  }

  List<String> get historyLines {
    return _session.moves.reversed
        .take(8)
        .map((move) => move.summary)
        .toList(growable: false);
  }

  Future<void> bootstrap() async {
    final saved = await _storage.load();
    if (saved == null) {
      _notice = 'Ready for a fresh chess board.';
      notifyListeners();
      return;
    }

    _session = saved.session;
    _role = saved.role;
    _careerXp = saved.careerXp;
    _selectedThemeId = ChessSetCatalog.byId(saved.selectedThemeId).id;
    final selectedTheme = ChessSetCatalog.byId(_selectedThemeId);
    if (!isThemeUnlocked(selectedTheme)) {
      _selectedThemeId = ChessSetCatalog.themeForLevel(playerLevel).id;
    }
    _hostAddress = saved.hostAddress;
    _hostPort = kIsWeb && saved.hostPort == 0 ? null : saved.hostPort;
    _joinAddress = saved.joinAddress;
    _joinPort = kIsWeb && saved.joinPort == 0 ? null : saved.joinPort;
    _hostUri = kIsWeb && _role == MatchRole.host && _hostAddress != null
        ? _browserRoomUri(_hostAddress!)
        : null;
    _joinUri = kIsWeb && _role == MatchRole.guest && _joinAddress != null
        ? _browserRoomUri(_joinAddress!)
        : null;
    _selectedSquare = null;
    _notice = kIsWeb && _syncUri != null
        ? 'Saved browser room restored.'
        : 'Saved chess position restored. Reconnect host or join to resume LAN play.';
    if (_syncUri != null) {
      _startPolling();
      unawaited(refreshFromHost(silent: true));
    }
    notifyListeners();
  }

  Future<void> startLocalMatch() async {
    await _runBusy(() async {
      await _stopNetwork();
      _role = MatchRole.local;
      _session = MatchSession.initial();
      _selectedSquare = null;
      _notice = 'Local chess board reset.';
      await _persist();
    });
  }

  Future<void> hostMatch() async {
    await _runBusy(() async {
      await _stopNetwork();
      final launch = await _transport.startHost(
        readSession: () async => _session,
        applyMove: (move) => _applyMove(move, awardProgress: false),
        resetMatch: _resetMatch,
      );

      _role = MatchRole.host;
      _hostAddress = launch.lanAddress;
      _hostPort = launch.port == 0 ? null : launch.port;
      _hostUri = launch.uri;
      _joinUri = null;
      _selectedSquare = null;
      _notice = kIsWeb
          ? 'Browser room ready. Share the invite link with another tab.'
          : launch.lanAddress == null
              ? 'Host is live on port ${launch.port}, but no LAN address was detected.'
              : 'Share ${launch.lanAddress}:${launch.port} with the other device.';
      _pollErrorShown = false;
      await _persist();
      if (_syncUri != null) {
        _startPolling();
      }
    });
  }

  Future<void> joinHost({
    required String address,
    required int port,
  }) async {
    await _runBusy(() async {
      final cleanedAddress = address.trim();
      if (cleanedAddress.isEmpty) {
        throw MatchRuleError(
          kIsWeb
              ? 'Enter the invite link or room code first.'
              : 'Enter the host address first.',
        );
      }
      if (!kIsWeb && (port <= 0 || port > 65535)) {
        throw const MatchRuleError('Enter a valid port number.');
      }

      await _stopNetwork();
      final browserRoomCode =
          kIsWeb ? _browserRoomCodeFromInput(cleanedAddress) : null;
      if (kIsWeb && (browserRoomCode == null || browserRoomCode.isEmpty)) {
        throw const MatchRuleError('Enter a valid invite link or room code.');
      }
      final baseUri = kIsWeb
          ? _browserRoomUri(browserRoomCode!)
          : Uri.parse('http://$cleanedAddress:$port');
      final initialState = await _transport.fetchState(baseUri);
      _session = initialState;
      _role = MatchRole.guest;
      _joinAddress = kIsWeb ? browserRoomCode : cleanedAddress;
      _joinPort = kIsWeb ? null : port;
      _joinUri = baseUri;
      _hostUri = null;
      _selectedSquare = null;
      _notice = kIsWeb
          ? 'Connected to browser room.'
          : 'Connected to $cleanedAddress:$port.';
      _pollErrorShown = false;
      _startPolling();
      await _persist();
    });
  }

  Future<void> refreshFromHost({bool silent = false}) async {
    final uri = _syncUri;
    if (uri == null) {
      return;
    }

    try {
      final fresh = await _transport.fetchState(uri);
      if (fresh.updatedAt.isAfter(_session.updatedAt)) {
        _session = fresh;
        _selectedSquare = null;
        _notice = 'Chess position synchronized from host.';
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

  Future<void> tapSquare(int file, int row) async {
    if (_busy) {
      return;
    }

    final square = ChessSquare(file: file, row: row);
    final selected = _selectedSquare;

    if (selected != null) {
      if (selected == square) {
        _selectedSquare = null;
        notifyListeners();
        return;
      }

      final legalMove = _findLegalMove(selected, square);
      if (legalMove != null) {
        await playMove(legalMove);
        return;
      }
    }

    final piece = _session.pieceAt(square);
    if (piece != null && _canSelectPiece(piece)) {
      _selectedSquare = square;
      _notice = _session.note;
      notifyListeners();
      return;
    }

    if (_selectedSquare != null) {
      _selectedSquare = null;
      notifyListeners();
    }
  }

  Future<void> playMove(ChessMove move) async {
    await _runBusy(() async {
      if (!canLocalMove) {
        throw const MatchRuleError(
          'Wait for your turn or start a local match.',
        );
      }

      final movingPiece = _session.pieceAt(move.from);
      if (movingPiece == null) {
        throw MatchRuleError('No piece is on ${move.from.notation}.');
      }

      final syncUri = _syncUri;
      if (syncUri != null &&
          (_role == MatchRole.guest || (kIsWeb && _role == MatchRole.host))) {
        final fresh = await _transport.submitMove(syncUri, move);
        _session = fresh;
        _notice = fresh.note;
        _selectedSquare = null;
        _pollErrorShown = false;
        _recordCareerProgress(
          movingColor: movingPiece.color,
          resultingSession: fresh,
        );
        await _persist();
        return;
      }

      await _applyMove(move, awardProgress: true);
    });
  }

  Future<void> resetMatch() async {
    await _runBusy(() async {
      final syncUri = _syncUri;
      if (syncUri == null) {
        _session = _session.reset();
      } else {
        _session = await _transport.reset(syncUri);
      }
      _notice = _session.note;
      _selectedSquare = null;
      _pollErrorShown = false;
      await _persist();
    });
  }

  Future<MatchSession> _resetMatch() async {
    _session = _session.reset();
    _notice = _session.note;
    _selectedSquare = null;
    await _persist();
    notifyListeners();
    return _session;
  }

  Future<MatchSession> _applyMove(
    ChessMove move, {
    bool awardProgress = true,
  }) async {
    final movingPiece = _session.pieceAt(move.from);
    _session = _session.playMove(move);
    _notice = _session.note;
    if (awardProgress && movingPiece != null) {
      _recordCareerProgress(
        movingColor: movingPiece.color,
        resultingSession: _session,
      );
    }
    _selectedSquare = null;
    await _persist();
    notifyListeners();
    return _session;
  }

  Future<void> selectTheme(String themeId) async {
    final theme = ChessSetCatalog.byId(themeId);
    if (!isThemeUnlocked(theme)) {
      _notice = 'Reach level ${theme.unlockLevel} to unlock ${theme.name}.';
      notifyListeners();
      return;
    }

    if (_selectedThemeId == theme.id) {
      return;
    }

    _selectedThemeId = theme.id;
    _notice = '${theme.name} selected.';
    notifyListeners();
    await _persist();
  }

  ChessMove? _findLegalMove(ChessSquare from, ChessSquare to) {
    for (final move in _session.legalMovesFrom(from)) {
      if (move.to == to) {
        return move;
      }
    }
    return null;
  }

  bool _canSelectPiece(ChessPiece piece) {
    return switch (_role) {
      MatchRole.local => piece.color == _session.activeColor,
      MatchRole.host =>
        _hostUri != null &&
            piece.color == ChessColor.white &&
            _session.activeColor == ChessColor.white,
      MatchRole.guest =>
        _joinUri != null &&
            piece.color == ChessColor.black &&
            _session.activeColor == ChessColor.black,
    };
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
        careerXp: _careerXp,
        selectedThemeId: _selectedThemeId,
      ),
    );
  }

  void _recordCareerProgress({
    required ChessColor movingColor,
    required MatchSession resultingSession,
  }) {
    final previousLevel = playerLevel;
    var earnedXp = 1;

    if (resultingSession.isComplete) {
      earnedXp += resultingSession.phase == MatchPhase.draw
          ? 2
          : resultingSession.winner == movingColor
              ? 6
              : 2;
    }

    _careerXp += earnedXp;

    final updatedLevel = playerLevel;
    if (updatedLevel > previousLevel) {
      final unlockedThemes = ChessSetCatalog.all
          .where(
            (theme) =>
                theme.unlockLevel > previousLevel &&
                theme.unlockLevel <= updatedLevel,
          )
          .map((theme) => theme.name)
          .toList(growable: false);
      _notice = unlockedThemes.isEmpty
          ? 'Level $updatedLevel reached.'
          : 'Level $updatedLevel unlocked ${unlockedThemes.join(', ')}.';
    }
  }

  Future<void> _stopNetwork() async {
    _pollTimer?.cancel();
    _pollTimer = null;
    _hostUri = null;
    _joinUri = null;
    _hostAddress = null;
    _hostPort = null;
    _joinAddress = null;
    _joinPort = null;
    _selectedSquare = null;
    await _transport.stop();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(milliseconds: 850),
      (_) => unawaited(refreshFromHost(silent: true)),
    );
  }

  Uri get _browserRoomUriFallback => Uri.base;

  Uri _browserRoomUri(String roomCode) {
    final normalized = roomCode.trim();
    final base = _browserRoomUriFallback;
    return base.replace(
      queryParameters: <String, String>{'room': normalized},
    );
  }

  String? _browserRoomCodeFromInput(String input) {
    final cleaned = input.trim();
    if (cleaned.isEmpty) {
      return null;
    }

    final parsed = Uri.tryParse(cleaned);
    if (parsed == null) {
      return cleaned;
    }

    final queryRoom = parsed.queryParameters['room']?.trim();
    if (queryRoom != null && queryRoom.isNotEmpty) {
      return queryRoom;
    }

    if (parsed.pathSegments.isNotEmpty) {
      final last = parsed.pathSegments.last.trim();
      if (last.isNotEmpty) {
        return last;
      }
    }

    return cleaned;
  }

  Uri? get _syncUri {
    if (_role == MatchRole.guest) {
      return _joinUri;
    }
    if (kIsWeb && _role == MatchRole.host) {
      return _hostUri;
    }
    return null;
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
