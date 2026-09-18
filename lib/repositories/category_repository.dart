import '../models/category.dart';
import '../models/category_query.dart';
import 'list_repository.dart';

abstract interface class CategoryRepository
    implements ListRepository<Category, CategoryQuery> {
  Future<Category?> findById(String id);

  /// Полный список действующих категорий — нужен фильтру и множественному
  /// выбору категорий в форме оружия.
  Future<List<Category>> listAll();

  /// [draft.id] игнорируется — идентификатор назначает репозиторий.
  Future<Category> create(Category draft);
  Future<Category> update(Category category);

  Future<void> softDelete(String id);
  Future<void> hardDelete(String id);
  Future<void> restore(String id);
}
