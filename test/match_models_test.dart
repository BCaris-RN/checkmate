import 'package:flutter_test/flutter_test.dart';

import 'package:checkmate_by_caris/features/match/match_models.dart';

void main() {
  test('starts with the standard chess layout from the white view', () {
    final session = MatchSession.initial();

    expect(session.board.length, MatchSession.rows);
    expect(
      session.board.every((row) => row.length == MatchSession.columns),
      isTrue,
    );
    expect(
      session.board[7][4],
      const ChessPiece(color: ChessColor.white, type: ChessPieceType.king),
    );
    expect(
      session.board[7][3],
      const ChessPiece(color: ChessColor.white, type: ChessPieceType.queen),
    );
    expect(
      session.board[0][4],
      const ChessPiece(color: ChessColor.black, type: ChessPieceType.king),
    );
    expect(
      session.board[0][3],
      const ChessPiece(color: ChessColor.black, type: ChessPieceType.queen),
    );
    expect(
      session.board[6][4],
      const ChessPiece(color: ChessColor.white, type: ChessPieceType.pawn),
    );
    expect(
      session.board[1][4],
      const ChessPiece(color: ChessColor.black, type: ChessPieceType.pawn),
    );
    expect(session.activeColor, ChessColor.white);
    expect(session.statusLabel, 'White to move');
  });

  test('allows a legal white pawn advance and serializes the result', () {
    final e2 = ChessSquare(file: 4, row: 6);
    final e3 = ChessSquare(file: 4, row: 5);
    final e4 = ChessSquare(file: 4, row: 4);

    final session = MatchSession.initial();
    final legalMoves = session.legalMovesFrom(e2);

    expect(
      legalMoves,
      containsAll(<ChessMove>[
        ChessMove(from: e2, to: e3),
        ChessMove(from: e2, to: e4),
      ]),
    );

    final next = session.playMove(ChessMove(from: e2, to: e4));

    expect(
      next.board[4][4],
      const ChessPiece(
        color: ChessColor.white,
        type: ChessPieceType.pawn,
        hasMoved: true,
      ),
    );
    expect(next.activeColor, ChessColor.black);
    expect(next.statusLabel, 'Black to move');

    final restored = MatchSession.fromJson(
      next.toJson().cast<String, dynamic>(),
    );

    expect(restored.activeColor, ChessColor.black);
    expect(restored.moves.length, 1);
    expect(restored.board[4][4], next.board[4][4]);
  });

  test('offers queen, rook, bishop, and knight promotion choices', () {
    final session = MatchSession.fromJson({
      'board': _emptyBoard()
        ..[0][4] = const ChessPiece(
          color: ChessColor.black,
          type: ChessPieceType.king,
        ).toJson()
        ..[1][0] = const ChessPiece(
          color: ChessColor.white,
          type: ChessPieceType.pawn,
        ).toJson()
        ..[7][4] = const ChessPiece(
          color: ChessColor.white,
          type: ChessPieceType.king,
        ).toJson(),
      'activeColor': 'white',
      'phase': 'playing',
      'moves': <Object?>[],
      'updatedAt': DateTime.utc(2026, 1, 1).toIso8601String(),
      'enPassantTarget': null,
    });

    final moves = session.legalMovesFrom(const ChessSquare(file: 0, row: 1));

    expect(
      moves.map((move) => move.promotion),
      containsAll(<ChessPieceType>[
        ChessPieceType.queen,
        ChessPieceType.rook,
        ChessPieceType.bishop,
        ChessPieceType.knight,
      ]),
    );

    final promoted = session.playMove(
      const ChessMove(
        from: ChessSquare(file: 0, row: 1),
        to: ChessSquare(file: 0, row: 0),
        promotion: ChessPieceType.knight,
      ),
    );

    expect(
      promoted.board[0][0],
      const ChessPiece(
        color: ChessColor.white,
        type: ChessPieceType.knight,
        hasMoved: true,
      ),
    );
  });

  test('draws after the 21-move lone king counter expires', () {
    final session = MatchSession.fromJson({
      'board': _emptyBoard()
        ..[0][4] = const ChessPiece(
          color: ChessColor.black,
          type: ChessPieceType.king,
        ).toJson()
        ..[7][4] = const ChessPiece(
          color: ChessColor.white,
          type: ChessPieceType.king,
        ).toJson(),
      'activeColor': 'white',
      'phase': 'playing',
      'moves': <Object?>[],
      'updatedAt': DateTime.utc(2026, 1, 1).toIso8601String(),
      'enPassantTarget': null,
      'loneKingPlyCount': 41,
    });

    expect(session.loneKingMovesRemaining, 1);

    final drawn = session.playMove(
      const ChessMove(
        from: ChessSquare(file: 4, row: 7),
        to: ChessSquare(file: 4, row: 6),
      ),
    );

    expect(drawn.phase, MatchPhase.draw);
    expect(drawn.statusLabel, 'Draw by 21-move lone king rule');
  });
}

List<List<Object?>> _emptyBoard() {
  return List<List<Object?>>.generate(
    MatchSession.rows,
    (_) => List<Object?>.filled(MatchSession.columns, null),
  );
}
