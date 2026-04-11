import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/tokens/design_tokens.g.dart';
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
      _setDocument(
        MatchReplayDocument.fromJson(jsonDecode(text) as Map<String, dynamic>),
      );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chess match viewer'),
        actions: [
          TextButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.upload_file),
            label: const Text('Open file'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.grid4),
        child: session == null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Open a replay file to watch the match.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.grid2),
                    ElevatedButton(
                      onPressed: _pickFile,
                      child: const Text('Open replay'),
                    ),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _ReplayBoard(session: session)),
                  const SizedBox(height: AppSpacing.grid2),
                  Text(
                    'Move ${_index + 1} / ${_document!.snapshots.length}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: AppSpacing.grid1),
                  Text(
                    session.note,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.grid2),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _index == 0 ? null : () => _step(-1),
                        icon: const Icon(Icons.skip_previous),
                      ),
                      IconButton(
                        onPressed: _togglePlay,
                        icon: Icon(
                          _playing ? Icons.pause_circle : Icons.play_circle,
                        ),
                      ),
                      IconButton(
                        onPressed: _index >= _document!.snapshots.length - 1
                            ? null
                            : () => _step(1),
                        icon: const Icon(Icons.skip_next),
                      ),
                      const SizedBox(width: AppSpacing.grid2),
                      Text(
                        'Speed',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Expanded(
                        child: Slider(
                          value: _speed,
                          min: 0.5,
                          max: 4,
                          divisions: 7,
                          label: '${_speed.toStringAsFixed(1)}x',
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
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

class MatchReplayDocument {
  const MatchReplayDocument({required this.snapshots});

  final List<MatchSession> snapshots;

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

class _ReplayBoard extends StatelessWidget {
  const _ReplayBoard({required this.session});

  final MatchSession session;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(20),
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
                color: light
                    ? const Color(0xffeeeed2)
                    : const Color(0xff769656),
                alignment: Alignment.center,
                child: Text(
                  piece?.symbol ?? '',
                  style: TextStyle(
                    fontSize: 28,
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
