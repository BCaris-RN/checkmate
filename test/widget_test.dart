import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:checkmate_by_caris/features/match/match_controller.dart';
import 'package:checkmate_by_caris/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('renders the board and core local controls', (tester) async {
    final controller = MatchController();
    unawaited(controller.bootstrap());
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const ui.Size(1600, 1800));

    await tester.pumpWidget(CheckmateApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.byType(DecoratedBox), findsWidgets);
    expect(find.text('Pass reminder'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
    expect(find.byType(Semantics), findsWidgets);
  });
}
