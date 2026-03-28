import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/tokens/design_tokens.g.dart';
import '../match_controller.dart';
import '../match_models.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  late final TextEditingController _hostController;
  late final TextEditingController _portController;

  @override
  void initState() {
    super.initState();
    _hostController = TextEditingController();
    _portController = TextEditingController(text: '5050');
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MatchController>(
      builder: (context, controller, _) {
        final wide = MediaQuery.sizeOf(context).width >= 980;

        return Scaffold(
          body: Stack(
            children: [
              const _AmbientBackdrop(),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.grid4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TopBar(controller: controller),
                      const SizedBox(height: AppSpacing.grid4),
                      if (controller.notice != null) ...[
                        _NoticeBanner(message: controller.notice!),
                        const SizedBox(height: AppSpacing.grid4),
                      ],
                      Expanded(
                        child: wide
                            ? SingleChildScrollView(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: _BoardCard(controller: controller),
                                    ),
                                    const SizedBox(width: AppSpacing.grid4),
                                    Expanded(
                                      flex: 2,
                                      child: _ControlColumn(
                                        controller: controller,
                                        hostController: _hostController,
                                        portController: _portController,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView(
                                children: [
                                  _BoardCard(controller: controller),
                                  const SizedBox(height: AppSpacing.grid4),
                                  _ControlColumn(
                                    controller: controller,
                                    hostController: _hostController,
                                    portController: _portController,
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.controller});

  final MatchController controller;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 760;

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Checkmate by Caris',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: AppSpacing.grid1),
        Text(
          'White view: files a-h run left to right and ranks 1-8 run bottom to top.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );

    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          titleBlock,
          const SizedBox(height: AppSpacing.grid2),
          _StatusPill(label: controller.connectionSummary),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: AppSpacing.grid4),
        _StatusPill(label: controller.connectionSummary),
      ],
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
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
            ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.grid4,
        vertical: AppSpacing.grid2,
      ),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.18)),
      ),
      child: Center(
        child: Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.accent,
              ),
        ),
      ),
    );
  }
}

class _BoardCard extends StatelessWidget {
  const _BoardCard({required this.controller});

  final MatchController controller;

