import '../models/category.dart';
import '../models/category_query.dart';
import 'list_repository.dart';

abstract interface class CategoryRepository
    implements ListRepository<Category, CategoryQuery> {
  Future<Category?> findById(String id);

  Future<List<Category>> listAll();

  Future<Category> create(Category draft);
  Future<Category> update(Category category);

  Future<void> softDelete(String id);
  Future<void> hardDelete(String id);
  Future<void> restore(String id);
}
