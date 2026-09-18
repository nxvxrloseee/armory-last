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
    // AuthNotifier до restore() ещё "восстанавливается" (isRestoring == true),
    // поэтому redirect() в router.dart ничего не решает и пропускает прямо
    // на '/', как и без входа — сетевых запросов при этом не происходит,
    // поэтому PocketBase-клиенту не нужен подменённый транспорт.
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