  @override
  Widget build(BuildContext context) {
    final session = controller.session;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.grid4),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(AppRadii.large),
        border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.turnSummary,
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(height: AppSpacing.grid1),
                    Text(
                      'Standard chess layout. Tap a piece, then tap a highlighted square.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.grid1),
                    Text(
                      session.note,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.grid4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    controller.seatSummary,
                    style: Theme.of(context).textTheme.labelLarge,
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: AppSpacing.grid1),
                  Text(
                    controller.connectionSummary,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.grid4),
          AspectRatio(
            aspectRatio: 1,
            child: _BoardGrid(controller: controller),
          ),
          const SizedBox(height: AppSpacing.grid4),
          Row(
            children: [
              Expanded(
                child: Text(
                  session.note,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
              const SizedBox(width: AppSpacing.grid4),
              TextButton(
                onPressed: controller.busy ? null : controller.resetMatch,
                child: const Text('Reset board'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BoardGrid extends StatelessWidget {
  const _BoardGrid({required this.controller});

  final MatchController controller;

  @override
  Widget build(BuildContext context) {
    final session = controller.session;
    final selectedSquare = controller.selectedSquare;
    final legalTargets = controller.legalTargets.toSet();
    final lastMove = session.moves.isNotEmpty ? session.moves.last : null;
    final checkedSquare = session.checkedKingSquare;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.large - 2),
        border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.08)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface.withValues(alpha: 0.96),
            AppColors.textPrimary.withValues(alpha: 0.03),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.large - 2),
        child: Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 24,
                    child: Column(
                      children: List.generate(
                        MatchSession.rows,
                        (index) => Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${MatchSession.rows - index}',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.grid2),
                  Expanded(
                    child: Column(
                      children: List.generate(MatchSession.rows, (row) {
                        return Expanded(
                          child: Row(
                            children: List.generate(MatchSession.columns, (file) {
                              final square = ChessSquare(file: file, row: row);
                              final piece = session.board[row][file];
                              final isLightSquare = (file + row) % 2 == 0;
                              final isSelected = selectedSquare == square;
                              final isTarget = legalTargets.contains(square);
                              final isLastMove = lastMove != null &&
                                  (lastMove.from == square || lastMove.to == square);
                              final isChecked = checkedSquare == square;
                              final canTap =
                                  controller.canLocalMove && !session.isComplete;

                              return Expanded(
                                child: _BoardSquare(
                                  square: square,
                                  piece: piece,
                                  isLightSquare: isLightSquare,
                                  isSelected: isSelected,
                                  isTarget: isTarget,
                                  isLastMove: isLastMove,
                                  isChecked: isChecked,
                                  canTap: canTap,
                                  onTap: canTap
                                      ? () {
                                          controller.tapSquare(file, row);
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
            const SizedBox(height: AppSpacing.grid2),
            SizedBox(
              height: 24,
              child: Padding(
                padding: const EdgeInsets.only(left: 32),
                child: Row(
                  children: List.generate(
                    MatchSession.columns,
                    (file) => Expanded(
                      child: Center(
                        child: Text(
                          String.fromCharCode(97 + file),
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: AppColors.textMuted,
                              ),
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
    );
  }
}

class _BoardSquare extends StatelessWidget {
  const _BoardSquare({
    required this.square,
    required this.piece,
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
  final bool isLightSquare;
  final bool isSelected;
  final bool isTarget;
  final bool isLastMove;
  final bool isChecked;
  final bool canTap;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final squareColor = isLightSquare
        ? AppColors.surface.withValues(alpha: 0.95)
        : AppColors.textPrimary.withValues(alpha: 0.08);
    final borderColor = isChecked
        ? AppColors.accent.withValues(alpha: 0.88)
        : isSelected
            ? AppColors.accent.withValues(alpha: 0.64)
            : AppColors.textPrimary.withValues(alpha: 0.04);

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
                squareColor.withValues(alpha: isLightSquare ? 0.72 : 0.88),
              ],
            ),
            border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (isLastMove)
                Container(
                  color: AppColors.accent.withValues(alpha: 0.06),
                ),
              if (isTarget)
                Center(
                  child: piece == null
                      ? Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.65),
                            shape: BoxShape.circle,
                          ),
                        )
                      : Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.55),
                              width: 2,
                            ),
                          ),
                        ),
                ),
              if (piece != null)
                Center(
                  child: _PieceBadge(
                    piece: piece!,
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
    required this.selected,
  });

  final ChessPiece piece;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest.shortestSide * 0.72;
        final isWhite = piece.color == ChessColor.white;
        final glyphColor = isWhite ? AppColors.textPrimary : AppColors.surface;
        final glowColor = isWhite
            ? AppColors.textPrimary.withValues(alpha: 0.18)
            : AppColors.textPrimary.withValues(alpha: 0.36);

        return AnimatedScale(
          duration: const Duration(milliseconds: 140),
          scale: selected ? 1.06 : 1.0,
          curve: Curves.easeOutBack,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isWhite
                    ? [
                        AppColors.surface,
                        AppColors.surface.withValues(alpha: 0.82),
                        AppColors.textPrimary.withValues(alpha: 0.06),
                      ]
                    : [
                        AppColors.textPrimary.withValues(alpha: 0.96),
                        AppColors.textPrimary.withValues(alpha: 0.78),
                        AppColors.textPrimary.withValues(alpha: 0.58),
                      ],
              ),
              border: Border.all(
                color: isWhite
                    ? AppColors.textPrimary.withValues(alpha: 0.10)
                    : AppColors.surface.withValues(alpha: 0.14),
              ),
              boxShadow: [
                BoxShadow(
                  color: glowColor,
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: size * 0.08,
                  child: Container(
                    width: size * 0.36,
                    height: size * 0.14,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: isWhite
                          ? AppColors.surface.withValues(alpha: 0.44)
                          : AppColors.surface.withValues(alpha: 0.10),
                    ),
                  ),
                ),
                Text(
                  piece.symbol,
                  style: TextStyle(
                    fontSize: size * 0.48,
                    height: 1,
                    color: glyphColor,
                    fontWeight: FontWeight.w700,
                    fontFamilyFallback: const <String>[
                      'Segoe UI Symbol',
                      'Noto Sans Symbols 2',
                      'Apple Symbols',
                    ],
                    shadows: [
                      Shadow(
                        color: isWhite
                            ? AppColors.textPrimary.withValues(alpha: 0.10)
                            : AppColors.textPrimary.withValues(alpha: 0.45),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
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
  });

  final MatchController controller;
  final TextEditingController hostController;
  final TextEditingController portController;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.grid4),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(AppRadii.large),
        border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.10)),
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
          Text(
            'Local chess works immediately. Hosting makes this device white; joining makes it black.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.grid4),
          _ActionButtonRow(
            title: 'New local game',
            description: 'Reset the board and play on one screen.',
            onPressed: controller.busy ? null : controller.startLocalMatch,
          ),
          const SizedBox(height: AppSpacing.grid2),
          _ActionButtonRow(
            title: 'Host this device',
            description: 'Starts the local server as the white side.',
            onPressed: controller.busy ? null : controller.hostMatch,
          ),
          const SizedBox(height: AppSpacing.grid2),
          _ActionButtonRow(
            title: 'Join host',
            description: 'Connect to the host address as black.',
            onPressed: controller.busy
                ? null
                : () async {
                    try {
                      final port = int.parse(portController.text.trim());
                      await controller.joinHost(
                        address: hostController.text,
                        port: port,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Connected.')),
                        );
                      }
                    } on FormatException {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Port must be a number.')),
                        );
                      }
                    }
                  },
          ),
          const SizedBox(height: AppSpacing.grid4),
          Text(
            'Host address',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.grid1),
          TextField(
            controller: hostController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: '192.168.1.10',
            ),
          ),
          const SizedBox(height: AppSpacing.grid2),
          Text(
            'Port',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.grid1),
          TextField(
            controller: portController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: '5050',
            ),
          ),
          const SizedBox(height: AppSpacing.grid4),
          _HostDetails(controller: controller),
          const SizedBox(height: AppSpacing.grid4),
          Text(
            'Move history',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.grid2),
          if (controller.historyLines.isEmpty)
            Text(
              'No moves yet.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
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
        border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.08)),
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
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
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

class _HostDetails extends StatelessWidget {
  const _HostDetails({required this.controller});

  final MatchController controller;

  @override
  Widget build(BuildContext context) {
    final hostText = controller.isHosted &&
            controller.hostAddress != null &&
            controller.hostPort != null
        ? '${controller.hostAddress}:${controller.hostPort}'
        : 'Host this device to generate a shareable address.';

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
            'Share this address',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.accent,
                ),
          ),
          const SizedBox(height: AppSpacing.grid1),
          Text(
            hostText,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: AppSpacing.grid2),
          OutlinedButton(
            onPressed: controller.isHosted &&
                    controller.hostAddress != null &&
                    controller.hostPort != null
                ? () async {
                    await Clipboard.setData(
                      ClipboardData(text: '${controller.hostAddress}:${controller.hostPort}'),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Address copied.')),
                      );
                    }
                  }
                : null,
            child: const Text('Copy address'),
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
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
