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
          'Cross-device match room for phones and tablets.',
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
    final boardAspectRatio = MatchSession.columns / MatchSession.rows;

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
                      session.statusLabel,
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(height: AppSpacing.grid1),
                    Text(
                      'Tap a lane to drop a token. Blue always opens.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.grid4),
              _Legend(controller: controller),
            ],
          ),
          const SizedBox(height: AppSpacing.grid4),
          AspectRatio(
            aspectRatio: boardAspectRatio,
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
                child: const Text('Reset match'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.controller});

  final MatchController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _LegendRow(
          label: 'Blue',
          color: MatchToken.blue.color,
        ),
        const SizedBox(height: AppSpacing.grid1),
        _LegendRow(
          label: 'Ink',
          color: MatchToken.ink.color,
        ),
        const SizedBox(height: AppSpacing.grid2),
        Text(
          controller.seatSummary,
          style: Theme.of(context).textTheme.labelLarge,
          textAlign: TextAlign.right,
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.grid2),
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.textPrimary,
              ),
        ),
      ],
    );
  }
}

class _BoardGrid extends StatelessWidget {
  const _BoardGrid({required this.controller});

  final MatchController controller;

  @override
  Widget build(BuildContext context) {
    final session = controller.session;

    return Material(
      color: AppColors.textPrimary.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(AppRadii.large - 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.large - 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(MatchSession.columns, (column) {
            final canTap = controller.canLocalMove && !session.isComplete;
            return Expanded(
              child: InkWell(
                onTap: canTap ? () => controller.playColumn(column) : null,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: AppColors.surface.withValues(alpha: 0.55),
                        width: column == MatchSession.columns - 1 ? 0 : 1,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: List.generate(MatchSession.rows, (row) {
                      final token = session.board[row][column];
                      final isTop = row == 0;
                      return Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: AppColors.surface.withValues(alpha: 0.55),
                                width: isTop ? 0 : 1,
                              ),
                            ),
                          ),
                          child: Center(
                            child: _TokenCell(token: token),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _TokenCell extends StatelessWidget {
  const _TokenCell({required this.token});

  final MatchToken? token;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 160),
      scale: token == null ? 0.88 : 1.0,
      curve: Curves.easeOutBack,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: token == null
              ? AppColors.surface.withValues(alpha: 0.12)
              : token!.color,
          shape: BoxShape.circle,
          border: Border.all(
            color: token == null
                ? AppColors.textMuted.withValues(alpha: 0.22)
                : AppColors.surface.withValues(alpha: 0.42),
            width: 2,
          ),
          boxShadow: token == null
              ? []
              : [
                  BoxShadow(
                    color: token!.color.withValues(alpha: 0.30),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
      ),
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
            'Match controls',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: AppSpacing.grid1),
          Text(
            'Local play works immediately. Device-to-device play needs one host and one joiner on the same Wi-Fi.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.grid4),
          _ActionButtonRow(
            title: 'New local match',
            description: 'Reset the board and play on one screen.',
            onPressed: controller.busy ? null : controller.startLocalMatch,
          ),
          const SizedBox(height: AppSpacing.grid2),
          _ActionButtonRow(
            title: 'Host this device',
            description: 'Starts the local server and shares this board.',
            onPressed: controller.busy ? null : controller.hostMatch,
          ),
          const SizedBox(height: AppSpacing.grid2),
          _ActionButtonRow(
            title: 'Join host',
            description: 'Connect to the host address and sync the board.',
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
            'Join address',
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
