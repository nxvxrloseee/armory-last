import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_exceptions.dart';
import '../models/app_user.dart';
import '../models/register_input.dart';
import '../models/role.dart';

/// Состояние входа на всё приложение. Токен персистится PocketBase-ом самим
/// (см. core/pb_client.dart) — здесь только профиль пользователя и общая
/// длительность сессии (ПР5, оценка «5»), которых у токена самого по себе
/// нет.
///
/// Профиль (в т.ч. роль) кэшируется в `auth_cached_user`, и после входа
/// именно этот кэш красит интерфейс — сервер на восстановлении сессии
/// запрашивается только чтобы убедиться, что токен ещё жив
/// ([PocketBase.collection('users').authRefresh]), его ответ роль в кэше не
/// перезаписывает. Это НАМЕРЕННО уязвимое для подмены место (тот же приём,
/// что в ПР5, и тот же вопрос есть в билете защиты итогового проекта:
/// "откройте DevTools и подмените сохранённые данные..."). Реальная защита
/// живёт только на сервере: `listRule`/`createRule`/... каждой коллекции
/// проверяют настоящую роль из токена, а не то, что показывает интерфейс.
class AuthNotifier extends ChangeNotifier {
  static const _kSessionStarted = 'auth_session_started';
  static const _kCachedUser = 'auth_cached_user';

  /// Общая длительность сессии — независимо от активности, по истечении
  /// этого времени от входа пользователь выходит.
  static const sessionMaxAge = Duration(hours: 8);

  AuthNotifier(this._prefs, this.pb);

  final SharedPreferences _prefs;
  final PocketBase pb;

  AppUser? _user;
  DateTime? _sessionStarted;
  String? _restoreError;
  String? _lastLogoutReason;
  bool _restoring = true;

  AppUser? get user => _user;
  String? get restoreError => _restoreError;
  bool get isAuthenticated => _user != null;
  bool get isRestoring => _restoring;

  /// Причина последнего автоматического выхода — экран входа показывает её
  /// один раз и сбрасывает через [consumeLogoutReason].
  String? get lastLogoutReason => _lastLogoutReason;

  String? consumeLogoutReason() {
    final reason = _lastLogoutReason;
    _lastLogoutReason = null;
    return reason;
  }

  bool has(Role role) => _user != null && _user!.role.level >= role.level;

  DateTime? get sessionExpiresAt => _sessionStarted?.add(sessionMaxAge);

  /// Восстановление сессии при запуске приложения — вызывается один раз до
  /// построения дерева виджетов (см. main.dart).
  Future<void> restore() async {
    _restoring = true;
    final startedRaw = _prefs.getString(_kSessionStarted);
    _sessionStarted = startedRaw == null ? null : DateTime.tryParse(startedRaw);

    if (!pb.authStore.isValid) {
      _restoring = false;
      notifyListeners();
      return;
    }
    if (_sessionExpired()) {
      await logout(
        reason: 'Сессия завершена: истекло максимальное время входа.',
      );
      _restoring = false;
      notifyListeners();
      return;
    }

    // Красим интерфейс сразу по кэшу, не дожидаясь сети — и именно этот
    // кэш, не ответ сервера, остаётся источником роли для UI (см. class-doc).
    final cachedRaw = _prefs.getString(_kCachedUser);
    if (cachedRaw != null) {
      try {
        _user = AppUser.fromJson(jsonDecode(cachedRaw) as Map<String, dynamic>);
      } catch (_) {
        _user = null;
      }
    }
    try {
      // Только проверка + обновление токена; результат (в т.ч. актуальную
      // роль) сознательно игнорируем — см. class-doc.
      await pb.collection('users').authRefresh();
      _restoreError = null;
    } on ClientException catch (e) {
      final mapped = mapPbError(e);
      if (mapped is UnauthorizedException) {
        await logout(reason: 'Сессия истекла, войдите снова.');
      } else {
        // Сервер недоступен: сессию не сбрасываем, покажем ошибку на экране
        // входа, но токен остаётся — при следующей успешной проверке всё
        // восстановится само, без повторного ввода пароля.
        _restoreError = 'Не удалось проверить сессию: сервер недоступен.';
      }
    }
    _restoring = false;
    notifyListeners();
  }

  bool _sessionExpired() {
    final started = _sessionStarted;
    return started != null &&
        DateTime.now().toUtc().difference(started) > sessionMaxAge;
  }

  Future<void> login(String email, String password) => guard(() async {
    final auth = await pb.collection('users').authWithPassword(email, password);
    await _applySession(auth.record);
  });

  Future<void> register(RegisterInput input) => guard(() async {
    await pb.collection('users').create(
      body: {
        'email': input.email,
        'password': input.password,
        'passwordConfirm': input.password,
        'role': 'buyer',
        'last_name': input.lastName,
        'first_name': input.firstName,
        if (input.patronymic != null) 'patronymic': input.patronymic,
      },
    );
    final auth = await pb
        .collection('users')
        .authWithPassword(input.email, input.password);
    // Клиентский профиль создаётся отдельным запросом сразу после первого
    // входа — сущность `clients` не может быть создана до того, как
    // существует связанный `users`-аккаунт (relation обязателен).
    await pb.collection('clients').create(
      body: {'user': auth.record.id, 'phone': input.phone},
    );
    await _applySession(auth.record);
  });

  Future<void> _applySession(RecordModel record) async {
    String? clientId;
    if (record.get<String>('role') == 'buyer') {
      try {
        final client = await pb
            .collection('clients')
            .getFirstListItem('user="${record.id}"');
        clientId = client.id;
      } on ClientException {
        clientId = null; // регистрация не успела создать клиента — не должно
      }
    }
    _user = AppUser(
      id: record.id,
      email: record.get<String>('email', ''),
      lastName: record.get<String>('last_name', ''),
      firstName: record.get<String>('first_name', ''),
      patronymic: record.get<String>('patronymic', ''),
      role: Role.fromWire(record.get<String>('role', 'buyer')),
      clientId: clientId,
    );
    _sessionStarted = DateTime.now().toUtc();
    _restoreError = null;
    await _prefs.setString(_kSessionStarted, _sessionStarted!.toIso8601String());
    await _prefs.setString(_kCachedUser, jsonEncode(_user!.toJson()));
    notifyListeners();
  }

  /// Молча обновляет токен — используется интерсептором репозиториев при
  /// 401 на "боевом" запросе, чтобы исходный запрос можно было повторить
  /// прозрачно для пользователя (оценка «5»: автообновление токена).
  Future<void> refreshTokens() => guard(
    () => pb.collection('users').authRefresh(),
  );

  Future<void> logout({String? reason}) async {
    _user = null;
    _sessionStarted = null;
    if (reason != null) _lastLogoutReason = reason;
    pb.authStore.clear();
    await _prefs.remove(_kSessionStarted);
    await _prefs.remove(_kCachedUser);
    notifyListeners();
  }
}
