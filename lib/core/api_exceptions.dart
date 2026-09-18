import 'package:pocketbase/pocketbase.dart';

/// Между сетевым слоем и остальным приложением стоит набор собственных
/// исключений — виджеты не должны знать о существовании PocketBase.
sealed class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

/// Нет соединения, таймаут, сервер недоступен, заблокировано CORS.
class NetworkException extends ApiException {
  const NetworkException([
    super.message = 'Сервер недоступен. Проверьте соединение.',
  ]);
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException([super.message = 'Требуется вход в систему.']);
}

/// PocketBase на практике не различает «эта запись правда не существует» и
/// «правило доступа её от вас скрывает» — оба случая приходят как 404 (не
/// 403, как было у самописного сервера в ПР4/5). См. armory_last/pocketbase/
/// README.md. Класс оставлен для мест, где приложение сознательно проверяет
/// роль само (до обращения к серверу), а не для разбора ответа сервера.
class ForbiddenException extends ApiException {
  const ForbiddenException([
    super.message = 'Недостаточно прав для этого действия.',
  ]);
}

class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'Запись не найдена.']);
}

/// Нарушено ограничение ссылочной целостности при удалении. PocketBase (в
/// отличие от armory_api) не присылает число ссылающихся записей — [count]
/// всегда 0, платформенное ограничение, экраны показывают message без числа.
class ConflictException extends ApiException {
  final int count;
  const ConflictException(super.message, {this.count = 0});
}

/// Ошибки валидации по полям. Ключи в [errors] — имена полей коллекции
/// PocketBase (snake_case), маппинг на конкретный домен делает репозиторий.
class ValidationException extends ApiException {
  final Map<String, String> errors;
  const ValidationException(super.message, this.errors);
}

class ServerException extends ApiException {
  const ServerException([
    super.message = 'Ошибка на сервере. Попробуйте позже.',
  ]);
}

bool _looksLikeReferentialIntegrity(ClientException e) =>
    e.response['message']?.toString().contains('relation') ?? false;

ApiException mapPbError(ClientException e) {
  final status = e.statusCode;
  final message = e.response['message']?.toString();
  final data = e.response['data'];

  if (status == 0) {
    return const NetworkException();
  }
  if (status == 400 && data is Map && data.isNotEmpty) {
    final errors = data.map(
      (k, v) => MapEntry(
        '$k',
        (v is Map ? v['message']?.toString() : null) ?? 'Некорректное значение',
      ),
    );
    return ValidationException(message ?? 'Ошибка валидации', errors);
  }
  if (status == 400 && _looksLikeReferentialIntegrity(e)) {
    return ConflictException(
      'Запись используется в других записях — удаление невозможно.',
    );
  }
  if (status == 401) {
    return UnauthorizedException(message ?? 'Требуется вход в систему.');
  }
  if (status == 403) {
    return ForbiddenException(message ?? 'Недостаточно прав для этого действия.');
  }
  if (status == 404) {
    return NotFoundException(message ?? 'Запись не найдена.');
  }
  return ServerException(message ?? 'Неизвестная ошибка (код $status).');
}

/// Каждое обращение к PocketBase оборачивается этой функцией — единственная
/// её задача — не выпустить наружу [ClientException]: в приложение должны
/// попадать только исключения предметной области.
Future<T> guard<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on ClientException catch (e) {
    throw mapPbError(e);
  }
}
