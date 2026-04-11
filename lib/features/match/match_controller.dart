import 'dart:async';

import 'package:flutter/foundation.dart';

import 'match_analytics.dart';
import 'match_analytics_sink.dart';
import 'chess_set_themes.dart';
import 'match_models.dart';
import 'match_storage.dart';
import 'match_transport.dart';
import 'match_time.dart';

class MatchController extends ChangeNotifier {
  MatchController({
    MatchStorage? storage,
    LocalMatchTransport? transport,
    MatchAnalyticsSink? analyticsSink,
    DateTime Function()? now,
  }) : _storage = storage ?? MatchStorage(),
       _transport = transport ?? LocalMatchTransport(),
       _analyticsSink = analyticsSink ?? MatchAnalyticsSink(),
       _now = now ?? DateTime.now;

  final MatchStorage _storage;
  final LocalMatchTransport _transport;
  final MatchAnalyticsSink _analyticsSink;
  final DateTime Function() _now;

  MatchSession _session = MatchSession.initial();
  MatchRole _role = MatchRole.local;
  int _careerXp = 0;
  String _selectedThemeId = ChessSetCatalog.chrome.id;
  bool _whiteAtBottom = true;
  bool _awaitingHandOff = false;
  bool _passReminderEnabled = true;
  MatchTimerPreset _clockPreset = MatchTimerPreset.infinity;
  String? _analyticsSinkUrl;
  DateTime _turnStartedAtUtc = DateTime.now().toUtc();
  String? _hostAddress;
  int? _hostPort;
  Uri? _hostUri;
  String? _joinAddress;
  int? _joinPort;
  Uri? _joinUri;
  ChessSquare? _selectedSquare;
  String? _notice =
      'White moves first. Tap a piece, then a highlighted square.';
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
  bool get isBrowserRoomHost =>
      kIsWeb && _role == MatchRole.host && _hostUri != null;
  bool get isBrowserRoomGuest =>
      kIsWeb && _role == MatchRole.guest && _joinUri != null;
  int get careerXp => _careerXp;
  bool get whiteAtBottom => _whiteAtBottom;
  bool get awaitingHandOff => _awaitingHandOff;
  bool get passReminderEnabled => _passReminderEnabled;
  MatchTimerPreset get clockPreset => _clockPreset;
  String? get analyticsSinkUrl => _analyticsSinkUrl;
  static const int _xpPerLevel = 8;

  int get playerLevel => 1 + (_careerXp ~/ _xpPerLevel);

  int get xpIntoLevel => _careerXp % _xpPerLevel;

  int get xpToNextLevel => _xpPerLevel - xpIntoLevel;

  List<ChessSetTheme> get availableThemes => ChessSetCatalog.all;

  List<ChessSetTheme> get unlockedThemes =>
      ChessSetCatalog.unlockedForLevel(playerLevel);

  ChessSetTheme get activeTheme => ChessSetCatalog.byId(_selectedThemeId);

  String get levelSummary =>
      'Level $playerLevel - $xpIntoLevel/$_xpPerLevel XP';

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

  String get boardOrientationSummary =>
      _whiteAtBottom ? 'White at bottom' : 'Black at bottom';

  String get timeControlSummary => _clockPreset.longLabel;

  String get turnClockSummary {
    if (_session.isComplete) {
      return _session.note;
    }

    if (_awaitingHandOff && isLocal) {
      return 'Pass the device to ${_session.activeColor.label}.';
    }

    final elapsed = currentTurnElapsed;
    if (elapsed == null) {
      return 'No clock running.';
    }

    final remaining = remainingFor(_session.activeColor);
    if (remaining == null) {
      return '${_session.activeColor.label} move timing: ${formatClock(elapsed)}';
    }

    return '${_session.activeColor.label} ${formatClock(remaining)} left';
  }

  Duration? get currentTurnElapsed {
    if (_session.isComplete || _awaitingHandOff) {
      return null;
    }
    return _now().toUtc().difference(_turnStartedAtUtc);
  }

