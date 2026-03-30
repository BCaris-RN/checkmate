import 'package:flutter_test/flutter_test.dart';

import 'package:checkmate_by_caris/features/match/chess_set_themes.dart';
import 'package:checkmate_by_caris/features/match/match_controller.dart';
import 'package:checkmate_by_caris/features/match/match_models.dart';
import 'package:checkmate_by_caris/features/match/match_storage.dart';
import 'package:checkmate_by_caris/features/match/match_transport.dart';
import 'package:checkmate_by_caris/features/match/match_time.dart';

class FakeMatchStorage extends MatchStorage {
  MatchPersistedState? savedState;
  int saveCount = 0;
  int clearCount = 0;

  @override
  Future<MatchPersistedState?> load() async => null;

  @override
  Future<void> save(MatchPersistedState state) async {
    savedState = state;
    saveCount += 1;
  }

  @override
  Future<void> clear() async {
    savedState = null;
    clearCount += 1;
  }
}

class FakeMatchTransport extends LocalMatchTransport {
  FakeMatchTransport({
    required this.launchResult,
    MatchSession? fetchedSession,
  }) : fetchedSession = fetchedSession ?? MatchSession.initial();

  final HostLaunchResult launchResult;
  MatchSession fetchedSession;
  int stopCount = 0;
  int startHostCount = 0;
  int fetchStateCount = 0;
  int submitMoveCount = 0;
  int resetCount = 0;

  @override
  Future<HostLaunchResult> startHost({
    required Future<MatchSession> Function() readSession,
    required Future<MatchSession> Function(ChessMove move) applyMove,
    required Future<MatchSession> Function() resetMatch,
    int preferredPort = 0,
  }) async {
    startHostCount += 1;
    return launchResult;
  }

  @override
  Future<MatchSession> fetchState(Uri baseUri) async {
    fetchStateCount += 1;
    return fetchedSession;
  }

  @override
  Future<MatchSession> submitMove(Uri baseUri, ChessMove move) async {
    submitMoveCount += 1;
    fetchedSession = fetchedSession.playMove(move);
    return fetchedSession;
  }

  @override
  Future<MatchSession> reset(Uri baseUri) async {
    resetCount += 1;
    fetchedSession = MatchSession.initial();
    return fetchedSession;
  }

  @override
  Future<void> stop() async {
    stopCount += 1;
  }
}

