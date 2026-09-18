import '../models/store.dart';
import '../models/store_query.dart';
import 'list_repository.dart';

abstract interface class StoreRepository
    implements ListRepository<Store, StoreQuery> {
  Future<Store?> findById(String id);

  /// Полный список действующих магазинов — нужен выбору точки выдачи при
  /// оформлении заказа.
  Future<List<Store>> listAll();

  /// [draft.id] игнорируется — идентификатор назначает репозиторий.
  Future<Store> create(Store draft);
  Future<Store> update(Store store);

  Future<void> softDelete(String id);
  Future<void> hardDelete(String id);
  Future<void> restore(String id);
}
