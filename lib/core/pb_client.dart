import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';

Future<PocketBase> buildPocketBase(SharedPreferences prefs) async {
  const key = 'pb_auth';
  final store = AsyncAuthStore(
    save: (data) async => prefs.setString(key, data),
    clear: () async => prefs.remove(key),
    initial: prefs.getString(key),
  );
  return PocketBase(pocketBaseUrl, authStore: store);
}
