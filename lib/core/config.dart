/// Адрес PocketBase как параметр сборки, а не константа — на занятии он
/// один, дома другой, при публикации третий.
///
///   flutter run -d chrome --web-port=5555 --dart-define=POCKETBASE_URL=http://192.168.1.10:8090
const pocketBaseUrl = String.fromEnvironment(
  'POCKETBASE_URL',
  defaultValue: 'http://127.0.0.1:8090',
);
