import 'package:flutter_test/flutter_test.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:armory_last/main.dart';
import 'package:armory_last/router.dart';
import 'package:armory_last/state/auth_notifier.dart';

void main() {
  testWidgets('приложение запускается и показывает главный экран', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final pb = PocketBase('http://test.local');
    final authNotifier = AuthNotifier(prefs, pb);
    final router = buildRouter(authNotifier);

    await tester.pumpWidget(
      ArmoryApp(pb: pb, authNotifier: authNotifier, router: router),
    );
    await tester.pump();

    expect(find.text('Оружие'), findsOneWidget);
    expect(find.text('Производители'), findsOneWidget);
  });
}
