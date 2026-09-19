import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:armory_last/state/auth_notifier.dart';

const _jsonHeaders = {'content-type': 'application/json'};

String fakeJwt() {
  String b64(Map<String, dynamic> data) =>
      base64Url.encode(utf8.encode(jsonEncode(data))).replaceAll('=', '');
  final header = b64({'alg': 'HS256', 'typ': 'JWT'});
  final payload = b64({
    'exp': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
  });
  return '$header.$payload.fake-signature';
}

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
