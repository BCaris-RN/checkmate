import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:checkmate_by_caris/main.dart';
import 'package:checkmate_by_caris/features/match/match_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('renders the match shell', (tester) async {
    final controller = MatchController();
    unawaited(controller.bootstrap());
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const ui.Size(1600, 1800));

    await tester.pumpWidget(CheckmateApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Checkmate by Caris'), findsOneWidget);
    expect(find.text('Match controls'), findsOneWidget);
    expect(find.text('Join address'), findsOneWidget);
    expect(find.text('Share this address'), findsOneWidget);
  });
}
