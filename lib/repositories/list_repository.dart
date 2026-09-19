import '../models/page_result.dart';

abstract interface class ListRepository<T, Q> {
  Future<PageResult<T>> find(Q query);
  Future<int> deleteMany(List<String> ids);
}
