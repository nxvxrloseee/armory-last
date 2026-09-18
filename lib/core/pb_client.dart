import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';

/// Один [PocketBase]-клиент на всё приложение. Токен персистится через
/// встроенный в пакет [AsyncAuthStore] (shared_preferences = localStorage на
/// web) — PocketBase сам подставляет заголовок Authorization в каждый
/// запрос, пока `authStore.isValid` (см. package:pocketbase/src/client.dart).
Future<PocketBase> buildPocketBase(SharedPreferences prefs) async {
  const key = 'pb_auth';
  final store = AsyncAuthStore(
    save: (data) async => prefs.setString(key, data),
    clear: () async => prefs.remove(key),
    initial: prefs.getString(key),
  );
  return PocketBase(pocketBaseUrl, authStore: store);
}
