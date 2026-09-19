import '../models/store.dart';
import '../models/store_query.dart';
import 'list_repository.dart';

abstract interface class StoreRepository
    implements ListRepository<Store, StoreQuery> {
  Future<Store?> findById(String id);

  Future<List<Store>> listAll();

  Future<Store> create(Store draft);
  Future<Store> update(Store store);

  Future<void> softDelete(String id);
  Future<void> hardDelete(String id);
  Future<void> restore(String id);
}
