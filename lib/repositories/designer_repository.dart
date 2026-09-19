import '../models/designer.dart';
import '../models/designer_query.dart';
import 'list_repository.dart';

abstract interface class DesignerRepository
    implements ListRepository<Designer, DesignerQuery> {
  Future<Designer?> findById(String id);

  Future<List<Designer>> listAll();

  Future<Designer> create(Designer draft);
  Future<Designer> update(Designer designer);

  Future<void> softDelete(String id);
  Future<void> hardDelete(String id);
  Future<void> restore(String id);
}
