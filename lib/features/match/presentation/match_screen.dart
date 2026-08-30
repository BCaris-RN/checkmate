import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/tokens/design_tokens.g.dart';
import '../chess_set_themes.dart';
import '../match_controller.dart';
import '../match_replay_file.dart';
import '../match_models.dart';
import '../match_time.dart';
import 'match_viewer_screen.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  late final TextEditingController _analyticsController;

  @override
  void initState() {
    super.initState();
    _analyticsController = TextEditingController();
  }

  @override
  void dispose() {
    _analyticsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MatchController>(
      builder: (context, controller, _) {
        final analyticsValue = controller.analyticsSinkUrl ?? '';
        if (_analyticsController.text != analyticsValue) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }
            if (_analyticsController.text != analyticsValue) {
              _analyticsController.text = analyticsValue;
            }
          });
        }

        return Scaffold(
          body: Stack(
            children: [
              const _AmbientBackdrop(),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final boardExtent = math.min(
                      constraints.maxWidth,
                      constraints.maxHeight * 0.90,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: boardExtent,
                          child: _BoardCard(
                            controller: controller,
                            maxBoardExtent: boardExtent,
                          ),
                        ),
                        Expanded(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.surface.withValues(alpha: 0.96),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(AppRadii.large),
                              ),
                              border: Border.all(
                                color: AppColors.textPrimary.withValues(
                                  alpha: 0.08,
                                ),
                              ),
                            ),
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.grid4,
                                AppSpacing.grid4,
                                AppSpacing.grid4,
                                AppSpacing.grid8,
                              ),
                              children: [
                                if (controller.notice != null) ...[
                                  _NoticeBanner(
                                    controller: controller,
                                    message: controller.notice!,
                                  ),
                                  const SizedBox(height: AppSpacing.grid2),
                                ],
                                _PassReminderTile(controller: controller),
                                const SizedBox(height: AppSpacing.grid2),
                                _ControlsDrawer(controller: controller),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NoticeBanner extends StatelessWidget {
  const _NoticeBanner({required this.controller, required this.message});

  final MatchController controller;
  final String message;

  @override
  Widget build(BuildContext context) {
    final tappable = controller.canPassDevice && controller.isLocal;

    return Material(
      color: AppColors.textPrimary.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(AppRadii.medium),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.medium),
        onTap: tappable && !controller.busy
            ? () => unawaited(controller.passDevice())
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.grid4,
            vertical: AppSpacing.grid4,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.medium),
            border: Border.all(
              color: tappable
                  ? controller.activeTheme.accent.withValues(alpha: 0.34)
                  : AppColors.textPrimary.withValues(alpha: 0.10),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (tappable) ...[
                const SizedBox(width: AppSpacing.grid2),
                Icon(
                  Icons.swap_horiz,
                  size: 18,
                  color: controller.activeTheme.accent,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BoardCard extends StatelessWidget {
  const _BoardCard({required this.controller, required this.maxBoardExtent});

  final MatchController controller;
  final double maxBoardExtent;

  @override
  Widget build(BuildContext context) {
    final theme = controller.activeTheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return SizedBox(
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final widthDrivenExtent = math.min(
            constraints.maxWidth,
            maxBoardExtent,
          );

          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: widthDrivenExtent,
              height: widthDrivenExtent,
              child: _BoardFlipShell(
                whiteAtBottom: controller.whiteAtBottom,
                reduceMotion: reduceMotion,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadii.large - 2),
                    border: Border.all(
                      color: AppColors.textPrimary.withValues(alpha: 0.08),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.board.glow.withValues(alpha: 0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: _BoardGrid(controller: controller, theme: theme),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PassReminderTile extends StatelessWidget {
  const _PassReminderTile({required this.controller});

  final MatchController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.grid4,
        vertical: AppSpacing.grid2,
      ),
      decoration: BoxDecoration(
        color: AppColors.textPrimary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppRadii.medium),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pass reminder',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: AppSpacing.grid1),
                Text(
                  controller.passReminderEnabled
                      ? 'On when you want a pass prompt after local moves.'
                      : 'Off when you want uninterrupted play.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Switch(
            value: controller.passReminderEnabled,
            onChanged: controller.busy
                ? null
                : (value) =>
                      unawaited(controller.setPassReminderEnabled(value)),
          ),
        ],
      ),
    );
  }
}

class _BoardFlipShell extends StatefulWidget {
  const _BoardFlipShell({
    required this.whiteAtBottom,
    required this.reduceMotion,
    required this.child,
  });

  final bool whiteAtBottom;
  final bool reduceMotion;
  final Widget child;

  @override
  State<_BoardFlipShell> createState() => _BoardFlipShellState();
}

class _BoardFlipShellState extends State<_BoardFlipShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late bool _whiteAtBottom;

  @override
  void initState() {
    super.initState();
    _whiteAtBottom = widget.whiteAtBottom;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
  }

  @override
  void didUpdateWidget(covariant _BoardFlipShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.whiteAtBottom != _whiteAtBottom) {
      _whiteAtBottom = widget.whiteAtBottom;
      if (widget.reduceMotion) {
        _controller.value = 0;
      } else {
        HapticFeedback.lightImpact();
        _controller.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final curved = Curves.easeInOutCubic.transform(_controller.value);
        final lift = math.sin(curved * math.pi).abs();
        return Transform.scale(
          scale: 1 - (lift * 0.06),
          child: Transform.rotate(angle: curved * math.pi, child: child),
        );
      },
    );
  }
}

class _BoardGrid extends StatefulWidget {
  const _BoardGrid({required this.controller, required this.theme});

  final MatchController controller;
  final ChessSetTheme theme;

  @override
  State<_BoardGrid> createState() => _BoardGridState();
}

class _BoardGridState extends State<_BoardGrid> with TickerProviderStateMixin {
  late MatchSession _previousSession;
  late final AnimationController _moveController;
  late final AnimationController _illegalController;
  late final AnimationController _checkController;
  _MoveAnimation? _moveAnimation;
  ChessSquare? _illegalSquare;

  static const double _rankLabelWidth = 6;
  static const double _fileLabelHeight = 24;
  static const double _fileLabelGap = AppSpacing.grid1;

  @override
  void initState() {
    super.initState();
    _previousSession = widget.controller.session;
    _moveController = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() {
            _moveAnimation = null;
          });
        }
      });
    _illegalController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 280),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted) {
            setState(() {
              _illegalSquare = null;
            });
          }
        });
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void didUpdateWidget(covariant _BoardGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    final session = widget.controller.session;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    if (!reduceMotion && session.moves.length > _previousSession.moves.length) {
      final record = session.moves.last;
      final movingPiece = _previousSession.pieceAt(record.from);
      if (movingPiece != null) {
        final capturedSquare = record.isEnPassant
            ? ChessSquare(file: record.to.file, row: record.from.row)
            : record.to;
        final distance = math.max(
          (record.from.file - record.to.file).abs(),
          (record.from.row - record.to.row).abs(),
        );
        _moveAnimation = _MoveAnimation(
          record: record,
          piece: movingPiece,
          capturedPiece: _previousSession.pieceAt(capturedSquare),
          capturedSquare: capturedSquare,
        );
        _moveController.duration = Duration(
          milliseconds: math.min(260, 180 + distance * 12) + 110,
        );
        _moveController.forward(from: 0);
      }
    }

    if (session.checkedKingSquare != null && !reduceMotion) {
      if (!_checkController.isAnimating) {
        _checkController.repeat(reverse: true, count: 4);
      }
    } else if (session.checkedKingSquare == null) {
      _checkController.stop();
      _checkController.value = 0;
    }

    _previousSession = session;
  }

  @override
  void dispose() {
    _moveController.dispose();
    _illegalController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.controller.session;
    final theme = widget.theme;
    final board = theme.board;
    final selectedSquare = widget.controller.selectedSquare;
    final legalTargets = widget.controller.legalTargets.toSet();
    final lastMove = session.moves.isNotEmpty ? session.moves.last : null;
    final checkedSquare = session.checkedKingSquare;
    final whiteAtBottom = widget.controller.whiteAtBottom;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.large - 2),
        border: Border.all(color: board.border.withValues(alpha: 0.14)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            board.lightSquare.first,
            board.lightSquare.last,
            board.darkSquare.first,
          ],
          stops: const [0.0, 0.56, 1.0],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.large - 2),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final boardSize = Size(
              math.max(0, constraints.maxWidth - _rankLabelWidth),
              math.max(
                0,
                constraints.maxHeight - _fileLabelHeight - _fileLabelGap,
              ),
            );
            final squareSize = boardSize.shortestSide / MatchSession.columns;

            return Stack(
              fit: StackFit.expand,
              children: [
                RepaintBoundary(
                  child: _BoardContent(
                    session: session,
                    theme: theme,
                    selectedSquare: selectedSquare,
                    legalTargets: legalTargets,
                    lastMove: lastMove,
                    checkedSquare: checkedSquare,
                    whiteAtBottom: whiteAtBottom,
                    moving: reduceMotion ? null : _moveAnimation,
                    illegalSquare: _illegalSquare,
                    illegalAnimation: _illegalController,
                    checkAnimation: _checkController,
                    canTap:
                        widget.controller.canLocalMove && !session.isComplete,
                    onTap: (square) => unawaited(
                      _handleBoardTap(context, widget.controller, square),
                    ),
                  ),
                ),
                if (_moveAnimation != null && !reduceMotion)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _moveController,
                        builder: (context, _) => _MoveOverlay(
                          animation: _moveAnimation!,
                          controller: _moveController,
                          theme: theme,
                          boardSize: boardSize,
                          squareSize: squareSize,
                          whiteAtBottom: whiteAtBottom,
                          rankLabelWidth: _rankLabelWidth,
                        ),
                      ),
                    ),
                  ),
                IgnorePointer(
                  child: CustomPaint(
                    painter: _SurfacePatternPainter(
                      pattern: board.pattern,
                      color: board.patternColor,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleBoardTap(
    BuildContext context,
    MatchController controller,
    ChessSquare square,
  ) async {
    final promotionMoves = controller.promotionMovesForSelectedTarget(square);
    if (promotionMoves.isEmpty) {
      final selected = controller.selectedSquare;
      final reduceMotion = MediaQuery.disableAnimationsOf(context);
      final isIllegalTarget =
          selected != null &&
          selected != square &&
          !controller.legalTargets.contains(square);
      await controller.tapSquare(square.file, square.row);
      if (isIllegalTarget && mounted) {
        setState(() {
          _illegalSquare = selected;
        });
        if (!reduceMotion) {
          _illegalController.forward(from: 0);
        }
      }
      return;
    }

    final selectedMove = await showModalBottomSheet<ChessMove>(
      context: context,
      showDragHandle: true,
      builder: (context) => _PromotionPicker(moves: promotionMoves),
    );
    if (selectedMove == null) {
      return;
    }
    await controller.playMove(selectedMove);
  }
}

class _BoardContent extends StatelessWidget {
  const _BoardContent({
    required this.session,
    required this.theme,
    required this.selectedSquare,
    required this.legalTargets,
    required this.lastMove,
    required this.checkedSquare,
    required this.whiteAtBottom,
    required this.moving,
    required this.illegalSquare,
    required this.illegalAnimation,
    required this.checkAnimation,
    required this.canTap,
    required this.onTap,
  });

  final MatchSession session;
  final ChessSetTheme theme;
  final ChessSquare? selectedSquare;
  final Set<ChessSquare> legalTargets;
  final ChessMoveRecord? lastMove;
  final ChessSquare? checkedSquare;
  final bool whiteAtBottom;
  final _MoveAnimation? moving;
  final ChessSquare? illegalSquare;
  final Animation<double> illegalAnimation;
  final Animation<double> checkAnimation;
  final bool canTap;
  final ValueChanged<ChessSquare> onTap;

  @override
  Widget build(BuildContext context) {
    final board = theme.board;

    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: _BoardGridState._rankLabelWidth,
                child: Column(
                  children: List.generate(MatchSession.rows, (displayRow) {
                    final boardRow = whiteAtBottom
                        ? displayRow
                        : 7 - displayRow;
                    return Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${MatchSession.rows - boardRow}',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: board.border,
                                fontSize: AppTypography.labelMD,
                              ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Expanded(
                child: Column(
                  children: List.generate(MatchSession.rows, (displayRow) {
                    final boardRow = whiteAtBottom
                        ? displayRow
                        : 7 - displayRow;
                    return Expanded(
                      child: Row(
                        children: List.generate(MatchSession.columns, (
                          displayFile,
                        ) {
                          final boardFile = whiteAtBottom
                              ? displayFile
                              : 7 - displayFile;
                          final square = ChessSquare(
                            file: boardFile,
                            row: boardRow,
                          );
                          var piece = session.board[boardRow][boardFile];
                          if (moving != null &&
                              (moving!.record.from == square ||
                                  moving!.record.to == square ||
                                  moving!.capturedSquare == square)) {
                            piece = null;
                          }
                          final isLightSquare = (boardFile + boardRow) % 2 == 0;
                          final isSelected = selectedSquare == square;
                          final isTarget = legalTargets.contains(square);
                          final isLastMove =
                              lastMove != null &&
                              (lastMove!.from == square ||
                                  lastMove!.to == square);
                          final isChecked = checkedSquare == square;
                          final shouldShake = illegalSquare == square;

                          return Expanded(
                            child: AnimatedBuilder(
                              animation: Listenable.merge([
                                illegalAnimation,
                                checkAnimation,
                              ]),
                              builder: (context, child) {
                                final shake = shouldShake
                                    ? math.sin(
                                            illegalAnimation.value *
                                                math.pi *
                                                6,
                                          ) *
                                          (1 - illegalAnimation.value) *
                                          6
                                    : 0.0;
                                final checkPulse = isChecked
                                    ? checkAnimation.value
                                    : 0.0;
                                return Transform.translate(
                                  offset: Offset(shake, 0),
                                  child: _BoardSquare(
                                    square: square,
                                    piece: piece,
                                    theme: theme,
                                    isLightSquare: isLightSquare,
                                    isSelected: isSelected,
                                    isTarget: isTarget,
                                    isLastMove: isLastMove,
                                    isChecked: isChecked,
                                    checkPulse: checkPulse,
                                    illegalPulse: shouldShake
                                        ? 1 - illegalAnimation.value
                                        : 0,
                                    canTap: canTap,
                                    onTap: canTap ? () => onTap(square) : null,
                                  ),
                                );
                              },
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: _BoardGridState._fileLabelGap),
        SizedBox(
          height: _BoardGridState._fileLabelHeight,
          child: Padding(
            padding: const EdgeInsets.only(
              left: _BoardGridState._rankLabelWidth,
            ),
            child: Row(
              children: List.generate(MatchSession.columns, (displayFile) {
                final boardFile = whiteAtBottom ? displayFile : 7 - displayFile;
                return Expanded(
                  child: Center(
                    child: Text(
                      String.fromCharCode(97 + boardFile),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: board.border,
                        fontSize: AppTypography.labelMD,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

class _MoveAnimation {
  const _MoveAnimation({
    required this.record,
    required this.piece,
    required this.capturedPiece,
    required this.capturedSquare,
  });

  final ChessMoveRecord record;
  final ChessPiece piece;
  final ChessPiece? capturedPiece;
  final ChessSquare capturedSquare;
}

class _MoveOverlay extends StatelessWidget {
  const _MoveOverlay({
    required this.animation,
    required this.controller,
    required this.theme,
    required this.boardSize,
    required this.squareSize,
    required this.whiteAtBottom,
    required this.rankLabelWidth,
  });

  final _MoveAnimation animation;
  final AnimationController controller;
  final ChessSetTheme theme;
  final Size boardSize;
  final double squareSize;
  final bool whiteAtBottom;
  final double rankLabelWidth;

  @override
  Widget build(BuildContext context) {
    final moveProgress = Curves.easeInOutCubic.transform(
      (controller.value / 0.72).clamp(0.0, 1.0),
    );
    final settleProgress = Curves.easeOutBack.transform(
      ((controller.value - 0.72) / 0.28).clamp(0.0, 1.0),
    );
    final from = _squareOffset(animation.record.from);
    final to = _squareOffset(animation.record.to);
    final current = Offset.lerp(from, to, moveProgress)!;
    final scale = 1.08 - (0.08 * settleProgress);

    return Stack(
      children: [
        if (animation.capturedPiece != null)
          Positioned(
            left: _squareOffset(animation.capturedSquare).dx,
            top: _squareOffset(animation.capturedSquare).dy,
            width: squareSize,
            height: squareSize,
            child: Opacity(
              opacity: 1 - ((controller.value - 0.58) / 0.34).clamp(0.0, 1.0),
              child: Transform.scale(
                scale:
                    1 -
                    (((controller.value - 0.58) / 0.34).clamp(0.0, 1.0) * 0.3),
                child: _PieceBadge(
                  piece: animation.capturedPiece!,
                  theme: theme,
                  selected: false,
                ),
              ),
            ),
          ),
        Positioned(
          left: current.dx,
          top: current.dy,
          width: squareSize,
          height: squareSize,
          child: Transform.scale(
            scale: scale,
            child: _PieceBadge(
              piece: animation.piece,
              theme: theme,
              selected: true,
            ),
          ),
        ),
      ],
    );
  }

  Offset _squareOffset(ChessSquare square) {
    final displayFile = whiteAtBottom ? square.file : 7 - square.file;
    final displayRow = whiteAtBottom ? square.row : 7 - square.row;
    return Offset(
      rankLabelWidth + displayFile * squareSize,
      displayRow * squareSize,
    );
  }
}

class _PromotionPicker extends StatelessWidget {
  const _PromotionPicker({required this.moves});

  final List<ChessMove> moves;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.grid4,
          0,
          AppSpacing.grid4,
          AppSpacing.grid4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Promote pawn', style: theme.textTheme.displayMedium),
            const SizedBox(height: AppSpacing.grid2),
            Wrap(
              spacing: AppSpacing.grid2,
              runSpacing: AppSpacing.grid2,
              children: [
                for (final move in moves)
                  FilledButton.tonalIcon(
                    onPressed: () => Navigator.of(context).pop(move),
                    icon: Text(
                      move.promotion!.symbolFor(
                        context.read<MatchController>().session.activeColor,
                      ),
                      style: const TextStyle(
                        fontSize: AppTypography.bodyMD,
                        height: 1,
                      ),
                    ),
                    label: Text(_promotionLabel(move.promotion!)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _promotionLabel(ChessPieceType type) {
    return type == ChessPieceType.rook ? 'Castle (rook)' : type.label;
  }
}

class _BoardSquare extends StatelessWidget {
  const _BoardSquare({
    required this.square,
    required this.piece,
    required this.theme,
    required this.isLightSquare,
    required this.isSelected,
    required this.isTarget,
    required this.isLastMove,
    required this.isChecked,
    required this.checkPulse,
    required this.illegalPulse,
    required this.canTap,
    required this.onTap,
  });

  final ChessSquare square;
  final ChessPiece? piece;
  final ChessSetTheme theme;
  final bool isLightSquare;
  final bool isSelected;
  final bool isTarget;
  final bool isLastMove;
  final bool isChecked;
  final double checkPulse;
  final double illegalPulse;
  final bool canTap;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final board = theme.board;
    final squareColor = isLightSquare
        ? board.lightSquare.first
        : board.darkSquare.first;
    final borderColor = isChecked
        ? theme.accent.withValues(alpha: 0.92)
        : illegalPulse > 0
        ? Colors.redAccent.withValues(alpha: 0.72)
        : isSelected
        ? theme.accent.withValues(alpha: 0.68)
        : board.border.withValues(alpha: 0.16);
    final borderWidth = isChecked
        ? 1.5 + checkPulse
        : isSelected
        ? 2.0
        : 1.0;

    return Semantics(
      button: canTap,
      label: piece == null
          ? square.notation
          : '${piece!.label} on ${square.notation}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                squareColor,
                (isLightSquare ? board.lightSquare.last : board.darkSquare.last)
                    .withValues(alpha: isLightSquare ? 0.92 : 0.95),
              ],
            ),
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: [
              if (isChecked)
                BoxShadow(
                  color: theme.accent.withValues(
                    alpha: 0.18 + checkPulse * 0.2,
                  ),
                  blurRadius: 8 + checkPulse * 8,
                ),
              if (illegalPulse > 0)
                BoxShadow(
                  color: Colors.redAccent.withValues(
                    alpha: illegalPulse * 0.24,
                  ),
                  blurRadius: 6,
                ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (isLastMove)
                Container(color: theme.accent.withValues(alpha: 0.08)),
              if (isTarget)
                Center(
                  child: piece == null
                      ? Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: theme.accent.withValues(alpha: 0.72),
                            shape: BoxShape.circle,
                          ),
                        )
                      : Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.accent.withValues(alpha: 0.58),
                              width: 1.25,
                            ),
                          ),
                        ),
                ),
              if (piece != null)
                Center(
                  child: _PieceBadge(
                    piece: piece!,
                    theme: theme,
                    selected: isSelected,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PieceBadge extends StatelessWidget {
  const _PieceBadge({
    required this.piece,
    required this.theme,
    required this.selected,
  });

  final ChessPiece piece;
  final ChessSetTheme theme;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final material = piece.color == ChessColor.white
        ? theme.whitePieces
        : theme.blackPieces;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest.shortestSide * 0.82;
        final shadowColor = selected
            ? theme.accent.withValues(alpha: 0.16)
            : material.shadow.withValues(alpha: 0.30);

        return AnimatedScale(
          duration: const Duration(milliseconds: 140),
          scale: selected ? 1.06 : 1.0,
          curve: Curves.easeOutBack,
          child: SizedBox(
            width: size,
            height: size,
            child: Image.asset(
              _pieceAssetPath(theme, piece),
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              errorBuilder: (context, error, stackTrace) => _GlyphPieceBadge(
                piece: piece,
                theme: theme,
                material: material,
                shadowColor: shadowColor,
                selected: selected,
                size: size,
              ),
            ),
          ),
        );
      },
    );
  }

  String _pieceAssetPath(ChessSetTheme theme, ChessPiece piece) {
    final color = piece.color == ChessColor.white ? 'light' : 'dark';
    return 'assets/pieces/${_pieceThemeSlug(theme)}/${color}_${piece.type.label}.png';
  }

  String _pieceThemeSlug(ChessSetTheme theme) {
    return switch (theme.id) {
      'chrome' => 'chrome_vanguard',
      'crystal' => 'crystal_vault',
      'gold' => 'gilded_court',
      'carbon' => 'carbon_night',
      'obsidian' => 'obsidian_relic',
      'aurora' => 'aurora_myth',
      _ => theme.id,
    };
  }
}

class _GlyphPieceBadge extends StatelessWidget {
  const _GlyphPieceBadge({
    required this.piece,
    required this.theme,
    required this.material,
    required this.shadowColor,
    required this.selected,
    required this.size,
  });

  final ChessPiece piece;
  final ChessSetTheme theme;
  final ChessSurfaceMaterial material;
  final Color shadowColor;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [material.surface.first, material.surface.last],
        ),
        border: Border.all(
          color: selected
              ? theme.accent.withValues(alpha: 0.58)
              : material.border.withValues(alpha: 0.78),
          width: selected ? 1.2 : 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: selected ? 4 : 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          piece.symbol,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: size * 0.66,
            height: 1,
            color: material.symbolColor,
            fontWeight: FontWeight.w500,
            fontFamilyFallback: const <String>[
              'Segoe UI Symbol',
              'Noto Sans Symbols 2',
              'Apple Symbols',
            ],
            shadows: [
              Shadow(
                color: material.shadow.withValues(alpha: 0.18),
                blurRadius: 0.25,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlColumn extends StatelessWidget {
  const _ControlColumn({required this.controller});

  final MatchController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.grid4),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(AppRadii.large),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Hot-seat controls',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: AppSpacing.grid1),
          Text('Timer settings', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.grid1),
          Text(
            'Pick the move clock you want for hot-seat play.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.grid2),
          Wrap(
            spacing: AppSpacing.grid2,
            runSpacing: AppSpacing.grid2,
            children:
                <MatchTimerPreset>[
                      MatchTimerPreset.fiveMinutes,
                      MatchTimerPreset.tenMinutes,
                      MatchTimerPreset.fifteenMinutes,
                      MatchTimerPreset.thirtyMinutes,
                      MatchTimerPreset.infinity,
                    ]
                    .map(
                      (preset) => ChoiceChip(
                        label: Text(preset.label),
                        selected: controller.clockPreset == preset,
                        onSelected: controller.busy
                            ? null
                            : (selected) {
                                if (selected) {
                                  unawaited(controller.setClockPreset(preset));
                                }
                              },
                      ),
                    )
                    .toList(growable: false),
          ),
          const SizedBox(height: AppSpacing.grid2),
          _TimerSummaryCard(controller: controller),
          const SizedBox(height: AppSpacing.grid4),
          if (controller.isLocal) ...[
            Wrap(
              spacing: AppSpacing.grid2,
              runSpacing: AppSpacing.grid2,
              children: [
                FilledButton.icon(
                  onPressed: controller.busy
                      ? null
                      : () => unawaited(controller.flipBoard()),
                  icon: const Icon(Icons.flip),
                  label: Text(
                    controller.whiteAtBottom
                        ? 'Flip to black at bottom'
                        : 'Flip to white at bottom',
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: controller.busy || !controller.canPassDevice
                      ? null
                      : () => unawaited(controller.passDevice()),
                  icon: const Icon(Icons.swap_horiz),
                  label: Text(controller.passButtonLabel),
                ),
                OutlinedButton.icon(
                  onPressed: controller.busy
                      ? null
                      : () => unawaited(controller.resetMatch()),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset board'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.grid2),
          ],
          Text(
            controller.isLocal
                ? 'After a move, pass the device so the next color gets the clock.'
                : 'Hot-seat passing is available in local play.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.grid4),
          _PassReminderTile(controller: controller),
          const SizedBox(height: AppSpacing.grid4),
          Text('Match actions', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.grid1),
          Text(
            'Use these to recover from a misread board or end the game cleanly.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.grid2),
          Wrap(
            spacing: AppSpacing.grid2,
            runSpacing: AppSpacing.grid2,
            children: [
              OutlinedButton.icon(
                onPressed: controller.busy
                    ? null
                    : () => unawaited(controller.resignAs(ChessColor.white)),
                icon: const Icon(Icons.flag_outlined),
                label: const Text('White resigns'),
              ),
              OutlinedButton.icon(
                onPressed: controller.busy
                    ? null
                    : () => unawaited(controller.resignAs(ChessColor.black)),
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Black resigns'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.grid4),
          Text('Move export', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.grid1),
          Text(
            'Copy the move text or open an email draft with the move list attached.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.grid2),
          Wrap(
            spacing: AppSpacing.grid2,
            runSpacing: AppSpacing.grid2,
            children: [
              OutlinedButton.icon(
                onPressed: controller.busy
                    ? null
                    : () async {
                        await Clipboard.setData(
                          ClipboardData(text: controller.moveLogText),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Move text copied.')),
                          );
                        }
                      },
                icon: const Icon(Icons.copy),
                label: const Text('Copy moves'),
              ),
              ElevatedButton.icon(
                onPressed: controller.busy
                    ? null
                    : () async {
                        final subject = Uri.encodeComponent(
                          'Checkmate move list',
                        );
                        final body = Uri.encodeComponent(
                          controller.moveLogText,
                        );
                        final uri = Uri.parse(
                          'mailto:?subject=$subject&body=$body',
                        );
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                icon: const Icon(Icons.email_outlined),
                label: const Text('Email moves'),
              ),
              OutlinedButton.icon(
                onPressed: controller.busy
                    ? null
                    : () async {
                        final fileName =
                            'checkmate_replay_${DateTime.now().toUtc().toIso8601String().replaceAll(':', '-').replaceAll('.', '-')}.txt';
                        final path = await saveMatchReplayText(
                          fileName: fileName,
                          contents: controller.replayExportText,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Saved replay file: $path')),
                          );
                        }
                      },
                icon: const Icon(Icons.save_alt),
                label: const Text('Export .txt'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const MatchViewerScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.slideshow),
                label: const Text('Match viewer'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ControlsDrawer extends StatelessWidget {
  const _ControlsDrawer({required this.controller});

  final MatchController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppRadii.large),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.08),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.large),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: false,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.grid4,
              vertical: AppSpacing.grid2,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(
              AppSpacing.grid4,
              0,
              AppSpacing.grid4,
              AppSpacing.grid4,
            ),
            title: Text(
              'Controls',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            subtitle: Text(
              'Collapsed by default so the board stays dominant.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            children: [_ControlColumn(controller: controller)],
          ),
        ),
      ),
    );
  }
}

class _TimerSummaryCard extends StatelessWidget {
  const _TimerSummaryCard({required this.controller});

  final MatchController controller;

  @override
  Widget build(BuildContext context) {
    final theme = controller.activeTheme;
    final board = theme.board;
    final whiteRemaining = controller.remainingFor(ChessColor.white);
    final blackRemaining = controller.remainingFor(ChessColor.black);
    final hasFiniteClock = controller.clockPreset.duration != null;
    final loneKingMovesRemaining = controller.loneKingMovesRemaining;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.grid4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            board.surface.first.withValues(alpha: 0.96),
            board.surface.last.withValues(alpha: 0.92),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadii.medium),
        border: Border.all(color: theme.accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Turn clock',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              Text(
                controller.timeControlSummary,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: theme.accent),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.grid1),
          Text(
            controller.turnClockSummary,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.grid1),
          if (loneKingMovesRemaining != null) ...[
            _TimePill(
              label: 'Lone king',
              value: '$loneKingMovesRemaining moves',
            ),
            const SizedBox(height: AppSpacing.grid2),
          ],
          if (controller.isLocal) ...[
            FilledButton.icon(
              onPressed: controller.busy
                  ? null
                  : () => unawaited(controller.flipBoard()),
              icon: const Icon(Icons.flip),
              label: Text(
                controller.whiteAtBottom
                    ? 'Flip to black at bottom'
                    : 'Flip to white at bottom',
              ),
            ),
            const SizedBox(height: AppSpacing.grid2),
          ],
          if (controller.session.isComplete)
            Text(
              controller.session.note,
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else if (controller.awaitingHandOff && controller.isLocal) ...[
            Text(
              'Pass to ${controller.session.activeColor.label} to start their clock.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ] else if (hasFiniteClock)
            Wrap(
              spacing: AppSpacing.grid2,
              runSpacing: AppSpacing.grid2,
              children: [
                _TimePill(label: 'White', value: formatClock(whiteRemaining)),
                _TimePill(label: 'Black', value: formatClock(blackRemaining)),
                _TimePill(
                  label: 'Turn',
                  value: formatClock(controller.currentTurnElapsed),
                ),
              ],
            )
          else
            Text(
              controller.awaitingHandOff
                  ? 'Press pass to hand the board to the next player.'
                  : 'Infinity keeps the clock off and only records move times.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
        ],
      ),
    );
  }
}

class _TimePill extends StatelessWidget {
  const _TimePill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.grid2,
        vertical: AppSpacing.grid2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.08),
        ),
      ),
      child: Text(
        '$label $value',
        style: Theme.of(context).textTheme.labelLarge,
      ),
    );
  }
}

class _AmbientBackdrop extends StatelessWidget {
  const _AmbientBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surface,
              AppColors.surface.withValues(alpha: 0.96),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: -80,
              top: -100,
              child: _Glow(
                color: AppColors.accent.withValues(alpha: 0.20),
                size: 320,
              ),
            ),
            Positioned(
              right: -120,
              top: 120,
              child: _Glow(
                color: AppColors.textPrimary.withValues(alpha: 0.07),
                size: 420,
              ),
            ),
            Positioned(
              left: 120,
              bottom: -100,
              child: _Glow(
                color: AppColors.textMuted.withValues(alpha: 0.12),
                size: 260,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _SurfacePatternPainter extends CustomPainter {
  const _SurfacePatternPainter({required this.pattern, required this.color});

  final ChessSurfacePattern pattern;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (pattern == ChessSurfacePattern.none || size.isEmpty) {
      return;
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 1;

    switch (pattern) {
      case ChessSurfacePattern.none:
        return;
      case ChessSurfacePattern.brushed:
        _paintBrushed(canvas, size, paint);
        return;
      case ChessSurfacePattern.weave:
        _paintWeave(canvas, size, paint);
        return;
      case ChessSurfacePattern.facets:
        _paintFacets(canvas, size, paint);
        return;
      case ChessSurfacePattern.etched:
        _paintEtched(canvas, size, paint);
        return;
      case ChessSurfacePattern.aurora:
        _paintAurora(canvas, size, paint);
        return;
    }
  }

  void _paintBrushed(Canvas canvas, Size size, Paint paint) {
    var stripe = 0;
    for (var y = 0.0; y <= size.height; y += 7.5) {
      paint.color = color.withValues(alpha: stripe.isEven ? 0.10 : 0.05);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      stripe += 1;
    }
  }

  void _paintWeave(Canvas canvas, Size size, Paint paint) {
    final step = 12.0;
    for (var offset = -size.height; offset <= size.width; offset += step) {
      paint.color = color.withValues(alpha: 0.07);
      canvas.drawLine(
        Offset(offset, 0),
        Offset(offset + size.height, size.height),
        paint,
      );
      paint.color = color.withValues(alpha: 0.04);
      canvas.drawLine(
        Offset(offset + step * 0.45, 0),
        Offset(offset + size.height + step * 0.45, size.height),
        paint,
      );
    }
    for (var offset = 0.0; offset <= size.width + size.height; offset += step) {
      paint.color = color.withValues(alpha: 0.04);
      canvas.drawLine(
        Offset(offset, 0),
        Offset(offset - size.height, size.height),
        paint,
      );
    }
  }

  void _paintFacets(Canvas canvas, Size size, Paint paint) {
    final step = 18.0;
    for (var x = -step; x <= size.width + step; x += step) {
      paint.color = color.withValues(alpha: 0.09);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
      paint.color = color.withValues(alpha: 0.05);
      canvas.drawLine(
        Offset(x + step * 0.5, 0),
        Offset(x + size.height + step * 0.5, size.height),
        paint,
      );
    }
    for (var y = 0.0; y <= size.height; y += step) {
      paint.color = color.withValues(alpha: 0.05);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _paintEtched(Canvas canvas, Size size, Paint paint) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.shortestSide / 2;
    final minimumRadius = math.max(4.0, maxRadius * 0.2);
    for (var radius = maxRadius; radius > minimumRadius; radius -= 12) {
      paint.color = color.withValues(alpha: 0.10);
      canvas.drawOval(Rect.fromCircle(center: center, radius: radius), paint);
    }
    paint.color = color.withValues(alpha: 0.05);
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), paint);
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      paint,
    );
  }

  void _paintAurora(Canvas canvas, Size size, Paint paint) {
    final width = size.width;
    final height = size.height;
    for (var band = 0; band < 4; band += 1) {
      final centerY = height * (0.18 + band * 0.21);
      final amplitude = height * (0.05 + band * 0.01);
      final phase = band * math.pi * 0.45;
      final path = Path()..moveTo(0, centerY);
      for (var x = 0.0; x <= width; x += math.max(8.0, width / 12)) {
        final t = x / math.max(1.0, width);
        final y =
            centerY +
            math.sin((t * math.pi * 2.0) + phase) * amplitude +
            math.cos((t * math.pi * 4.0) + phase) * (amplitude * 0.35);
        path.lineTo(x, y);
      }
      paint.color = color.withValues(alpha: 0.10 - band * 0.015);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SurfacePatternPainter oldDelegate) {
    return oldDelegate.pattern != pattern || oldDelegate.color != color;
  }
}
