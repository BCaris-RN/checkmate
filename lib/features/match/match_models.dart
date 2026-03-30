import 'match_time.dart';

enum MatchRole { local, host, guest }

enum MatchPhase { playing, whiteWon, blackWon, draw }

enum ChessColor { white, black }

enum ChessPieceType { king, queen, rook, bishop, knight, pawn }

extension ChessColorX on ChessColor {
  ChessColor get opponent =>
      this == ChessColor.white ? ChessColor.black : ChessColor.white;

  String get label => this == ChessColor.white ? 'White' : 'Black';

  String get shortLabel => this == ChessColor.white ? 'W' : 'B';

  int get forwardRowDelta => this == ChessColor.white ? -1 : 1;
}

extension ChessPieceTypeX on ChessPieceType {
  String get label => switch (this) {
        ChessPieceType.king => 'king',
        ChessPieceType.queen => 'queen',
        ChessPieceType.rook => 'rook',
        ChessPieceType.bishop => 'bishop',
        ChessPieceType.knight => 'knight',
        ChessPieceType.pawn => 'pawn',
      };

  String get shortLabel => switch (this) {
        ChessPieceType.king => 'K',
        ChessPieceType.queen => 'Q',
        ChessPieceType.rook => 'R',
        ChessPieceType.bishop => 'B',
        ChessPieceType.knight => 'N',
        ChessPieceType.pawn => 'P',
      };

  String symbolFor(ChessColor color) => switch (this) {
        ChessPieceType.king => color == ChessColor.white ? '♔' : '♚',
        ChessPieceType.queen => color == ChessColor.white ? '♕' : '♛',
        ChessPieceType.rook => color == ChessColor.white ? '♖' : '♜',
        ChessPieceType.bishop => color == ChessColor.white ? '♗' : '♝',
        ChessPieceType.knight => color == ChessColor.white ? '♘' : '♞',
        ChessPieceType.pawn => color == ChessColor.white ? '♙' : '♟',
      };
}

class MatchRuleError implements Exception {
  const MatchRuleError(this.message);

  final String message;

  @override
  String toString() => message;
}

class ChessSquare {
  const ChessSquare({
    required this.file,
    required this.row,
  });

  final int file;
  final int row;

  bool get isInsideBoard => file >= 0 && file < 8 && row >= 0 && row < 8;

  int get rank => 8 - row;

  String get fileLabel => String.fromCharCode(97 + file);

  String get notation => '$fileLabel$rank';

  ChessSquare offset(int fileDelta, int rowDelta) {
    return ChessSquare(file: file + fileDelta, row: row + rowDelta);
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'file': file,
      'row': row,
    };
  }

  factory ChessSquare.fromJson(Map<String, dynamic> json) {
    return ChessSquare(
      file: (json['file'] as num).toInt(),
      row: (json['row'] as num).toInt(),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ChessSquare && other.file == file && other.row == row;
  }

  @override
  int get hashCode => Object.hash(file, row);

  @override
  String toString() => notation;
}

class ChessPiece {
  const ChessPiece({
    required this.color,
    required this.type,
    this.hasMoved = false,
  });

  final ChessColor color;
  final ChessPieceType type;
  final bool hasMoved;

  ChessPiece copyWith({
    ChessColor? color,
    ChessPieceType? type,
    bool? hasMoved,
  }) {
    return ChessPiece(
      color: color ?? this.color,
      type: type ?? this.type,
      hasMoved: hasMoved ?? this.hasMoved,
    );
  }

  String get symbol => type.symbolFor(color);

