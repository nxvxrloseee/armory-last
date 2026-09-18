import '../models/page_result.dart';

/// Общая часть интерфейса всех пяти репозиториев: постраничная выборка и
/// массовое логическое удаление. Вынесена отдельно, чтобы [ListNotifier]
/// (см. state/list_notifier.dart) работал с любой сущностью одинаково,
/// вместо пяти почти одинаковых нотифаеров.
abstract interface class ListRepository<T, Q> {
  Future<PageResult<T>> find(Q query);
  Future<int> deleteMany(List<String> ids);
}
