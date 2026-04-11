import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/tokens/design_tokens.g.dart';
import '../chess_set_themes.dart';
import '../match_models.dart';

class MatchViewerScreen extends StatefulWidget {
  const MatchViewerScreen({super.key});

  @override
  State<MatchViewerScreen> createState() => _MatchViewerScreenState();
}

class _MatchViewerScreenState extends State<MatchViewerScreen> {
  MatchReplayDocument? _document;
  int _index = 0;
  bool _playing = false;
  double _speed = 1.0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  MatchSession? get _currentSession => _document?.snapshots.isNotEmpty == true
      ? _document!.snapshots[_index.clamp(0, _document!.snapshots.length - 1)]
      : null;

  void _setDocument(MatchReplayDocument doc) {
    setState(() {
      _document = doc;
      _index = 0;
      _playing = false;
      _timer?.cancel();
      _timer = null;
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['txt', 'json'],
      withData: true,
    );
    final bytes = result?.files.single.bytes;
    if (bytes == null) {
      return;
    }
    final text = utf8.decode(bytes);
    try {
      _setDocument(MatchReplayDocument.parse(text));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('That file could not be read.')),
        );
      }
    }
  }

  void _step(int delta) {
    final doc = _document;
    if (doc == null) {
      return;
    }
    setState(() {
      _index = (_index + delta).clamp(0, doc.snapshots.length - 1);
      if (_index == doc.snapshots.length - 1) {
        _playing = false;
        _timer?.cancel();
      }
    });
  }

  void _togglePlay() {
    final doc = _document;
    if (doc == null) {
      return;
    }
    if (_playing) {
      _timer?.cancel();
      setState(() => _playing = false);
      return;
    }
    setState(() => _playing = true);
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: (900 / _speed).round()), (
      _,
    ) {
      if (!mounted || _document == null) {
        return;
      }
      if (_index >= _document!.snapshots.length - 1) {
        _timer?.cancel();
        setState(() => _playing = false);
        return;
      }
      _step(1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = _currentSession;
    final hasDocument = _document != null;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Chess match viewer'),
        centerTitle: false,
        actions: [
          TextButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.upload_file),
            label: const Text('Open replay'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.grid4),
        child: session == null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accent.withValues(alpha: 0.24),
                            AppColors.textPrimary.withValues(alpha: 0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(
                        Icons.slideshow,
                        size: 36,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.grid4),
                    Text(
                      'Open a replay file to watch the match.',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.grid2),
                    Text(
                      'Use the exported replay .txt file to step through the game or autoplay it at a chosen speed.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.grid4),
                    ElevatedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Open replay'),
                    ),
                  ],
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final boardSize = math.min(
                    constraints.maxWidth,
                    constraints.maxHeight * 0.72,
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: SizedBox(
                          width: boardSize,
                          height: boardSize,
                          child: _ReplayBoard(session: session),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.grid4),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.grid4),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(AppRadii.large),
                          border: Border.all(
                            color: AppColors.textPrimary.withValues(
                              alpha: 0.08,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.textPrimary.withValues(
                                alpha: 0.05,
                              ),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Move ${_index + 1} / ${_document!.snapshots.length}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelLarge,
                                  ),
                                ),
                                _StatusPill(
                                  label: _playing ? 'Playing' : 'Paused',
                                  accent: _playing
                                      ? AppColors.accent
                                      : AppColors.textMuted,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.grid1),
                            Text(
                              session.note,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: AppSpacing.grid2),
                            Wrap(
                              spacing: AppSpacing.grid2,
                              runSpacing: AppSpacing.grid2,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _index == 0
                                      ? null
                                      : () => _step(-1),
                                  icon: const Icon(Icons.skip_previous),
                                  label: const Text('Back'),
                                ),
                                FilledButton.icon(
                                  onPressed: _togglePlay,
                                  icon: Icon(
                                    _playing
                                        ? Icons.pause_circle
                                        : Icons.play_circle,
                                  ),
                                  label: Text(_playing ? 'Pause' : 'Play'),
                                ),
                                OutlinedButton.icon(
                                  onPressed:
                                      _index >= _document!.snapshots.length - 1
                                      ? null
                                      : () => _step(1),
                                  icon: const Icon(Icons.skip_next),
                                  label: const Text('Next'),
                                ),
                                const SizedBox(width: AppSpacing.grid2),
                                SizedBox(
                                  width: math.min(280, constraints.maxWidth),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        'Speed ${_speed.toStringAsFixed(1)}x',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.labelLarge,
                                      ),
                                      Slider(
                                        value: _speed,
                                        min: 0.5,
                                        max: 4,
                                        divisions: 7,
                                        onChanged: (value) {
                                          setState(() {
                                            _speed = value;
                                            if (_playing) {
                                              _togglePlay();
                                              _togglePlay();
                                            }
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.grid1),
                            Text(
                              hasDocument
                                  ? 'Imported replay file loaded.'
                                  : 'Open a replay file to begin.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.grid2,
        vertical: AppSpacing.grid1,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: accent),
      ),
    );
  }
}

class MatchReplayDocument {
  const MatchReplayDocument({required this.snapshots});

  final List<MatchSession> snapshots;

  factory MatchReplayDocument.parse(String text) {
    final trimmed = text.trim();
    if (trimmed.startsWith('Checkmate replay')) {
      return MatchReplayDocument.fromMoveList(trimmed);
    }

    final decoded = jsonDecode(trimmed);
    if (decoded is Map<String, dynamic>) {
      return MatchReplayDocument.fromJson(decoded);
    }
    throw const FormatException('Unsupported replay file.');
  }

  factory MatchReplayDocument.fromMoveList(String text) {
    final lines = text
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    if (lines.length < 2) {
      throw const FormatException('Replay file is missing move lines.');
    }

    var session = MatchSession.initial();
    final snapshots = <MatchSession>[session];
    for (final line in lines.skip(2)) {
      final match = RegExp(
        r'^(\d+)\.\s+([^\s]+)(?:\s+([^\s]+))?$',
      ).firstMatch(line);
      if (match == null) {
        throw FormatException('Could not parse move line: $line');
      }
      final whiteMove = _replayTokenToMove(session, match.group(2)!);
      session = session.playMove(whiteMove);
      snapshots.add(session);
      final blackMove = match.group(3);
      if (blackMove != null && blackMove.isNotEmpty) {
        final parsedBlack = _replayTokenToMove(session, blackMove);
        session = session.playMove(parsedBlack);
        snapshots.add(session);
      }
    }
    return MatchReplayDocument(snapshots: snapshots);
  }

  factory MatchReplayDocument.fromJson(Map<String, dynamic> json) {
    final rawSnapshots = json['snapshots'];
    final snapshots = rawSnapshots is List
        ? rawSnapshots
              .whereType<Map<String, dynamic>>()
              .map(MatchSession.fromJson)
              .toList(growable: false)
        : <MatchSession>[];
    if (snapshots.isEmpty) {
      throw const FormatException('No snapshots found.');
    }
    return MatchReplayDocument(snapshots: snapshots);
  }
}

ChessMove _replayTokenToMove(MatchSession session, String token) {
  final cleaned = token.replaceAll('0', 'O');
  final promotionMatch = RegExp(r'^(.*?)(?:=([QRBN]))?$').firstMatch(cleaned);
  if (promotionMatch == null) {
    throw FormatException('Unsupported move token: $token');
  }

  final body = promotionMatch.group(1)!;
  final promotion = switch (promotionMatch.group(2)) {
    'Q' => ChessPieceType.queen,
    'R' => ChessPieceType.rook,
    'B' => ChessPieceType.bishop,
    'N' => ChessPieceType.knight,
    _ => null,
  };

  final parts = body.split('-');
  if (parts.length != 2) {
    throw FormatException('Unsupported move token: $token');
  }

  if (body == 'O-O' || body == 'O-O-O') {
    final kingSquare = session.activeColor == ChessColor.white
        ? const ChessSquare(file: 4, row: 7)
        : const ChessSquare(file: 4, row: 0);
    final target = body == 'O-O'
        ? (session.activeColor == ChessColor.white
              ? const ChessSquare(file: 6, row: 7)
              : const ChessSquare(file: 6, row: 0))
        : (session.activeColor == ChessColor.white
              ? const ChessSquare(file: 2, row: 7)
              : const ChessSquare(file: 2, row: 0));
    return ChessMove(from: kingSquare, to: target);
  }

  final from = _squareFromNotation(parts[0]);
  final to = _squareFromNotation(parts[1]);
  final matchingMoves = session
      .legalMovesFrom(from)
      .where((move) => move.to == to && move.promotion == promotion)
      .toList(growable: false);
  if (matchingMoves.isEmpty) {
    throw FormatException('Could not resolve move token: $token');
  }
  return matchingMoves.first;
}

ChessSquare _squareFromNotation(String notation) {
  if (notation.length != 2) {
    throw FormatException('Invalid square notation: $notation');
  }
  final file = notation.codeUnitAt(0) - 97;
  final rank = 8 - int.parse(notation.substring(1));
  return ChessSquare(file: file, row: rank);
}

class _ReplayBoard extends StatelessWidget {
  const _ReplayBoard({required this.session});

  final MatchSession session;

  @override
  Widget build(BuildContext context) {
    final board = ChessSetCatalog.chrome.board;
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.large),
            border: Border.all(color: board.border.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 64,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
            ),
            itemBuilder: (context, index) {
              final row = index ~/ 8;
              final file = index % 8;
              final square = ChessSquare(file: file, row: row);
              final piece = session.pieceAt(square);
              final light = (row + file).isEven;
              return Container(
                decoration: BoxDecoration(
                  color: light
                      ? board.lightSquare.first
                      : board.darkSquare.first,
                  border: Border(
                    right: BorderSide(
                      color: board.border.withValues(alpha: 0.10),
                    ),
                    bottom: BorderSide(
                      color: board.border.withValues(alpha: 0.10),
                    ),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  piece?.symbol ?? '',
                  style: TextStyle(
                    fontSize: 30,
                    color: piece?.color == ChessColor.white
                        ? Colors.white
                        : Colors.black,
                    shadows: const [
                      Shadow(
                        blurRadius: 1,
                        offset: Offset(0, 1),
                        color: Colors.black26,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
