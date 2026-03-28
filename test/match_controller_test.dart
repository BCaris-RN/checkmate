import 'package:flutter_test/flutter_test.dart';

import 'package:checkmate_by_caris/features/match/match_controller.dart';
import 'package:checkmate_by_caris/features/match/match_models.dart';
import 'package:checkmate_by_caris/features/match/match_storage.dart';
import 'package:checkmate_by_caris/features/match/match_transport.dart';

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

  @override
  Future<HostLaunchResult> startHost({
    required Future<MatchSession> Function() readSession,
    required Future<MatchSession> Function(int column) applyMove,
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
  Future<MatchSession> submitMove(Uri baseUri, int column) {
    throw UnimplementedError('submitMove is not used in these tests.');
  }

  @override
  Future<MatchSession> reset(Uri baseUri) {
    throw UnimplementedError('reset is not used in these tests.');
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
}