  Duration? remainingFor(ChessColor color) {
    final presetDuration = _clockPreset.duration;
    if (presetDuration == null) {
      return null;
    }

    var spentMilliseconds = 0;
    for (final move in _session.moves) {
      if (move.color == color) {
        spentMilliseconds += move.elapsedMilliseconds ?? 0;
      }
    }

    if (!isLocal && _session.activeColor == color && !_session.isComplete) {
      spentMilliseconds += _now()
          .toUtc()
          .difference(_turnStartedAtUtc)
          .inMilliseconds;
    } else if (isLocal &&
        !_awaitingHandOff &&
        _session.activeColor == color &&
        !_session.isComplete) {
      spentMilliseconds += _now()
          .toUtc()
          .difference(_turnStartedAtUtc)
          .inMilliseconds;
    }

    final remaining = presetDuration.inMilliseconds - spentMilliseconds;
    return Duration(
      milliseconds: remaining.clamp(0, presetDuration.inMilliseconds).toInt(),
    );
  }

  String get analyticsSheetLabel {
    final cleaned = _analyticsSinkUrl?.trim();
    if (cleaned == null || cleaned.isEmpty) {
      return 'No analytics sheet linked.';
    }
    return cleaned;
  }

  String get analyticsCsv => analyticsCsvFromMoves(_session.moves);

  List<Map<String, Object?>> get analyticsRows {
    return [
      for (var index = 0; index < _session.moves.length; index += 1)
        analyticsRowForMove(_session.moves[index], moveNumber: index + 1),
    ];
  }

  String get turnSummary => _session.statusLabel;

  bool get canLocalMove {
    if (_session.isComplete) {
      return false;
    }

    return switch (_role) {
      MatchRole.local => !_awaitingHandOff,
      MatchRole.host =>
        _hostUri != null && _session.activeColor == ChessColor.white,
      MatchRole.guest =>
        _joinUri != null && _session.activeColor == ChessColor.black,
    };
  }

  bool get canPassDevice => isLocal && _awaitingHandOff && !_session.isComplete;

  String get passButtonLabel => _awaitingHandOff
      ? 'Pass to ${_session.activeColor.label}'
      : 'Pass device';

  String get passReminderLabel =>
      _passReminderEnabled ? 'Pass reminder on' : 'Pass reminder off';

  bool isThemeUnlocked(ChessSetTheme theme) {
    return playerLevel >= theme.unlockLevel;
  }

  List<String> get historyLines {
    return _session.moves.reversed
        .take(8)
        .map((move) => move.summary)
        .toList(growable: false);
  }

  String get replayExportText {
    final buffer = StringBuffer();
    buffer.writeln('Checkmate replay');
    buffer.writeln('Generated ${DateTime.now().toUtc().toIso8601String()}');
    if (_session.moves.isEmpty) {
      buffer.writeln('No moves yet.');
      return buffer.toString().trimRight();
    }

    for (var index = 0; index < _session.moves.length; index += 2) {
      final moveNumber = (index ~/ 2) + 1;
      final whiteMove = _session.moves[index].replayToken;
      final blackMove = index + 1 < _session.moves.length
          ? _session.moves[index + 1].replayToken
          : '';
      buffer.write('$moveNumber. $whiteMove');
      if (blackMove.isNotEmpty) {
        buffer.write('   $blackMove');
      }
      if (index + 2 < _session.moves.length) {
        buffer.writeln();
      }
    }

    return buffer.toString().trimRight();
  }

  String get moveLogText {
    if (_session.moves.isEmpty) {
      return 'No moves yet.';
    }

    final buffer = StringBuffer();
    for (var index = 0; index < _session.moves.length; index += 2) {
      final moveNumber = (index ~/ 2) + 1;
      final whiteMove = _session.moves[index].summary;
      final blackMove = index + 1 < _session.moves.length
          ? _session.moves[index + 1].summary
          : '';
      buffer.write('$moveNumber. $whiteMove');
      if (blackMove.isNotEmpty) {
        buffer.write(' | $blackMove');
      }
      if (index + 2 < _session.moves.length) {
        buffer.write('\n');
      }
    }

    return buffer.toString();
  }

