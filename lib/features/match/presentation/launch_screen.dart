import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/tokens/design_tokens.g.dart';

class AppLaunchGate extends StatefulWidget {
  const AppLaunchGate({
    super.key,
    required this.child,
    this.splashDuration = const Duration(milliseconds: 1400),
  });

  final Widget child;
  final Duration splashDuration;

  @override
  State<AppLaunchGate> createState() => _AppLaunchGateState();
}

class _AppLaunchGateState extends State<AppLaunchGate> {
  bool _showSplash = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.splashDuration, () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _showSplash
          ? const LaunchSplashPage(key: ValueKey<String>('launch_splash'))
          : KeyedSubtree(
              key: const ValueKey<String>('launch_app'),
              child: widget.child,
            ),
    );
  }
}

class BrandStamp extends StatelessWidget {
  const BrandStamp({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final logoSize = compact ? 34.0 : 94.0;
    final titleStyle = compact
        ? Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            )
        : Theme.of(context).textTheme.displaySmall?.copyWith(
              color: AppColors.textPrimary,
            );
    final quoteStyle = compact
        ? Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
            )
        : Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textMuted,
            );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 10 : 24),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.08),
                blurRadius: compact ? 12 : 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(compact ? 10 : 24),
            child: Image.asset(
              'assets/Icon-512.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        SizedBox(width: compact ? AppSpacing.grid2 : AppSpacing.grid4),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!compact)
              Text(
                'Checkmate by Caris',
                style: titleStyle,
              ),
            Text(
              '"created by Caris | Phoenix : Suprama_C"',
              style: quoteStyle,
            ),
          ],
        ),
      ],
    );
  }
}

class LaunchSplashPage extends StatelessWidget {
  const LaunchSplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surface,
              AppColors.surface.withValues(alpha: 0.96),
              AppColors.accent.withValues(alpha: 0.06),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: -120,
              top: -120,
              child: _Glow(
                color: AppColors.accent.withValues(alpha: 0.18),
                size: 320,
              ),
            ),
            Positioned(
              right: -90,
              bottom: -120,
              child: _Glow(
                color: AppColors.textPrimary.withValues(alpha: 0.08),
                size: 280,
              ),
            ),
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.92, end: 1),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (context, scale, child) {
                  return Opacity(
                    opacity: (scale - 0.92) / 0.08,
                    child: Transform.scale(
                      scale: scale,
                      child: child,
                    ),
                  );
                },
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.grid4,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const BrandStamp(),
                        const SizedBox(height: AppSpacing.grid4),
                        Text(
                          'Loading the board.',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                        ),
                        const SizedBox(height: AppSpacing.grid1),
                        Text(
                          'Chess, governance, and themed sets.',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                        ),
                      ],
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

class _Glow extends StatelessWidget {
  const _Glow({
    required this.color,
    required this.size,
  });

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