void main() {
  test('starting local mode clears previous host metadata', () async {
    final storage = FakeMatchStorage();
    final transport = FakeMatchTransport(
      launchResult: HostLaunchResult(
        uri: Uri.parse('http://192.168.1.10:5050'),
        port: 5050,
        lanAddress: '192.168.1.10',
      ),
    );
    final controller = MatchController(
      storage: storage,
      transport: transport,
    );

    await controller.hostMatch();
    await controller.startLocalMatch();

    expect(controller.isLocal, isTrue);
    expect(controller.hostAddress, isNull);
    expect(controller.hostPort, isNull);
    expect(controller.joinAddress, isNull);
    expect(controller.joinPort, isNull);
    expect(transport.startHostCount, 1);
    expect(transport.stopCount, 2);
    expect(storage.saveCount, 2);
    expect(storage.savedState?.role, MatchRole.local);
  });

  test('joining a host clears previous host metadata', () async {
    final storage = FakeMatchStorage();
    final transport = FakeMatchTransport(
      launchResult: HostLaunchResult(
        uri: Uri.parse('http://192.168.1.10:5050'),
        port: 5050,
        lanAddress: '192.168.1.10',
      ),
      fetchedSession: MatchSession.initial(),
    );
    final controller = MatchController(
      storage: storage,
      transport: transport,
    );

    await controller.hostMatch();
    await controller.joinHost(
      address: '10.0.0.2',
      port: 6060,
    );

    expect(controller.isJoined, isTrue);
    expect(controller.hostAddress, isNull);
    expect(controller.hostPort, isNull);
    expect(controller.joinAddress, '10.0.0.2');
    expect(controller.joinPort, 6060);
    expect(transport.startHostCount, 1);
    expect(transport.fetchStateCount, 1);
    expect(transport.stopCount, 2);
    expect(storage.saveCount, 2);
    expect(storage.savedState?.role, MatchRole.guest);
  });

  test('selecting and moving a piece updates the board', () async {
    final storage = FakeMatchStorage();
    final transport = FakeMatchTransport(
      launchResult: HostLaunchResult(
        uri: Uri.parse('http://192.168.1.10:5050'),
        port: 5050,
        lanAddress: '192.168.1.10',
      ),
    );
    final controller = MatchController(
      storage: storage,
      transport: transport,
    );

    await controller.bootstrap();
    await controller.tapSquare(4, 6);

    expect(controller.selectedSquare, const ChessSquare(file: 4, row: 6));
    expect(
      controller.legalTargets,
      contains(const ChessSquare(file: 4, row: 4)),
    );

    await controller.tapSquare(4, 4);

    expect(controller.selectedSquare, isNull);
    expect(
      controller.session.board[4][4],
      const ChessPiece(
        color: ChessColor.white,
        type: ChessPieceType.pawn,
        hasMoved: true,
      ),
    );
    expect(controller.session.activeColor, ChessColor.black);
    expect(controller.turnSummary, 'Black to move');
    expect(storage.saveCount, 2);
  });

  test('career progress unlocks and persists themed chess sets', () async {
    final storage = FakeMatchStorage();
    final transport = FakeMatchTransport(
      launchResult: HostLaunchResult(
        uri: Uri.parse('http://192.168.1.10:5050'),
        port: 5050,
        lanAddress: '192.168.1.10',
      ),
    );
    final controller = MatchController(
      storage: storage,
      transport: transport,
    );

    await controller.startLocalMatch();

    final opening = <ChessMove>[
      ChessMove(
        from: const ChessSquare(file: 4, row: 6),
        to: const ChessSquare(file: 4, row: 4),
      ),
      ChessMove(
        from: const ChessSquare(file: 4, row: 1),
        to: const ChessSquare(file: 4, row: 3),
      ),
      ChessMove(
        from: const ChessSquare(file: 6, row: 7),
        to: const ChessSquare(file: 5, row: 5),
      ),
      ChessMove(
        from: const ChessSquare(file: 1, row: 0),
        to: const ChessSquare(file: 2, row: 2),
      ),
      ChessMove(
        from: const ChessSquare(file: 5, row: 7),
        to: const ChessSquare(file: 2, row: 4),
      ),
      ChessMove(
        from: const ChessSquare(file: 6, row: 0),
        to: const ChessSquare(file: 5, row: 2),
      ),
      ChessMove(
        from: const ChessSquare(file: 3, row: 6),
        to: const ChessSquare(file: 3, row: 5),
      ),
      ChessMove(
        from: const ChessSquare(file: 3, row: 1),
        to: const ChessSquare(file: 3, row: 2),
      ),
    ];

    for (final move in opening) {
      await controller.playMove(move);
      if (controller.awaitingHandOff) {
        await controller.passDevice();
      }
    }

    expect(controller.playerLevel, 2);
    expect(controller.isThemeUnlocked(ChessSetCatalog.crystal), isTrue);
    expect(controller.isThemeUnlocked(ChessSetCatalog.gold), isFalse);

    await controller.selectTheme(ChessSetCatalog.crystal.id);

    expect(controller.activeTheme.id, ChessSetCatalog.crystal.id);
    expect(storage.savedState?.careerXp, controller.careerXp);
    expect(storage.savedState?.selectedThemeId, ChessSetCatalog.crystal.id);
    expect(controller.levelSummary, 'Level 2 - 0/8 XP');
  });

  test('local hot-seat play pauses for pass and flips the board', () async {
    final storage = FakeMatchStorage();
    final transport = FakeMatchTransport(
      launchResult: HostLaunchResult(
        uri: Uri.parse('http://192.168.1.10:5050'),
        port: 5050,
        lanAddress: '192.168.1.10',
      ),
    );
    final controller = MatchController(
      storage: storage,
      transport: transport,
      now: () => DateTime.utc(2026, 1, 1, 12, 0, 0),
    );

    await controller.startLocalMatch();
    await controller.tapSquare(4, 6);
    await controller.tapSquare(4, 4);

    expect(controller.awaitingHandOff, isTrue);
    expect(controller.canLocalMove, isFalse);
    expect(controller.passButtonLabel, 'Pass to Black');
    expect(controller.whiteAtBottom, isTrue);
    expect(controller.session.moves.last.elapsedMilliseconds, isNotNull);

    await controller.passDevice();

    expect(controller.awaitingHandOff, isFalse);
    expect(controller.whiteAtBottom, isFalse);
    expect(controller.turnSummary, 'Black to move');
    expect(storage.savedState?.whiteAtBottom, isFalse);
    expect(storage.savedState?.awaitingHandOff, isFalse);
  });

  test('timer presets and analytics rows persist with match play', () async {
    final storage = FakeMatchStorage();
    final transport = FakeMatchTransport(
      launchResult: HostLaunchResult(
        uri: Uri.parse('http://192.168.1.10:5050'),
        port: 5050,
        lanAddress: '192.168.1.10',
      ),
    );
    final controller = MatchController(
      storage: storage,
      transport: transport,
      now: () => DateTime.utc(2026, 1, 1, 12, 0, 0),
    );

    await controller.setClockPreset(MatchTimerPreset.fifteenMinutes);
    await controller.startLocalMatch();
    await controller.tapSquare(4, 6);
    await controller.tapSquare(4, 4);

    expect(storage.savedState?.clockPreset, MatchTimerPreset.fifteenMinutes);
    expect(controller.analyticsRows.length, 1);
    expect(controller.analyticsRows.first['Move #'], 1);
    expect(controller.analyticsRows.first['Clock'], MatchTimerPreset.fifteenMinutes.label);
    expect(controller.analyticsCsv, contains('Move #'));
    expect(controller.analyticsCsv, contains('Move time'));
  });
}
