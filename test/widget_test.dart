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

  testWidgets('renders the chess board with starting pieces', (tester) async {
    final controller = MatchController();
    unawaited(controller.bootstrap());
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const ui.Size(1600, 1800));

    await tester.pumpWidget(CheckmateApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Checkmate by Caris'), findsOneWidget);
    expect(
      find.text(
        'White view: files a-h run left to right and ranks 1-8 run bottom to top.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Single-device note: progress saves on this device. Use Host/Join for Wi-Fi or hotspot play.',
      ),
      findsOneWidget,
    );
    expect(find.text('White to move'), findsWidgets);
    expect(find.text('a'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('♔'), findsOneWidget);
    expect(find.text('♚'), findsOneWidget);
    expect(find.text('♙'), findsAtLeastNWidgets(8));
    expect(find.text('♟'), findsAtLeastNWidgets(8));
    expect(find.text('Reset board'), findsOneWidget);
  });
}
