import 'package:pocketbase/pocketbase.dart';

import '../core/api_exceptions.dart';
import '../models/category.dart';
import '../models/category_query.dart';
import '../models/page_result.dart';
import 'category_repository.dart';
import 'repository_exceptions.dart';

Category _fromRecord(RecordModel r) => Category(
  id: r.id,
  name: r.get<String>('name', ''),
  licenseType: r.get<String>('license_type', 'other'),
  deletedAt: r.get<bool>('is_deleted', false)
      ? (DateTime.tryParse(r.get<String>('deleted_at', '')) ?? DateTime.now())
      : null,
);

class PbCategoryRepository implements CategoryRepository {
  PbCategoryRepository(this._pb);
  final PocketBase _pb;

  String _filter(CategoryQuery q) {
    final parts = <String>['is_deleted = ${q.includeDeleted ? 'true' : 'false'}'];
    if (q.search.isNotEmpty) {
      parts.add(_pb.filter('name ~ {:s}', {'s': q.search}));
    }
    return parts.join(' && ');
  }

  @override
  Future<PageResult<Category>> find(CategoryQuery q) => guard(() async {
    final result = await _pb.collection('categories').getList(
      page: q.page,
      perPage: q.size,
      filter: _filter(q),
      sort: '${q.sortAscending ? '' : '-'}${q.sortField}',
    );
    return PageResult<Category>(
      items: result.items.map(_fromRecord).toList(),
      page: result.page,
      size: result.perPage,
      total: result.totalItems,
    );
  });

  @override
  Future<List<Category>> listAll() => guard(() async {
    final items = await _pb.collection('categories').getFullList(filter: 'is_deleted = false', sort: 'name');
    return items.map(_fromRecord).toList();
  });

  @override
  Future<Category?> findById(String id) async {
    try {
      return await guard(() async => _fromRecord(await _pb.collection('categories').getOne(id)));
    } on NotFoundException {
      return null;
    }
  }

  Map<String, dynamic> _body(Category c) => {'name': c.name, 'license_type': c.licenseType};

  Future<T> _rethrowNameConflict<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ValidationException catch (e) {
      final nameError = e.errors['name'];
      if (nameError != null) throw UniqueConstraintException('name', nameError);
      rethrow;
    }
  }

  @override
  Future<Category> create(Category draft) => _rethrowNameConflict(
    () => guard(() async => _fromRecord(await _pb.collection('categories').create(body: _body(draft)))),
  );

  @override
  Future<Category> update(Category category) => _rethrowNameConflict(
    () => guard(() async =>
        _fromRecord(await _pb.collection('categories').update(category.id, body: _body(category)))),
  );

  @override
  Future<void> softDelete(String id) => guard(() => _pb.collection('categories').update(
        id,
        body: {'is_deleted': true, 'deleted_at': DateTime.now().toUtc().toIso8601String()},
      ));

  Future<T> _rethrowConflict<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ConflictException catch (e) {
      throw ReferentialIntegrityException(e.count, e.message);
    }
  }

  @override
  Future<void> hardDelete(String id) =>
      _rethrowConflict(() => guard(() => _pb.collection('categories').delete(id)));

  @override
  Future<void> restore(String id) => guard(
    () => _pb.collection('categories').update(id, body: {'is_deleted': false, 'deleted_at': ''}),
  );

  @override
  Future<int> deleteMany(List<String> ids) => guard(() async {
    for (final id in ids) {
      await _pb.collection('categories').update(
        id,
        body: {'is_deleted': true, 'deleted_at': DateTime.now().toUtc().toIso8601String()},
      );
    }
    return ids.length;
  });
}
