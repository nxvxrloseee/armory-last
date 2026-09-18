import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:armory_last/state/auth_notifier.dart';

const _jsonHeaders = {'content-type': 'application/json'};

/// Собирает синтаксически валидный (но не подписанный настоящим секретом)
/// JWT: [AuthStore.isValid] сам декодирует payload и сверяет `exp`, поэтому
/// тестовому токену достаточно быть трёхчастным base64url и иметь future-`exp`
/// — подпись PocketBase на клиенте не проверяет.
String fakeJwt() {
  String b64(Map<String, dynamic> data) =>
      base64Url.encode(utf8.encode(jsonEncode(data))).replaceAll('=', '');
  final header = b64({'alg': 'HS256', 'typ': 'JWT'});
  final payload = b64({
    'exp': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
  });
  return '$header.$payload.fake-signature';
}

/// Тот же приём, что раньше подменял транспорт Dio: здесь подменяется
/// [PocketBase]-клиента `httpClientFactory`, поэтому проверяется настоящий
/// код [AuthNotifier], а не заглушка поверх него. `/auth-with-password`
/// отвечает нужной ролью, `/collections/clients/records` — единственной
/// тестовой записью клиента (нужна [AuthNotifier._applySession] для buyer).
Future<AuthNotifier> loggedInAs(String role) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final pb = PocketBase(
    'http://test.local',
    httpClientFactory: () => MockClient((request) async {
      if (request.url.path.contains('auth-with-password') ||
          request.url.path.contains('auth-refresh')) {
        final body = jsonEncode({
          'token': fakeJwt(),
          'record': {
            'id': 'user1',
            'collectionId': '_pb_users_auth_',
            'collectionName': 'users',
            'email': 'test@example.com',
            'last_name': 'Тестов',
            'first_name': 'Тест',
            'role': role,
          },
        });
        return http.Response(body, 200, headers: _jsonHeaders);
      }
      if (request.url.path.contains('/collections/clients/records')) {
        final body = jsonEncode({
          'page': 1,
          'perPage': 1,
          'totalItems': 1,
          'totalPages': 1,
          'items': [
            {
              'id': 'client1',
              'collectionId': 'clients',
              'collectionName': 'clients',
              'user': 'user1',
              'phone': '',
            },
          ],
        });
        return http.Response(body, 200, headers: _jsonHeaders);
      }
      return http.Response(jsonEncode({'message': 'not found'}), 404, headers: _jsonHeaders);
    }),
  );
  final auth = AuthNotifier(prefs, pb);
  await auth.login('test@example.com', 'irrelevant');
  return auth;
}

/// [PocketBase] без единого залогиненного пользователя — для проверки
/// поведения "гость не имеет прав ни одной роли".
Future<AuthNotifier> loggedOut() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final pb = PocketBase(
    'http://test.local',
    httpClientFactory: () => MockClient(
      (request) async => http.Response(jsonEncode({'message': 'not found'}), 404, headers: _jsonHeaders),
    ),
  );
  return AuthNotifier(prefs, pb);
}
