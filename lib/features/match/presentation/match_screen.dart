import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/tokens/design_tokens.g.dart';
import '../match_analytics.dart';
import '../chess_set_themes.dart';
import '../match_controller.dart';
import '../match_models.dart';
import '../match_time.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  late final TextEditingController _analyticsController;

  @override
  void initState() {
    super.initState();
    _hostController = TextEditingController();
    _portController = TextEditingController(text: '5050');
    _analyticsController = TextEditingController();
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _analyticsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MatchController>(
      builder: (context, controller, _) {
        final size = MediaQuery.sizeOf(context);
        final wide = size.width >= 980;
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
                    final boardSlotHeight = wide
                        ? constraints.maxHeight * 0.80
                        : constraints.maxHeight * 0.60;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: boardSlotHeight,
                          child: _BoardCard(
                            controller: controller,
                            maxBoardExtent: boardSlotHeight,
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.grid2,
                              AppSpacing.grid2,
                              AppSpacing.grid2,
                              AppSpacing.grid4,
                            ),
                            children: [
                              _BoardMetaBar(controller: controller),
                              const SizedBox(height: AppSpacing.grid2),
                              if (controller.notice != null) ...[
                                _NoticeBanner(message: controller.notice!),
                                const SizedBox(height: AppSpacing.grid2),
                              ],
                              if (wide)
                                _ControlColumn(
                                  controller: controller,
                                  hostController: _hostController,
                                  portController: _portController,
                                  analyticsController: _analyticsController,
                                )
                              else
                                _ControlsDrawer(
                                  controller: controller,
                                  hostController: _hostController,
                                  portController: _portController,
                                  analyticsController: _analyticsController,
                                ),
                            ],
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
  const _NoticeBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.grid4,
        vertical: AppSpacing.grid4,
      ),
      decoration: BoxDecoration(
        color: AppColors.textPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadii.medium),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.10),
        ),
      ),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
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
    final boardExtent = maxBoardExtent;
    final isBoardLocked = controller.boardInteractionLocked;

    return SizedBox(
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final widthDrivenExtent = math.min(constraints.maxWidth, boardExtent);

          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: widthDrivenExtent,
              height: widthDrivenExtent,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onDoubleTap: controller.busy
                    ? null
                    : controller.toggleBoardInteractionLock,
                child: Stack(
                  children: [
                    IgnorePointer(
                      ignoring: isBoardLocked,
                      child: _BoardGrid(controller: controller, theme: theme),
                    ),
                    Positioned.fill(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: isBoardLocked ? 1 : 0,
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.textPrimary.withValues(
                                alpha: 0.04,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppRadii.large - 2,
                              ),
                            ),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.grid4,
                                  vertical: AppSpacing.grid2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surface.withValues(
                                    alpha: 0.92,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: AppColors.textPrimary.withValues(
                                      alpha: 0.10,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Double tap to unlock board',
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(color: AppColors.textPrimary),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BoardMetaBar extends StatelessWidget {
  const _BoardMetaBar({required this.controller});

  final MatchController controller;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.grid2,
      runSpacing: AppSpacing.grid2,
      children: [
        _MetaPill(text: controller.turnSummary),
        _MetaPill(text: controller.boardOrientationSummary),
        _MetaPill(text: controller.connectionSummary),
      ],
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.grid2,
        vertical: AppSpacing.grid1,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.08),
        ),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BoardGrid extends StatelessWidget {
  const _BoardGrid({required this.controller, required this.theme});

  final MatchController controller;
  final ChessSetTheme theme;

  @override
  Widget build(BuildContext context) {
    final session = controller.session;
    final board = theme.board;
    final selectedSquare = controller.selectedSquare;
    final legalTargets = controller.legalTargets.toSet();
    final lastMove = session.moves.isNotEmpty ? session.moves.last : null;
    final checkedSquare = session.checkedKingSquare;
    final whiteAtBottom = controller.whiteAtBottom;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.large - 2),
        border: Border.all(color: board.border.withValues(alpha: 0.40)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: board.frame,
          stops: const [0.0, 0.56, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: board.glow.withValues(alpha: 0.20),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.large - 2),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 10,
                        child: Column(
                          children: List.generate(MatchSession.rows, (
                            displayRow,
                          ) {
                            final boardRow = whiteAtBottom
                                ? displayRow
                                : 7 - displayRow;
                            return Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '${MatchSession.rows - boardRow}',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(color: AppColors.textMuted),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Column(
                          children: List.generate(MatchSession.rows, (
                            displayRow,
                          ) {
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
                                  final piece =
                                      session.board[boardRow][boardFile];
                                  final isLightSquare =
                                      (boardFile + boardRow) % 2 == 0;
                                  final isSelected = selectedSquare == square;
                                  final isTarget = legalTargets.contains(
                                    square,
                                  );
                                  final isLastMove =
                                      lastMove != null &&
                                      (lastMove.from == square ||
                                          lastMove.to == square);
                                  final isChecked = checkedSquare == square;
                                  final canTap =
                                      controller.canLocalMove &&
                                      !session.isComplete;

                                  return Expanded(
                                    child: _BoardSquare(
                                      square: square,
                                      piece: piece,
                                      theme: theme,
                                      isLightSquare: isLightSquare,
                                      isSelected: isSelected,
                                      isTarget: isTarget,
                                      isLastMove: isLastMove,
                                      isChecked: isChecked,
                                      canTap: canTap,
                                      onTap: canTap
                                          ? () {
                                              controller.tapSquare(
                                                boardFile,
                                                boardRow,
                                              );
                                            }
                                          : null,
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
                const SizedBox(height: AppSpacing.grid1),
                SizedBox(
                  height: 24,
                  child: Row(
                    children: List.generate(MatchSession.columns, (
                      displayFile,
                    ) {
                      final boardFile = whiteAtBottom
                          ? displayFile
                          : 7 - displayFile;
                      return Expanded(
                        child: Center(
                          child: Text(
                            String.fromCharCode(97 + boardFile),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: AppColors.textMuted),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
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
        ),
      ),
    );
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
        : isSelected
        ? theme.accent.withValues(alpha: 0.68)
        : board.border.withValues(alpha: 0.16);

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
            border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
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
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: theme.accent.withValues(alpha: 0.72),
                            shape: BoxShape.circle,
                          ),
                        )
                      : Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.accent.withValues(alpha: 0.58),
                              width: 2,
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
        final size = constraints.biggest.shortestSide * 0.72;
        final shadowColor = selected
            ? theme.accent.withValues(alpha: 0.30)
            : material.shadow.withValues(alpha: 0.58);

        return AnimatedScale(
          duration: const Duration(milliseconds: 140),
          scale: selected ? 1.06 : 1.0,
          curve: Curves.easeOutBack,
          child: SizedBox(
            width: size,
            height: size,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: material.surface,
                ),
                border: Border.all(
                  color: selected
                      ? theme.accent.withValues(alpha: 0.58)
                      : material.border,
                  width: selected ? 1.6 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: selected ? 20 : 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipOval(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _SurfacePatternPainter(
                          pattern: material.pattern,
                          color: material.patternColor,
                        ),
                      ),
                    ),
                    Positioned(
                      top: size * 0.08,
                      child: Container(
                        width: size * 0.40,
                        height: size * 0.16,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: material.highlight,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: size * 0.10,
                      child: Container(
                        width: size * 0.58,
                        height: size * 0.14,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: material.border.withValues(alpha: 0.20),
                        ),
                      ),
                    ),
                    Text(
                      piece.symbol,
                      style: TextStyle(
                        fontSize: size * 0.48,
                        height: 1,
                        color: material.symbolColor,
                        fontWeight: FontWeight.w800,
                        fontFamilyFallback: const <String>[
                          'Segoe UI Symbol',
                          'Noto Sans Symbols 2',
                          'Apple Symbols',
                        ],
                        shadows: [
                          Shadow(
                            color: material.shadow.withValues(alpha: 0.66),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ControlColumn extends StatelessWidget {
  const _ControlColumn({
    required this.controller,
    required this.hostController,
    required this.portController,
    required this.analyticsController,
  });

  final MatchController controller;
  final TextEditingController hostController;
  final TextEditingController portController;
  final TextEditingController analyticsController;

  @override
  Widget build(BuildContext context) {
    final theme = controller.activeTheme;
    final isWeb = kIsWeb;
    final localModeHint = controller.isLocal
        ? 'This is the best GitHub Pages mode: one device, two players, no setup.'
        : isWeb
        ? 'Invite another tab or continue as a browser room.'
        : 'Host a local network match or return to hot-seat play.';

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
            'Game controls',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: AppSpacing.grid1),
          Text(localModeHint, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.grid4),
          _QuickStartStrip(
            title: 'Best way to play here',
            items: const [
              'Tap New local game',
              'Move with highlighted squares',
              'Pass the phone when prompted',
            ],
          ),
          const SizedBox(height: AppSpacing.grid4),
          Text('Timer settings', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.grid1),
          Text(
            'Pick the move clock you want for hot-seat play. Infinity only tracks move times.',
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
          _ActionButtonRow(
            title: 'New local game',
            description: 'Reset the board for one-device hot-seat play.',
            onPressed: controller.busy ? null : controller.startLocalMatch,
          ),
          const SizedBox(height: AppSpacing.grid2),
          _ActionButtonRow(
            title: 'Host this device',
            description: isWeb
                ? 'Starts a browser room for a second tab as the white side.'
                : 'Starts the local server as the white side.',
            onPressed: controller.busy ? null : controller.hostMatch,
          ),
          const SizedBox(height: AppSpacing.grid2),
          _ActionButtonRow(
            title: 'Join host',
            description: isWeb
                ? 'Connect to the invite link or room code in another tab as black.'
                : 'Connect to the host address as black.',
            onPressed: controller.busy
                ? null
                : () async {
                    try {
                      if (isWeb) {
                        await controller.joinHost(
                          address: hostController.text,
                          port: 0,
                        );
                      } else {
                        final port = int.parse(portController.text.trim());
                        await controller.joinHost(
                          address: hostController.text,
                          port: port,
                        );
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Connected.')),
                        );
                      }
                    } on FormatException {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Port must be a number.'),
                          ),
                        );
                      }
                    }
                  },
          ),
          const SizedBox(height: AppSpacing.grid4),
          Text(
            isWeb ? 'Invite link or room code' : 'Host address',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.grid1),
          TextField(
            controller: hostController,
            textInputAction: isWeb
                ? TextInputAction.done
                : TextInputAction.next,
            decoration: InputDecoration(
              hintText: isWeb ? 'https://.../?room=ABC123' : '192.168.1.10',
            ),
          ),
          if (!isWeb) ...[
            const SizedBox(height: AppSpacing.grid2),
            Text('Port', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppSpacing.grid1),
            TextField(
              controller: portController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: '5050'),
            ),
          ],
          const SizedBox(height: AppSpacing.grid4),
          _CareerProgressPanel(controller: controller, theme: theme),
          const SizedBox(height: AppSpacing.grid4),
          _AnalyticsPanel(
            controller: controller,
            analyticsController: analyticsController,
          ),
          const SizedBox(height: AppSpacing.grid4),
          Text('Set collection', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.grid1),
          Text(
            'Chrome starts open. Play to unlock crystal, gold, carbon fiber, and the stranger sets.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.grid2),
          LayoutBuilder(
            builder: (context, constraints) {
              final tileWidth = constraints.maxWidth >= 440
                  ? (constraints.maxWidth - AppSpacing.grid2) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: AppSpacing.grid2,
                runSpacing: AppSpacing.grid2,
                children: controller.availableThemes
                    .map(
                      (availableTheme) => SizedBox(
                        width: tileWidth,
                        child: _ThemeTile(
                          theme: availableTheme,
                          selected:
                              availableTheme.id == controller.activeTheme.id,
                          unlocked: controller.isThemeUnlocked(availableTheme),
                          onTap: controller.busy
                              ? null
                              : () => controller.selectTheme(availableTheme.id),
                        ),
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
          const SizedBox(height: AppSpacing.grid4),
          _HostDetails(controller: controller),
          const SizedBox(height: AppSpacing.grid4),
          Text('Move history', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.grid2),
          if (controller.historyLines.isEmpty)
            Text('No moves yet.', style: Theme.of(context).textTheme.bodyMedium)
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: controller.historyLines
                  .map(
                    (line) => Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.grid1,
                      ),
                      child: Text(
                        line,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }
}

class _QuickStartStrip extends StatelessWidget {
  const _QuickStartStrip({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.grid4),
      decoration: BoxDecoration(
        color: AppColors.textPrimary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppRadii.medium),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.grid2),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.grid1),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '•',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.grid2),
                  Expanded(
                    child: Text(
                      item,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlsDrawer extends StatelessWidget {
  const _ControlsDrawer({
    required this.controller,
    required this.hostController,
    required this.portController,
    required this.analyticsController,
  });

  final MatchController controller;
  final TextEditingController hostController;
  final TextEditingController portController;
  final TextEditingController analyticsController;

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
          children: [
            _ControlColumn(
              controller: controller,
              hostController: hostController,
              portController: portController,
              analyticsController: analyticsController,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButtonRow extends StatelessWidget {
  const _ActionButtonRow({
    required this.title,
    required this.description,
    required this.onPressed,
  });

  final String title;
  final String description;
  final Future<void> Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.grid4),
      decoration: BoxDecoration(
        color: AppColors.textPrimary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppRadii.medium),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.grid1),
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.grid2),
          ElevatedButton(
            onPressed: onPressed == null ? null : () => onPressed!.call(),
            child: Text(title),
          ),
        ],
      ),
    );
  }
}

class _CareerProgressPanel extends StatelessWidget {
  const _CareerProgressPanel({required this.controller, required this.theme});

  final MatchController controller;
  final ChessSetTheme theme;

  @override
  Widget build(BuildContext context) {
    final progress = controller.xpIntoLevel / 8.0;
    final board = theme.board;

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
        boxShadow: [
          BoxShadow(
            color: theme.accent.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
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
                  'Career level',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              Text(
                theme.name,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: theme.accent),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.grid1),
          Text(
            controller.levelSummary,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.grid1),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: board.darkSquare.first.withValues(alpha: 0.24),
              valueColor: AlwaysStoppedAnimation<Color>(theme.accent),
            ),
          ),
          const SizedBox(height: AppSpacing.grid1),
          Text(
            '${controller.unlockSummary} | ${controller.xpToNextLevel} XP to level ${controller.playerLevel + 1}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.grid1),
          Text(
            controller.nextUnlockSummary,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: theme.accent),
          ),
        ],
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
          if (controller.session.isComplete)
            Text(
              controller.session.note,
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else if (controller.awaitingHandOff && controller.isLocal)
            Text(
              'Pass the device to start ${controller.session.activeColor.label}\'s clock.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else if (hasFiniteClock)
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
                  ? 'Move timing is recorded for analytics. Press Pass to start the next clock.'
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

class _AnalyticsPanel extends StatelessWidget {
  const _AnalyticsPanel({
    required this.controller,
    required this.analyticsController,
  });

  final MatchController controller;
  final TextEditingController analyticsController;

  @override
  Widget build(BuildContext context) {
    final rows = controller.analyticsRows.reversed
        .take(8)
        .toList(growable: false);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.grid4),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(AppRadii.medium),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Analytics',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              Text(
                rows.isEmpty
                    ? '0 rows'
                    : '${controller.analyticsRows.length} rows',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: controller.activeTheme.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.grid1),
          Text(
            'Common columns: ${matchAnalyticsHeaders.join(' | ')}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.grid2),
          TextField(
            controller: analyticsController,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Google Sheets link or live endpoint',
              hintText: 'Paste a sheet URL or Apps Script web app URL',
            ),
            onSubmitted: (value) {
              unawaited(controller.setAnalyticsSinkUrl(value));
            },
          ),
          const SizedBox(height: AppSpacing.grid1),
          Text(
            'Plain sheet links are saved as references. For live writes, use a Google Apps Script web app URL attached to that sheet.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.grid2),
          Wrap(
            spacing: AppSpacing.grid2,
            runSpacing: AppSpacing.grid2,
            children: [
              ElevatedButton(
                onPressed: controller.busy
                    ? null
                    : () async {
                        await controller.setAnalyticsSinkUrl(
                          analyticsController.text,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Analytics link saved.'),
                            ),
                          );
                        }
                      },
                child: const Text('Save link'),
              ),
              TextButton(
                onPressed: controller.analyticsCsv.isEmpty
                    ? null
                    : () async {
                        await Clipboard.setData(
                          ClipboardData(text: controller.analyticsCsv),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Analytics CSV copied.'),
                            ),
                          );
                        }
                      },
                child: const Text('Copy CSV'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.grid2),
          Text(
            controller.analyticsSheetLabel,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.grid2),
          if (rows.isEmpty)
            Text(
              'No analytics rows yet. Make a move to start logging move times.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                columnWidths: <int, TableColumnWidth>{
                  for (
                    var index = 0;
                    index < matchAnalyticsHeaders.length;
                    index += 1
                  )
                    index: const IntrinsicColumnWidth(),
                },
                children: [
                  TableRow(
                    children: matchAnalyticsHeaders
                        .map(
                          (header) => Padding(
                            padding: const EdgeInsets.only(
                              right: AppSpacing.grid2,
                              bottom: AppSpacing.grid1,
                            ),
                            child: Text(
                              header,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: controller.activeTheme.accent,
                                  ),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                  ...rows.map(
                    (row) => TableRow(
                      children: matchAnalyticsHeaders
                          .map(
                            (header) => Padding(
                              padding: const EdgeInsets.only(
                                right: AppSpacing.grid2,
                                bottom: AppSpacing.grid1,
                              ),
                              child: Text(
                                _analyticsCellText(row[header]),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

String _analyticsCellText(Object? value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) {
    return '-';
  }
  return text;
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.theme,
    required this.selected,
    required this.unlocked,
    required this.onTap,
  });

  final ChessSetTheme theme;
  final bool selected;
  final bool unlocked;
  final Future<void> Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final board = theme.board;
    final canTap = onTap != null && unlocked;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: canTap ? () => onTap!.call() : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(AppSpacing.grid4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.medium),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              board.frame.first.withValues(alpha: 0.94),
              board.surface.first.withValues(alpha: 0.94),
              board.surface.last.withValues(alpha: 0.90),
            ],
            stops: const [0.0, 0.56, 1.0],
          ),
          border: Border.all(
            color: selected
                ? theme.accent.withValues(alpha: 0.88)
                : board.border.withValues(alpha: 0.32),
            width: selected ? 1.8 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? theme.accent.withValues(alpha: 0.18)
                  : AppColors.textPrimary.withValues(alpha: 0.06),
              blurRadius: selected ? 18 : 10,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Opacity(
              opacity: unlocked ? 1.0 : 0.72,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          theme.name,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.grid1),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.grid2,
                          vertical: AppSpacing.grid1,
                        ),
                        decoration: BoxDecoration(
                          color: theme.accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          unlocked
                              ? (selected ? 'Selected' : 'Ready')
                              : 'Level ${theme.unlockLevel}',
                          style: Theme.of(
                            context,
                          ).textTheme.labelSmall?.copyWith(color: theme.accent),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.grid2),
                  Row(
                    children: [
                      _MiniMaterialSwatch(material: theme.whitePieces),
                      const SizedBox(width: AppSpacing.grid2),
                      _MiniMaterialSwatch(material: theme.blackPieces),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.grid2),
                  Text(
                    theme.tagline,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.medium - 1),
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _SurfacePatternPainter(
                      pattern: board.pattern,
                      color: board.patternColor,
                    ),
                  ),
                ),
              ),
            ),
            if (!unlocked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.42),
                    borderRadius: BorderRadius.circular(AppRadii.medium - 1),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 16,
                          color: theme.accent.withValues(alpha: 0.78),
                        ),
                        const SizedBox(width: AppSpacing.grid1),
                        Text(
                          'Locked',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: theme.accent),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MiniMaterialSwatch extends StatelessWidget {
  const _MiniMaterialSwatch({required this.material});

  final ChessSurfaceMaterial material;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 18,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: material.surface,
          ),
          border: Border.all(color: material.border.withValues(alpha: 0.60)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: CustomPaint(
            painter: _SurfacePatternPainter(
              pattern: material.pattern,
              color: material.patternColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _HostDetails extends StatelessWidget {
  const _HostDetails({required this.controller});

  final MatchController controller;

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
    final shareText = controller.hostShareText;
    final hostText =
        shareText ??
        (isWeb
            ? 'Host this device to generate a shareable browser invite.'
            : 'Host this device to generate a shareable address.');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.grid4),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadii.medium),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isWeb ? 'Share this invite link' : 'Share this address',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: AppColors.accent),
          ),
          const SizedBox(height: AppSpacing.grid1),
          Text(
            hostText,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.grid2),
          OutlinedButton(
            onPressed: shareText != null
                ? () async {
                    final shareValue = controller.hostShareText;
                    if (shareValue == null) {
                      return;
                    }
                    await Clipboard.setData(ClipboardData(text: shareValue));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isWeb ? 'Invite link copied.' : 'Address copied.',
                          ),
                        ),
                      );
                    }
                  }
                : null,
            child: Text(isWeb ? 'Copy invite link' : 'Copy address'),
          ),
        ],
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
