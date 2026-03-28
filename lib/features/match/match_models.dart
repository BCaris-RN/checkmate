import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/tokens/design_tokens.g.dart';

enum MatchToken { blue, ink }

extension MatchTokenX on MatchToken {
  String get label => switch (this) {
        MatchToken.blue => 'Blue',
        MatchToken.ink => 'Ink',
      };

  String get shortLabel => switch (this) {
        MatchToken.blue => 'B',
        MatchToken.ink => 'I',
      };

  Color get color => switch (this) {
        MatchToken.blue => AppColors.accent,
        MatchToken.ink => AppColors.textPrimary,
      };

  MatchToken get opponent => switch (this) {
        MatchToken.blue => MatchToken.ink,
        MatchToken.ink => MatchToken.blue,
      };
}

enum MatchPhase { playing, blueWon, inkWon, draw }

enum MatchRole { local, host, guest }

class MatchRuleError implements Exception {
  const MatchRuleError(this.message);

  final String message;

  @override
  String toString() => message;
}

class MatchMove {
  const MatchMove({
    required this.column,
    required this.row,
    required this.player,
    required this.playedAt,
  });

  final int column;
  final int row;
  final MatchToken player;
  final DateTime playedAt;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'column': column,
      'row': row,
      'player': player.name,
      'playedAt': playedAt.toUtc().toIso8601String(),
    };
  }

  factory MatchMove.fromJson(Map<String, dynamic> json) {
    return MatchMove(
      column: (json['column'] as num).toInt(),
      row: (json['row'] as num).toInt(),
      player: MatchToken.values.byName(json['player'] as String),
      playedAt: DateTime.parse(json['playedAt'] as String).toUtc(),
    );
  }
}

List<List<MatchToken?>> _freezeBoard(List<List<MatchToken?>> board) {
  return List<List<MatchToken?>>.unmodifiable(
    board.map((row) => List<MatchToken?>.unmodifiable(row)),
  );
}

List<List<MatchToken?>> _cloneBoard(List<List<MatchToken?>> board) {
  return List<List<MatchToken?>>.generate(
    board.length,
    (index) => List<MatchToken?>.from(board[index]),
    growable: false,
  );
}

MatchToken? _tokenFromJson(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  return MatchToken.values.byName(value);
}

MatchPhase _phaseFromJson(Object? value) {
  if (value is! String || value.isEmpty) {
    return MatchPhase.playing;
  }
  return MatchPhase.values.byName(value);
}

List<List<MatchToken?>> _boardFromJson(Object? value) {
  if (value is! List || value.length != MatchSession.rows) {
    return MatchSession.initial().board;
  }

  return List<List<MatchToken?>>.generate(
    MatchSession.rows,
    (rowIndex) {
      final row = value[rowIndex];
      if (row is! List || row.length != MatchSession.columns) {
        return List<MatchToken?>.filled(MatchSession.columns, null);
      }
      return List<MatchToken?>.generate(
        MatchSession.columns,
        (columnIndex) => _tokenFromJson(row[columnIndex]),
        growable: false,
      );
    },
    growable: false,
  );
}

class MatchSession {
  MatchSession._({
    required List<List<MatchToken?>> board,
    required this.activePlayer,
    required this.phase,
    required this.moves,
    required this.updatedAt,
    required this.note,
    required this.winner,
  }) : board = _freezeBoard(board);

  static const int columns = 7;
  static const int rows = 6;

  factory MatchSession.initial({DateTime? updatedAt}) {
    final timestamp = (updatedAt ?? DateTime.now()).toUtc();
    return MatchSession._(
      board: List<List<MatchToken?>>.generate(
        rows,
        (_) => List<MatchToken?>.filled(columns, null, growable: false),
        growable: false,
      ),
      activePlayer: MatchToken.blue,
      phase: MatchPhase.playing,
      moves: const <MatchMove>[],
      updatedAt: timestamp,
      note: 'Blue opens the board.',
      winner: null,
    );
  }

  factory MatchSession.fromJson(Map<String, dynamic> json) {
    final board = _boardFromJson(json['board']);
    final movesJson = json['moves'];
    final moves = movesJson is List
        ? movesJson
            .whereType<Map<String, dynamic>>()
            .map(MatchMove.fromJson)
            .toList(growable: false)
        : <MatchMove>[];

    return MatchSession._(
      board: _freezeBoard(board),
      activePlayer: _tokenFromJson(json['activePlayer']) ?? MatchToken.blue,
      phase: _phaseFromJson(json['phase']),
      moves: List<MatchMove>.unmodifiable(moves),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
      note: (json['note'] as String?)?.trim().isNotEmpty == true
          ? (json['note'] as String)
          : 'Blue opens the board.',
      winner: _tokenFromJson(json['winner']),
    );
  }

