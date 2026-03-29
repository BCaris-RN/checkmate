import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/match/match_controller.dart';
import 'features/match/presentation/match_screen.dart';
import 'features/match/presentation/launch_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = MatchController();
  unawaited(controller.bootstrap());
  runApp(CheckmateApp(controller: controller, showLaunchScreen: true));
}

class CheckmateApp extends StatelessWidget {
  const CheckmateApp({
    super.key,
    required this.controller,
    this.showLaunchScreen = false,
  });

  final MatchController controller;
  final bool showLaunchScreen;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MatchController>.value(
      value: controller,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Checkmate by Caris',
        theme: AppTheme.light(),
        home: showLaunchScreen
            ? const AppLaunchGate(child: MatchScreen())
            : const MatchScreen(),
      ),
    );
  }
}
