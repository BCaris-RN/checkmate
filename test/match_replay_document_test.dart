import 'package:flutter_test/flutter_test.dart';

import 'package:checkmate_by_caris/features/match/match_models.dart';
import 'package:checkmate_by_caris/features/match/presentation/match_viewer_screen.dart';

void main() {
  test('imports queenside castling replay tokens', () {
    final replay = MatchReplayDocument.fromMoveList('''
Checkmate replay
Generated 2026-01-01T00:00:00.000Z
1. d2-d4 d7-d5
2. b1-c3 b8-c6
3. c1-f4 c8-f5
4. d1-d2 d8-d7
5. O-O-O
''');

    final castled = replay.snapshots.last;

    expect(
      castled.pieceAt(const ChessSquare(file: 2, row: 7)),
      const ChessPiece(
        color: ChessColor.white,
        type: ChessPieceType.king,
        hasMoved: true,
      ),
    );
    expect(
      castled.pieceAt(const ChessSquare(file: 3, row: 7)),
      const ChessPiece(
        color: ChessColor.white,
        type: ChessPieceType.rook,
        hasMoved: true,
      ),
    );
    expect(castled.moves.last.isCastling, isTrue);
  });
}
