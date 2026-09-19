import '../models/manufacturer.dart';
import '../models/manufacturer_query.dart';
import 'list_repository.dart';

abstract interface class ManufacturerRepository
    implements ListRepository<Manufacturer, ManufacturerQuery> {
  Future<Manufacturer?> findById(String id);

  Future<List<Manufacturer>> listAll();

  Future<Manufacturer> create(Manufacturer draft);
  Future<Manufacturer> update(Manufacturer manufacturer);

  Future<void> softDelete(String id);
  Future<void> hardDelete(String id);
  Future<void> restore(String id);
}
