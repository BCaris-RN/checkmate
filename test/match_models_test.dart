import 'package:flutter_test/flutter_test.dart';

import 'package:checkmate_by_caris/features/match/match_models.dart';

void main() {
  test('drops tokens into the lowest empty slot', () {
    final session = MatchSession.initial()
        .playColumn(0)
        .playColumn(0)
        .playColumn(1);

    expect(session.board[5][0], MatchToken.blue);
    expect(session.board[4][0], MatchToken.ink);
    expect(session.board[5][1], MatchToken.blue);
    expect(session.activePlayer, MatchToken.ink);
    expect(session.statusLabel, 'Ink to move');
  });

  test('detects a horizontal win', () {
    final session = MatchSession.initial()
        .playColumn(0)
        .playColumn(0)
        .playColumn(1)
        .playColumn(1)
        .playColumn(2)
        .playColumn(2)
        .playColumn(3);

    expect(session.phase, MatchPhase.blueWon);
    expect(session.winner, MatchToken.blue);
    expect(session.isComplete, isTrue);
  });

  test('serializes and restores session state', () {
    final session = MatchSession.initial()
        .playColumn(0)
        .playColumn(1)
        .playColumn(0);

    final restored = MatchSession.fromJson(session.toJson().cast<String, dynamic>());

    expect(restored.activePlayer, session.activePlayer);
    expect(restored.phase, session.phase);
    expect(restored.moves.length, session.moves.length);
    expect(restored.board[5][0], MatchToken.blue);
    expect(restored.board[5][1], MatchToken.ink);
  });
}
