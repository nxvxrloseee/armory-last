import '../models/license.dart';

/// 1:1 с Client — нет отдельного списочного экрана/query, только "найти
/// лицензию этого покупателя" и создать/изменить (см. client_detail_screen).
abstract interface class LicenseRepository {
  Future<License?> findByClientId(String clientId);

  /// [draft.id] игнорируется — идентификатор назначает репозиторий.
  /// Бросает [UniqueConstraintException], если номер лицензии уже занят.
  Future<License> create(License draft);

  Future<License> update(License license);
}