  String get label => '${color.label} ${type.label}';

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'color': color.name,
      'type': type.name,
      'hasMoved': hasMoved,
    };
  }

  factory ChessPiece.fromJson(Map<String, dynamic> json) {
    return ChessPiece(
      color: ChessColor.values.byName(json['color'] as String),
      type: ChessPieceType.values.byName(json['type'] as String),
      hasMoved: json['hasMoved'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ChessPiece &&
        other.color == color &&
        other.type == type &&
        other.hasMoved == hasMoved;
  }

  @override
  int get hashCode => Object.hash(color, type, hasMoved);

  @override
  String toString() => label;
}

class ChessMove {
  const ChessMove({
    required this.from,
    required this.to,
    this.promotion,
  });

  final ChessSquare from;
  final ChessSquare to;
  final ChessPieceType? promotion;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'from': from.toJson(),
      'to': to.toJson(),
      'promotion': promotion?.name,
    };
  }

  factory ChessMove.fromJson(Map<String, dynamic> json) {
    final rawPromotion = json['promotion'];
    return ChessMove(
      from: ChessSquare.fromJson(json['from'] as Map<String, dynamic>),
      to: ChessSquare.fromJson(json['to'] as Map<String, dynamic>),
      promotion: rawPromotion is String
          ? ChessPieceType.values.byName(rawPromotion)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ChessMove &&
        other.from == from &&
        other.to == to &&
        other.promotion == promotion;
  }

  @override
  int get hashCode => Object.hash(from, to, promotion);

  @override
  String toString() {
    final promotionText = promotion == null ? '' : '=${promotion!.shortLabel}';
    return '${from.notation}${to.notation}$promotionText';
  }
}

class ChessMoveRecord {
  const ChessMoveRecord({
    required this.color,
    required this.piece,
    required this.from,
    required this.to,
    this.captured,
    this.promotion,
    required this.isCastling,
    required this.isEnPassant,
    this.elapsedMilliseconds,
    this.recordedAtUtc,
    this.timerPreset,
  });

  final ChessColor color;
  final ChessPieceType piece;
  final ChessSquare from;
  final ChessSquare to;
  final ChessPieceType? captured;
  final ChessPieceType? promotion;
  final bool isCastling;
  final bool isEnPassant;
  final int? elapsedMilliseconds;
  final DateTime? recordedAtUtc;
  final MatchTimerPreset? timerPreset;

  String get summary {
    final buffer = StringBuffer(
      '${color.label} ${piece.label} ${from.notation} -> ${to.notation}',
    );
    if (captured != null) {
      buffer.write(' x ${captured!.label}');
    }
    if (promotion != null) {
      buffer.write(' = ${promotion!.label}');
    }
    if (isCastling) {
      buffer.write(' (castle)');
    }
    if (isEnPassant) {
      buffer.write(' (en passant)');
    }
    return buffer.toString();
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'color': color.name,
      'piece': piece.name,
      'from': from.toJson(),
      'to': to.toJson(),
      'captured': captured?.name,
      'promotion': promotion?.name,
      'isCastling': isCastling,
      'isEnPassant': isEnPassant,
      'elapsedMilliseconds': elapsedMilliseconds,
      'recordedAtUtc': recordedAtUtc?.toIso8601String(),
      'timerPreset': timerPreset?.name,
    };
  }

  factory ChessMoveRecord.fromJson(Map<String, dynamic> json) {
    final rawCaptured = json['captured'];
    final rawPromotion = json['promotion'];
    final rawTimerPreset = json['timerPreset'];
    return ChessMoveRecord(
      color: ChessColor.values.byName(json['color'] as String),
      piece: ChessPieceType.values.byName(json['piece'] as String),
      from: ChessSquare.fromJson(json['from'] as Map<String, dynamic>),
      to: ChessSquare.fromJson(json['to'] as Map<String, dynamic>),
      captured: rawCaptured is String
          ? ChessPieceType.values.byName(rawCaptured)
          : null,
      promotion: rawPromotion is String
          ? ChessPieceType.values.byName(rawPromotion)
          : null,
      isCastling: json['isCastling'] as bool? ?? false,
      isEnPassant: json['isEnPassant'] as bool? ?? false,
      elapsedMilliseconds: (json['elapsedMilliseconds'] as num?)?.toInt(),
      recordedAtUtc: (json['recordedAtUtc'] as String?) == null
          ? null
          : DateTime.parse(json['recordedAtUtc'] as String).toUtc(),
      timerPreset: rawTimerPreset is String
          ? MatchTimerPreset.values.byName(rawTimerPreset)
          : null,
    );
  }
}

class MatchSession {
  MatchSession._({
    required List<List<ChessPiece?>> board,
    required this.activeColor,
    required this.phase,
    required this.moves,
    required this.updatedAt,
    required this.enPassantTarget,
  }) : board = _freezeBoard(board);

  static const int columns = 8;
  static const int rows = 8;

  final List<List<ChessPiece?>> board;
  final ChessColor activeColor;
  final MatchPhase phase;
  final List<ChessMoveRecord> moves;
  final DateTime updatedAt;
  final ChessSquare? enPassantTarget;