  final List<List<MatchToken?>> board;
  final MatchToken activePlayer;
  final MatchPhase phase;
  final List<MatchMove> moves;
  final DateTime updatedAt;
  final String note;
  final MatchToken? winner;

  bool get isComplete => phase != MatchPhase.playing;

  String get statusLabel => switch (phase) {
        MatchPhase.playing => '${activePlayer.label} to move',
        MatchPhase.blueWon => 'Blue wins',
        MatchPhase.inkWon => 'Ink wins',
        MatchPhase.draw => 'Board full',
      };

  MatchSession reset({DateTime? updatedAt}) {
    return MatchSession.initial(updatedAt: updatedAt);
  }

  MatchSession playColumn(int column, {DateTime? playedAt}) {
    if (column < 0 || column >= columns) {
      throw const MatchRuleError('That lane is outside the board.');
    }
    if (isComplete) {
      throw const MatchRuleError('This match is already complete.');
    }

    final targetRow = _landingRow(column);
    if (targetRow == null) {
      throw const MatchRuleError('That lane is full.');
    }

    final nextBoard = _cloneBoard(board);
    nextBoard[targetRow][column] = activePlayer;

    final move = MatchMove(
      column: column,
      row: targetRow,
      player: activePlayer,
      playedAt: (playedAt ?? DateTime.now()).toUtc(),
    );
    final didWin = _hasWinningLine(nextBoard, targetRow, column, activePlayer);
    final didDraw = !didWin && _boardIsFull(nextBoard);
    final nextPhase = switch ((didWin, didDraw, activePlayer)) {
      (true, _, MatchToken.blue) => MatchPhase.blueWon,
      (true, _, MatchToken.ink) => MatchPhase.inkWon,
      (_, true, _) => MatchPhase.draw,
      _ => MatchPhase.playing,
    };
    final nextPlayer = didWin || didDraw ? activePlayer : activePlayer.opponent;
    final nextNote = switch (nextPhase) {
      MatchPhase.playing => '${nextPlayer.label} to move.',
      MatchPhase.blueWon => 'Blue connects four.',
      MatchPhase.inkWon => 'Ink connects four.',
      MatchPhase.draw => 'The board is full.',
    };

    return MatchSession._(
      board: _freezeBoard(nextBoard),
      activePlayer: nextPlayer,
      phase: nextPhase,
      moves: List<MatchMove>.unmodifiable(<MatchMove>[...moves, move]),
      updatedAt: move.playedAt,
      note: nextNote,
      winner: switch (nextPhase) {
        MatchPhase.blueWon => MatchToken.blue,
        MatchPhase.inkWon => MatchToken.ink,
        _ => null,
      },
    );
  }

  int? _landingRow(int column) {
    for (var row = rows - 1; row >= 0; row -= 1) {
      if (board[row][column] == null) {
        return row;
      }
    }
    return null;
  }

  bool _boardIsFull(List<List<MatchToken?>> candidateBoard) {
    return candidateBoard.every((row) => row.every((cell) => cell != null));
  }

  bool _hasWinningLine(
    List<List<MatchToken?>> candidateBoard,
    int row,
    int column,
    MatchToken token,
  ) {
    const directions = <({int rowDelta, int columnDelta})>[
      (rowDelta: 0, columnDelta: 1),
      (rowDelta: 1, columnDelta: 0),
      (rowDelta: 1, columnDelta: 1),
      (rowDelta: 1, columnDelta: -1),
    ];

    for (final direction in directions) {
      var count = 1;
      count += _countDirection(
        candidateBoard,
        row,
        column,
        token,
        direction.rowDelta,
        direction.columnDelta,
      );
      count += _countDirection(
        candidateBoard,
        row,
        column,
        token,
        -direction.rowDelta,
        -direction.columnDelta,
      );
      if (count >= 4) {
        return true;
      }
    }
    return false;
  }

  int _countDirection(
    List<List<MatchToken?>> candidateBoard,
    int row,
    int column,
    MatchToken token,
    int rowDelta,
    int columnDelta,
  ) {
    var count = 0;
    var nextRow = row + rowDelta;
    var nextColumn = column + columnDelta;

    while (nextRow >= 0 &&
        nextRow < rows &&
        nextColumn >= 0 &&
        nextColumn < columns &&
        candidateBoard[nextRow][nextColumn] == token) {
      count += 1;
      nextRow += rowDelta;
      nextColumn += columnDelta;
    }

    return count;
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'board': board
          .map(
            (row) => row.map((token) => token?.name).toList(growable: false),
          )
          .toList(growable: false),
      'activePlayer': activePlayer.name,
      'phase': phase.name,
      'moves': moves.map((move) => move.toJson()).toList(growable: false),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'note': note,
      'winner': winner?.name,
    };
  }
}

String encodeSession(MatchSession session) => jsonEncode(session.toJson());
