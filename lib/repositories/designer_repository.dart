import '../models/designer.dart';
import '../models/designer_query.dart';
import 'list_repository.dart';

abstract interface class DesignerRepository
    implements ListRepository<Designer, DesignerQuery> {
  Future<Designer?> findById(String id);

  /// Полный список действующих конструкторов — нужен фильтру и
  /// множественному выбору конструкторов в форме оружия.
  Future<List<Designer>> listAll();

  /// [draft.id] игнорируется — идентификатор назначает репозиторий.
  Future<Designer> create(Designer draft);
  Future<Designer> update(Designer designer);

  Future<void> softDelete(String id);
  Future<void> hardDelete(String id);
  Future<void> restore(String id);
}
