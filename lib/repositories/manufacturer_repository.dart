import '../models/manufacturer.dart';
import '../models/manufacturer_query.dart';
import 'list_repository.dart';

abstract interface class ManufacturerRepository
    implements ListRepository<Manufacturer, ManufacturerQuery> {
  Future<Manufacturer?> findById(String id);

  /// Полный список действующих производителей — нужен спискам оружия для
  /// выпадающего фильтра/поля формы по производителю.
  Future<List<Manufacturer>> listAll();

  /// [draft.id] игнорируется — идентификатор назначает репозиторий.
  Future<Manufacturer> create(Manufacturer draft);
  Future<Manufacturer> update(Manufacturer manufacturer);

  /// Бросает [ReferentialIntegrityException], если на производителя ещё
  /// ссылается хотя бы одна единица оружия.
  Future<void> softDelete(String id);
  Future<void> hardDelete(String id);
  Future<void> restore(String id);
}