  Future<void> bootstrap() async {
    final saved = await _storage.load();
    if (saved == null) {
      _notice = 'Ready for a fresh chess board.';
      _turnStartedAtUtc = _now().toUtc();
      notifyListeners();
      return;
    }

    _session = saved.session;
    _role = saved.role;
    _careerXp = saved.careerXp;
    _selectedThemeId = ChessSetCatalog.byId(saved.selectedThemeId).id;
    _whiteAtBottom = saved.whiteAtBottom;
    _awaitingHandOff = saved.awaitingHandOff;
    _passReminderEnabled = true;
    _clockPreset = saved.clockPreset;
    _analyticsSinkUrl = saved.analyticsSinkUrl;
    _turnStartedAtUtc = saved.turnStartedAtUtc ?? _now().toUtc();
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
    if (_role == MatchRole.guest) {
      _whiteAtBottom = false;
    }
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
      _whiteAtBottom = true;
      _awaitingHandOff = false;
      _turnStartedAtUtc = _now().toUtc();
      _notice = 'Local chess board reset. White starts at the bottom.';
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
      _whiteAtBottom = true;
      _awaitingHandOff = false;
      _turnStartedAtUtc = _now().toUtc();
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

  Future<void> joinHost({required String address, required int port}) async {
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
      final browserRoomCode = kIsWeb
          ? _browserRoomCodeFromInput(cleanedAddress)
          : null;
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
      _whiteAtBottom = false;
      _awaitingHandOff = false;
      _turnStartedAtUtc = _now().toUtc();
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
        throw const MatchRuleError('Pass the device before the next move.');
      }

      final movingPiece = _session.pieceAt(move.from);
      if (movingPiece == null) {
        throw MatchRuleError('No piece is on ${move.from.notation}.');
      }

      final now = _now().toUtc();
      final elapsedMilliseconds = _turnElapsedMilliseconds(now);

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
        _turnStartedAtUtc = now;
        _awaitingHandOff = false;
        await _persist();
        return;
      }