  factory MatchSession.initial() {
    return MatchSession._(
      board: _startingBoard(),
      activeColor: ChessColor.white,
      phase: MatchPhase.playing,
      moves: const <ChessMoveRecord>[],
      updatedAt: DateTime.now().toUtc(),
      enPassantTarget: null,
    );
  }

  factory MatchSession.fromJson(Map<String, dynamic> json) {
    try {
      final rawBoard = json['board'];
      final rawMoves = json['moves'];
      final board = rawBoard is List ? _parseBoard(rawBoard) : _startingBoard();
      final moves = rawMoves is List
          ? rawMoves
              .whereType<Map<String, dynamic>>()
              .map(ChessMoveRecord.fromJson)
              .toList(growable: false)
          : const <ChessMoveRecord>[];

      final rawActiveColor = json['activeColor'];
      final rawPhase = json['phase'];
      final rawUpdatedAt = json['updatedAt'];
      final rawEnPassantTarget = json['enPassantTarget'];

      return MatchSession._(
        board: board,
        activeColor: rawActiveColor is String
            ? ChessColor.values.byName(rawActiveColor)
            : ChessColor.white,
        phase: rawPhase is String
            ? MatchPhase.values.byName(rawPhase)
            : MatchPhase.playing,
        moves: moves,
        updatedAt: rawUpdatedAt is String
            ? DateTime.parse(rawUpdatedAt).toUtc()
            : DateTime.now().toUtc(),
        enPassantTarget: rawEnPassantTarget is Map<String, dynamic>
            ? ChessSquare.fromJson(rawEnPassantTarget)
            : null,
      );
    } catch (_) {
      return MatchSession.initial();
    }
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'board': board
          .map(
            (row) => row
                .map((piece) => piece?.toJson())
                .toList(growable: false),
          )
          .toList(growable: false),
      'activeColor': activeColor.name,
      'phase': phase.name,
      'moves': moves.map((move) => move.toJson()).toList(growable: false),
      'updatedAt': updatedAt.toIso8601String(),
      'enPassantTarget': enPassantTarget?.toJson(),
    };
  }

  bool get isComplete => phase != MatchPhase.playing;

  ChessColor? get winner => switch (phase) {
        MatchPhase.whiteWon => ChessColor.white,
        MatchPhase.blackWon => ChessColor.black,
        _ => null,
      };

  ChessSquare? get checkedKingSquare {
    final square = kingSquare(activeColor);
    if (square == null) {
      return null;
    }
    return isSquareAttacked(square, activeColor.opponent) ? square : null;
  }

  String get statusLabel {
    return switch (phase) {
      MatchPhase.whiteWon => 'White wins by checkmate',
      MatchPhase.blackWon => 'Black wins by checkmate',
      MatchPhase.draw => 'Draw by stalemate',
      MatchPhase.playing => isInCheck(activeColor)
          ? '${activeColor.label} to move, in check'
          : '${activeColor.label} to move',
    };
  }

  String get note {
    return switch (phase) {
      MatchPhase.whiteWon => 'Checkmate. White wins.',
      MatchPhase.blackWon => 'Checkmate. Black wins.',
      MatchPhase.draw => 'Stalemate. Game drawn.',
      MatchPhase.playing => isInCheck(activeColor)
          ? '${activeColor.label} is in check. Find a legal escape.'
          : '${activeColor.label} to move. Tap a piece, then tap a highlighted square.',
    };
  }

  ChessPiece? pieceAt(ChessSquare square) {
    if (!square.isInsideBoard) {
      return null;
    }
    return board[square.row][square.file];
  }

  List<ChessMove> legalMovesFrom(ChessSquare square) {
    if (isComplete) {
      return const <ChessMove>[];
    }

    final piece = pieceAt(square);
    if (piece == null || piece.color != activeColor) {
      return const <ChessMove>[];
    }

    final pseudoMoves = _pseudoMovesFrom(square, piece);
    final legalMoves = <ChessMove>[];

    for (final move in pseudoMoves) {
      final simulated = _applyMoveUnchecked(move, resolveOutcome: false);
      if (!simulated.isInCheck(piece.color)) {
        legalMoves.add(move);
      }
    }

    return List.unmodifiable(legalMoves);
  }

  MatchSession reset() => MatchSession.initial();

  MatchSession playMove(
    ChessMove move, {
    int? elapsedMilliseconds,
    DateTime? recordedAtUtc,
    MatchTimerPreset? timerPreset,
  }) {
    if (isComplete) {
      throw const MatchRuleError('The game is already complete.');
    }

    final piece = pieceAt(move.from);
    if (piece == null) {
      throw MatchRuleError('No piece is on ${move.from.notation}.');
    }
    if (piece.color != activeColor) {
      throw MatchRuleError('It is ${activeColor.label.toLowerCase()}\'s turn.');
    }

    final legalMoves = legalMovesFrom(move.from);
    final resolvedMove = _resolveRequestedMove(move, legalMoves);
    if (resolvedMove == null) {
      throw MatchRuleError('That move is not legal for ${move.from.notation}.');
    }

    return _applyMoveUnchecked(
      resolvedMove,
      resolveOutcome: true,
      elapsedMilliseconds: elapsedMilliseconds,
      recordedAtUtc: recordedAtUtc,
      timerPreset: timerPreset,
    );
  }

  bool isInCheck(ChessColor color) {
    final square = kingSquare(color);
    if (square == null) {
      return false;
    }
    return isSquareAttacked(square, color.opponent);
  }

  ChessSquare? kingSquare(ChessColor color) {
    for (var row = 0; row < rows; row += 1) {
      for (var file = 0; file < columns; file += 1) {
        final piece = board[row][file];
        if (piece != null &&
            piece.color == color &&
            piece.type == ChessPieceType.king) {
          return ChessSquare(file: file, row: row);
        }
      }
    }
    return null;
  }

  bool isSquareAttacked(ChessSquare square, ChessColor byColor) {
    final pawnRow =
        square.row + (byColor == ChessColor.white ? 1 : -1);
    for (final fileDelta in <int>[-1, 1]) {
      final attackerSquare = ChessSquare(
        file: square.file + fileDelta,
        row: pawnRow,
      );
      if (!_isInsideSquare(attackerSquare)) {
        continue;
      }
      final attacker = pieceAt(attackerSquare);
      if (attacker != null &&
          attacker.color == byColor &&
          attacker.type == ChessPieceType.pawn) {
        return true;
      }
    }

    const knightOffsets = <List<int>>[
      <int>[-2, -1],
      <int>[-2, 1],
      <int>[-1, -2],
      <int>[-1, 2],
      <int>[1, -2],
      <int>[1, 2],
      <int>[2, -1],
      <int>[2, 1],
    ];
    for (final offset in knightOffsets) {
      final attackerSquare = ChessSquare(
        file: square.file + offset[0],
        row: square.row + offset[1],
      );
      if (!_isInsideSquare(attackerSquare)) {
        continue;
      }
      final attacker = pieceAt(attackerSquare);
      if (attacker != null &&
          attacker.color == byColor &&
          attacker.type == ChessPieceType.knight) {
        return true;
      }
    }

    const bishopDirections = <List<int>>[
      <int>[-1, -1],
      <int>[-1, 1],
      <int>[1, -1],
      <int>[1, 1],
    ];
    for (final direction in bishopDirections) {
      if (_rayAttacked(
        square,
        byColor,
        fileDelta: direction[0],
        rowDelta: direction[1],
        attackers: <ChessPieceType>{
          ChessPieceType.bishop,
          ChessPieceType.queen,
        },
      )) {
        return true;
      }
    }

    const rookDirections = <List<int>>[
      <int>[-1, 0],
      <int>[1, 0],
      <int>[0, -1],
      <int>[0, 1],
    ];
    for (final direction in rookDirections) {
      if (_rayAttacked(
        square,
        byColor,
        fileDelta: direction[0],
        rowDelta: direction[1],
        attackers: <ChessPieceType>{
          ChessPieceType.rook,
          ChessPieceType.queen,
        },
      )) {
        return true;
      }
    }

    for (final fileDelta in <int>[-1, 0, 1]) {
      for (final rowDelta in <int>[-1, 0, 1]) {
        if (fileDelta == 0 && rowDelta == 0) {
          continue;
        }
        final attackerSquare = ChessSquare(
          file: square.file + fileDelta,
          row: square.row + rowDelta,
        );
      if (!_isInsideSquare(attackerSquare)) {
          continue;
        }
        final attacker = pieceAt(attackerSquare);
        if (attacker != null &&
            attacker.color == byColor &&
            attacker.type == ChessPieceType.king) {
          return true;
        }
      }
    }

    return false;
  }

  bool _rayAttacked(
    ChessSquare target,
    ChessColor byColor, {
    required int fileDelta,
    required int rowDelta,
    required Set<ChessPieceType> attackers,
  }) {
    var file = target.file + fileDelta;
    var row = target.row + rowDelta;
    while (_isInside(file: file, row: row)) {
      final piece = board[row][file];
      if (piece != null) {
        return piece.color == byColor && attackers.contains(piece.type);
      }
      file += fileDelta;
      row += rowDelta;
    }
    return false;
  }

  bool _hasAnyLegalMove() {
    for (var row = 0; row < rows; row += 1) {
      for (var file = 0; file < columns; file += 1) {
        final piece = board[row][file];
        if (piece != null && piece.color == activeColor) {
          if (legalMovesFrom(ChessSquare(file: file, row: row)).isNotEmpty) {
            return true;
          }
        }
      }
    }
    return false;
  }

  MatchPhase _resolveOutcome() {
    final inCheck = isInCheck(activeColor);
    final hasLegalMove = _hasAnyLegalMove();
    if (!hasLegalMove) {
      if (inCheck) {
        return activeColor == ChessColor.white
            ? MatchPhase.blackWon
            : MatchPhase.whiteWon;
      }
      return MatchPhase.draw;
    }
    return MatchPhase.playing;
  }

  MatchSession _applyMoveUnchecked(
    ChessMove move, {
    required bool resolveOutcome,
    int? elapsedMilliseconds,
    DateTime? recordedAtUtc,
    MatchTimerPreset? timerPreset,
  }) {
    final movingPiece = pieceAt(move.from);
    if (movingPiece == null) {
      throw MatchRuleError('No piece is on ${move.from.notation}.');
    }

    final nextBoard = _cloneBoard(board);
    final nextMoves = List<ChessMoveRecord>.of(moves);
    final nextActiveColor = activeColor.opponent;
    ChessSquare? nextEnPassantTarget;
    ChessPiece? capturedPiece = pieceAt(move.to);
    var isCastling = false;
    var isEnPassant = false;

    nextBoard[move.from.row][move.from.file] = null;

    var placedPiece = movingPiece.copyWith(hasMoved: true);
    final isPawnPromotionRank = movingPiece.type == ChessPieceType.pawn &&
        _isPromotionRank(move.to, movingPiece.color);
    final promotionType = isPawnPromotionRank
        ? (move.promotion ?? ChessPieceType.queen)
        : null;

    if (movingPiece.type == ChessPieceType.pawn) {
      final rowDelta = move.to.row - move.from.row;
      if (rowDelta.abs() == 2) {
        nextEnPassantTarget = ChessSquare(
          file: move.from.file,
          row: move.from.row + (rowDelta ~/ 2),
        );
      }

      if (move.from.file != move.to.file &&
          capturedPiece == null &&
          enPassantTarget == move.to) {
        final captureSquare = ChessSquare(
          file: move.to.file,
          row: move.from.row,
        );
        final enPassantPiece = pieceAt(captureSquare);
        if (enPassantPiece == null ||
            enPassantPiece.color == movingPiece.color ||
            enPassantPiece.type != ChessPieceType.pawn) {
          throw const MatchRuleError('That en passant capture is not available.');
        }
        capturedPiece = enPassantPiece;
        nextBoard[captureSquare.row][captureSquare.file] = null;
        isEnPassant = true;
      }
    }

    if (movingPiece.type == ChessPieceType.king &&
        (move.to.file - move.from.file).abs() == 2) {
      isCastling = true;
      final rookFromFile = move.to.file > move.from.file ? 7 : 0;
      final rookToFile = move.to.file > move.from.file ? 5 : 3;
      final rookSquare = ChessSquare(file: rookFromFile, row: move.from.row);
      final rook = pieceAt(rookSquare);
      if (rook == null ||
          rook.color != movingPiece.color ||
          rook.type != ChessPieceType.rook ||
          rook.hasMoved) {
        throw const MatchRuleError('Castling is not available here.');
      }
      nextBoard[rookSquare.row][rookSquare.file] = null;
      nextBoard[move.from.row][rookToFile] = rook.copyWith(hasMoved: true);
    }

    if (promotionType != null) {
      placedPiece = placedPiece.copyWith(type: promotionType);
    }

    nextBoard[move.to.row][move.to.file] = placedPiece;

    final record = ChessMoveRecord(
      color: movingPiece.color,
      piece: movingPiece.type,
      from: move.from,
      to: move.to,
      captured: capturedPiece?.type,
      promotion: promotionType,
      isCastling: isCastling,
      isEnPassant: isEnPassant,
      elapsedMilliseconds: elapsedMilliseconds,
      recordedAtUtc: recordedAtUtc?.toUtc(),
      timerPreset: timerPreset,
    );
    nextMoves.add(record);

    var nextSession = MatchSession._(
      board: nextBoard,
      activeColor: nextActiveColor,
      phase: MatchPhase.playing,
      moves: nextMoves,
      updatedAt: DateTime.now().toUtc(),
      enPassantTarget: nextEnPassantTarget,
    );

    if (resolveOutcome) {
      final resolvedPhase = nextSession._resolveOutcome();
      if (resolvedPhase != MatchPhase.playing) {
        nextSession = MatchSession._(
          board: nextBoard,
          activeColor: nextActiveColor,
          phase: resolvedPhase,
          moves: nextMoves,
          updatedAt: nextSession.updatedAt,
          enPassantTarget: nextEnPassantTarget,
        );
      }
    }

    return nextSession;
  }

  List<ChessMove> _pseudoMovesFrom(ChessSquare square, ChessPiece piece) {
    return switch (piece.type) {
      ChessPieceType.pawn => _pawnMoves(square, piece),
      ChessPieceType.knight => _knightMoves(square, piece),
      ChessPieceType.bishop => _slidingMoves(
          square,
          piece,
          <List<int>>[
            <int>[-1, -1],
            <int>[-1, 1],
            <int>[1, -1],
            <int>[1, 1],
          ],
        ),
      ChessPieceType.rook => _slidingMoves(
          square,
          piece,
          <List<int>>[
            <int>[-1, 0],
            <int>[1, 0],
            <int>[0, -1],
            <int>[0, 1],
          ],
        ),
      ChessPieceType.queen => _slidingMoves(
          square,
          piece,
          <List<int>>[
            <int>[-1, -1],
            <int>[-1, 1],
            <int>[1, -1],
            <int>[1, 1],
            <int>[-1, 0],
            <int>[1, 0],
            <int>[0, -1],
            <int>[0, 1],
          ],
        ),
      ChessPieceType.king => _kingMoves(square, piece),
    };
  }

  List<ChessMove> _pawnMoves(ChessSquare square, ChessPiece piece) {
    final moves = <ChessMove>[];
    final direction = piece.color.forwardRowDelta;
    final startRow = piece.color == ChessColor.white ? 6 : 1;
    final promotionRow = piece.color == ChessColor.white ? 0 : 7;

    final oneStep = square.offset(0, direction);
    if (_isInsideSquare(oneStep) && pieceAt(oneStep) == null) {
      moves.add(
        ChessMove(
          from: square,
          to: oneStep,
          promotion: oneStep.row == promotionRow
              ? ChessPieceType.queen
              : null,
        ),
      );

      final twoStep = square.offset(0, direction * 2);
      if (square.row == startRow &&
          _isInsideSquare(twoStep) &&
          pieceAt(twoStep) == null) {
        moves.add(ChessMove(from: square, to: twoStep));
      }
    }

    for (final fileDelta in <int>[-1, 1]) {
      final captureSquare = square.offset(fileDelta, direction);
      if (!_isInsideSquare(captureSquare)) {
        continue;
      }
      final targetPiece = pieceAt(captureSquare);
      if (targetPiece != null && targetPiece.color != piece.color) {
        moves.add(
          ChessMove(
            from: square,
            to: captureSquare,
            promotion: captureSquare.row == promotionRow
                ? ChessPieceType.queen
                : null,
          ),
        );
        continue;
      }

      if (enPassantTarget == captureSquare) {
        final adjacent = pieceAt(ChessSquare(
          file: captureSquare.file,
          row: square.row,
        ));
        if (adjacent != null &&
            adjacent.color != piece.color &&
            adjacent.type == ChessPieceType.pawn) {
          moves.add(ChessMove(from: square, to: captureSquare));
        }
      }
    }

    return moves;
  }

  List<ChessMove> _knightMoves(ChessSquare square, ChessPiece piece) {
    const offsets = <List<int>>[
      <int>[-2, -1],
      <int>[-2, 1],
      <int>[-1, -2],
      <int>[-1, 2],
      <int>[1, -2],
      <int>[1, 2],
      <int>[2, -1],
      <int>[2, 1],
    ];
    final moves = <ChessMove>[];

    for (final offset in offsets) {
      final target = square.offset(offset[0], offset[1]);
      if (!_isInsideSquare(target)) {
        continue;
      }
      final targetPiece = pieceAt(target);
      if (targetPiece == null || targetPiece.color != piece.color) {
        moves.add(ChessMove(from: square, to: target));
      }
    }

    return moves;
  }

  List<ChessMove> _slidingMoves(
    ChessSquare square,
    ChessPiece piece,
    List<List<int>> directions,
  ) {
    final moves = <ChessMove>[];
    for (final direction in directions) {
      var target = square.offset(direction[0], direction[1]);
      while (_isInsideSquare(target)) {
        final targetPiece = pieceAt(target);
        if (targetPiece == null) {
          moves.add(ChessMove(from: square, to: target));
        } else {
          if (targetPiece.color != piece.color) {
            moves.add(ChessMove(from: square, to: target));
          }
          break;
        }
        target = target.offset(direction[0], direction[1]);
      }
    }
    return moves;
  }

  List<ChessMove> _kingMoves(ChessSquare square, ChessPiece piece) {
    final moves = <ChessMove>[];

    for (final fileDelta in <int>[-1, 0, 1]) {
      for (final rowDelta in <int>[-1, 0, 1]) {
        if (fileDelta == 0 && rowDelta == 0) {
          continue;
        }
        final target = square.offset(fileDelta, rowDelta);
        if (!_isInsideSquare(target)) {
          continue;
        }
        final targetPiece = pieceAt(target);
        if (targetPiece == null || targetPiece.color != piece.color) {
          moves.add(ChessMove(from: square, to: target));
        }
      }
    }

    final homeRow = piece.color == ChessColor.white ? 7 : 0;
    if (!piece.hasMoved &&
        square.row == homeRow &&
        square.file == 4 &&
        !isInCheck(piece.color)) {
      final kingsideClear = [
        ChessSquare(file: 5, row: homeRow),
        ChessSquare(file: 6, row: homeRow),
      ].every((target) => pieceAt(target) == null);
      final queensideClear = [
        ChessSquare(file: 1, row: homeRow),
        ChessSquare(file: 2, row: homeRow),
        ChessSquare(file: 3, row: homeRow),
      ].every((target) => pieceAt(target) == null);

      final kingsideSafe = kingsideClear &&
          !isSquareAttacked(
            ChessSquare(file: 5, row: homeRow),
            piece.color.opponent,
          ) &&
          !isSquareAttacked(
            ChessSquare(file: 6, row: homeRow),
            piece.color.opponent,
          );
      final queensideSafe = queensideClear &&
          !isSquareAttacked(
            ChessSquare(file: 3, row: homeRow),
            piece.color.opponent,
          ) &&
          !isSquareAttacked(
            ChessSquare(file: 2, row: homeRow),
            piece.color.opponent,
          );

      if (kingsideSafe) {
        final rook = pieceAt(ChessSquare(file: 7, row: homeRow));
        if (rook != null &&
            rook.color == piece.color &&
            rook.type == ChessPieceType.rook &&
            !rook.hasMoved) {
          moves.add(
            ChessMove(
              from: square,
              to: ChessSquare(file: 6, row: homeRow),
            ),
          );
        }
      }

      if (queensideSafe) {
        final rook = pieceAt(ChessSquare(file: 0, row: homeRow));
        if (rook != null &&
            rook.color == piece.color &&
            rook.type == ChessPieceType.rook &&
            !rook.hasMoved) {
          moves.add(
            ChessMove(
              from: square,
              to: ChessSquare(file: 2, row: homeRow),
            ),
          );
        }
      }
    }

    return moves;
  }

  ChessMove? _resolveRequestedMove(
    ChessMove requested,
    List<ChessMove> legalMoves,
  ) {
    for (final legalMove in legalMoves) {
      if (legalMove.from != requested.from || legalMove.to != requested.to) {
        continue;
      }
      if (requested.promotion == null ||
          requested.promotion == legalMove.promotion ||
          legalMove.promotion == null) {
        return legalMove;
      }
    }
    return null;
  }

  bool _isPromotionRank(ChessSquare square, ChessColor color) {
    return (color == ChessColor.white && square.row == 0) ||
        (color == ChessColor.black && square.row == 7);
  }

  bool _isInside({
    int? file,
    int? row,
  }) {
    final resolvedFile = file;
    final resolvedRow = row;
    return resolvedFile != null &&
        resolvedRow != null &&
        resolvedFile >= 0 &&
        resolvedFile < columns &&
        resolvedRow >= 0 &&
        resolvedRow < rows;
  }

  bool _isInsideSquare(ChessSquare square) =>
      _isInside(file: square.file, row: square.row);
}

