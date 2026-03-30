import 'match_models.dart';
import 'match_time.dart';

const List<String> matchAnalyticsHeaders = <String>[
  'Move #',
  'Player',
  'Piece',
  'From',
  'To',
  'Capture',
  'Promotion',
  'Flags',
  'Clock',
  'Move ms',
  'Move time',
  'Recorded at UTC',
];

Map<String, Object?> analyticsRowForMove(
  ChessMoveRecord record, {
  required int moveNumber,
}) {
  return <String, Object?>{
    'Move #': moveNumber,
    'Player': record.color.label,
    'Piece': record.piece.label,
    'From': record.from.notation,
    'To': record.to.notation,
    'Capture': record.captured?.label,
    'Promotion': record.promotion?.label,
    'Flags': _analyticsFlags(record),
    'Clock': record.timerPreset?.label ?? MatchTimerPreset.infinity.label,
    'Move ms': record.elapsedMilliseconds,
    'Move time': formatClock(
      record.elapsedMilliseconds == null
          ? null
          : Duration(milliseconds: record.elapsedMilliseconds!),
    ),
    'Recorded at UTC': record.recordedAtUtc?.toIso8601String(),
  };
}

String analyticsCsvFromMoves(List<ChessMoveRecord> moves) {
  final buffer = StringBuffer();
  buffer.writeln(
    matchAnalyticsHeaders.map(_csvCell).join(','),
  );

  for (var index = 0; index < moves.length; index += 1) {
    final row = analyticsRowForMove(moves[index], moveNumber: index + 1);
    buffer.writeln(
      matchAnalyticsHeaders.map((header) => _csvCell(row[header])).join(','),
    );
  }

  return buffer.toString();
}

String _analyticsFlags(ChessMoveRecord record) {
  final flags = <String>[];
  if (record.isCastling) {
    flags.add('Castle');
  }
  if (record.isEnPassant) {
    flags.add('En passant');
  }
  return flags.join('; ');
}

String _csvCell(Object? value) {
  final raw = value?.toString() ?? '';
  final requiresQuotes =
      raw.contains(',') || raw.contains('"') || raw.contains('\n');
  final escaped = raw.replaceAll('"', '""');
  return requiresQuotes ? '"$escaped"' : escaped;
}