      await _applyMove(
        move,
        awardProgress: true,
        elapsedMilliseconds: elapsedMilliseconds,
        recordedAtUtc: now,
        timerPreset: _clockPreset,
      );
      _awaitingHandOff = !_session.isComplete;
      final moveSummary =
          '${movingPiece.color.label} moved in '
          '${formatClock(Duration(milliseconds: elapsedMilliseconds))}.';
      if (_session.isComplete) {
        _notice = '$moveSummary ${_session.note}';
      } else if (_role == MatchRole.local) {
        _notice = _passReminderEnabled
            ? '$moveSummary Pass the device to ${_session.activeColor.label}.'
            : moveSummary;
      } else {
        _notice = moveSummary;
      }
      notifyListeners();
      await _persist();
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
      _awaitingHandOff = false;
      if (_role == MatchRole.local) {
        _whiteAtBottom = true;
      }
      _turnStartedAtUtc = _now().toUtc();
      _pollErrorShown = false;
      await _persist();
    });
  }

  Future<MatchSession> _resetMatch() async {
    _session = _session.reset();
    _notice = _session.note;
    _selectedSquare = null;
    _awaitingHandOff = false;
    if (_role == MatchRole.local) {
      _whiteAtBottom = true;
    }
    _turnStartedAtUtc = _now().toUtc();
    await _persist();
    notifyListeners();
    return _session;
  }

  Future<MatchSession> _applyMove(
    ChessMove move, {
    bool awardProgress = true,
    int? elapsedMilliseconds,
    DateTime? recordedAtUtc,
    MatchTimerPreset? timerPreset,
  }) async {
    final movingPiece = _session.pieceAt(move.from);
    _session = _session.playMove(
      move,
      elapsedMilliseconds: elapsedMilliseconds,
      recordedAtUtc: recordedAtUtc,
      timerPreset: timerPreset,
    );
    _notice = _session.note;
    if (awardProgress && movingPiece != null) {
      _recordCareerProgress(
        movingColor: movingPiece.color,
        resultingSession: _session,
      );
    }
    _selectedSquare = null;
    await _persist();
    if (_analyticsSinkUrl != null && _role == MatchRole.local) {
      await _exportLatestAnalyticsRow();
    }
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

  Future<void> setClockPreset(MatchTimerPreset preset) async {
    if (_clockPreset == preset) {
      return;
    }

    await _runBusy(() async {
      _clockPreset = preset;
      _notice = 'Time control set to ${preset.longLabel}.';
      await _persist();
    });
  }

  Future<void> setAnalyticsSinkUrl(String value) async {
    final cleaned = value.trim();
    await _runBusy(() async {
      _analyticsSinkUrl = cleaned.isEmpty ? null : cleaned;
      if (_analyticsSinkUrl == null) {
        _notice = 'Analytics sink cleared.';
      } else {
        final parsed = Uri.tryParse(_analyticsSinkUrl!);
        if (parsed != null &&
            parsed.host.contains('docs.google.com') &&
            parsed.path.contains('/spreadsheets')) {
          _notice =
              'Analytics reference saved. Live writes need a Google Apps Script web app URL.';
        } else if (parsed == null || !parsed.hasScheme || parsed.host.isEmpty) {
          _notice =
              'Analytics reference saved as text. Live writes need a full web app URL.';
        } else {
          _notice = 'Analytics sink saved.';
        }
      }
      await _persist();
    });
  }

  Future<void> passDevice() async {
    await _runBusy(() async {
      if (!canPassDevice) {
        _notice = 'Make a move before passing the device.';
        notifyListeners();
        return;
      }

      _whiteAtBottom = !_whiteAtBottom;
      _awaitingHandOff = false;
      _turnStartedAtUtc = _now().toUtc();
      _notice = _passReminderEnabled
          ? '${_session.activeColor.label} can move now.'
          : _session.note;
      await _persist();
    });
  }

  Future<void> setPassReminderEnabled(bool value) async {
    if (_passReminderEnabled == value) {
      return;
    }

    await _runBusy(() async {
      _passReminderEnabled = value;
      _notice = value ? 'Pass reminder enabled.' : 'Pass reminder disabled.';
      await _persist();
    });
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
        whiteAtBottom: _whiteAtBottom,
        awaitingHandOff: _awaitingHandOff,
        clockPreset: _clockPreset,
        analyticsSinkUrl: _analyticsSinkUrl,
        turnStartedAtUtc: _turnStartedAtUtc,
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

  int _turnElapsedMilliseconds(DateTime nowUtc) {
    if (_session.isComplete || _awaitingHandOff) {
      return 0;
    }
    return nowUtc.difference(_turnStartedAtUtc).inMilliseconds;
  }

  Future<void> _exportLatestAnalyticsRow() async {
    final endpointText = _analyticsSinkUrl?.trim();
    if (endpointText == null ||
        endpointText.isEmpty ||
        _session.moves.isEmpty) {
      return;
    }

    final endpoint = Uri.tryParse(endpointText);
    if (endpoint == null || !endpoint.hasScheme || endpoint.host.isEmpty) {
      return;
    }

    if (endpoint.host.contains('docs.google.com') &&
        endpoint.path.contains('/spreadsheets')) {
      return;
    }

    final moveNumber = _session.moves.length;
    final row = analyticsRowForMove(
      _session.moves.last,
      moveNumber: moveNumber,
    );
    try {
      await _analyticsSink.appendRow(endpoint, row);
      _pollErrorShown = false;
    } catch (error) {
      _notice = 'Analytics export paused: ${_friendlyError(error)}';
      notifyListeners();
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
    return base.replace(queryParameters: <String, String>{'room': normalized});
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