List<List<ChessPiece?>> _startingBoard() {
  return <List<ChessPiece?>>[
    <ChessPiece?>[
      ChessPiece(color: ChessColor.black, type: ChessPieceType.rook),
      ChessPiece(color: ChessColor.black, type: ChessPieceType.knight),
      ChessPiece(color: ChessColor.black, type: ChessPieceType.bishop),
      ChessPiece(color: ChessColor.black, type: ChessPieceType.queen),
      ChessPiece(color: ChessColor.black, type: ChessPieceType.king),
      ChessPiece(color: ChessColor.black, type: ChessPieceType.bishop),
      ChessPiece(color: ChessColor.black, type: ChessPieceType.knight),
      ChessPiece(color: ChessColor.black, type: ChessPieceType.rook),
    ],
    List<ChessPiece?>.filled(
      8,
      const ChessPiece(color: ChessColor.black, type: ChessPieceType.pawn),
    ),
    List<ChessPiece?>.filled(8, null),
    List<ChessPiece?>.filled(8, null),
    List<ChessPiece?>.filled(8, null),
    List<ChessPiece?>.filled(8, null),
    List<ChessPiece?>.filled(
      8,
      const ChessPiece(color: ChessColor.white, type: ChessPieceType.pawn),
    ),
    <ChessPiece?>[
      ChessPiece(color: ChessColor.white, type: ChessPieceType.rook),
      ChessPiece(color: ChessColor.white, type: ChessPieceType.knight),
      ChessPiece(color: ChessColor.white, type: ChessPieceType.bishop),
      ChessPiece(color: ChessColor.white, type: ChessPieceType.queen),
      ChessPiece(color: ChessColor.white, type: ChessPieceType.king),
      ChessPiece(color: ChessColor.white, type: ChessPieceType.bishop),
      ChessPiece(color: ChessColor.white, type: ChessPieceType.knight),
      ChessPiece(color: ChessColor.white, type: ChessPieceType.rook),
    ],
  ];
}

List<List<ChessPiece?>> _parseBoard(List<dynamic> boardJson) {
  if (boardJson.length != MatchSession.rows) {
    throw const FormatException('Expected an 8x8 board.');
  }

  final rows = <List<ChessPiece?>>[];
  for (final rawRow in boardJson) {
    if (rawRow is! List || rawRow.length != MatchSession.columns) {
      throw const FormatException('Expected an 8x8 board.');
    }
    final row = <ChessPiece?>[];
    for (final rawCell in rawRow) {
      if (rawCell == null) {
        row.add(null);
      } else if (rawCell is Map<String, dynamic>) {
        row.add(ChessPiece.fromJson(rawCell));
      } else {
        throw const FormatException('Unexpected board cell format.');
      }
    }
    rows.add(row);
  }
  return rows;
}

List<List<ChessPiece?>> _freezeBoard(List<List<ChessPiece?>> board) {
  return List<List<ChessPiece?>>.unmodifiable(
    board.map((row) => List<ChessPiece?>.unmodifiable(row)),
  );
}

List<List<ChessPiece?>> _cloneBoard(List<List<ChessPiece?>> board) {
  return board.map((row) => List<ChessPiece?>.of(row)).toList(growable: false);
}
