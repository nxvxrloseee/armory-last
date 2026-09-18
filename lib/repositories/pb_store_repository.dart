import 'package:pocketbase/pocketbase.dart';

import '../core/api_exceptions.dart';
import '../models/page_result.dart';
import '../models/store.dart';
import '../models/store_query.dart';
import 'repository_exceptions.dart';
import 'store_repository.dart';

Store _fromRecord(RecordModel r) => Store(
  id: r.id,
  name: r.get<String>('name', ''),
  address: r.get<String>('address', ''),
  deletedAt: r.get<bool>('is_deleted', false)
      ? (DateTime.tryParse(r.get<String>('deleted_at', '')) ?? DateTime.now())
      : null,
);

class PbStoreRepository implements StoreRepository {
  PbStoreRepository(this._pb);
  final PocketBase _pb;

  String _filter(StoreQuery q) {
    final parts = <String>['is_deleted = ${q.includeDeleted ? 'true' : 'false'}'];
    if (q.search.isNotEmpty) {
      parts.add(_pb.filter('(name ~ {:s} || address ~ {:s})', {'s': q.search}));
    }
    return parts.join(' && ');
  }

  @override
  Future<PageResult<Store>> find(StoreQuery q) => guard(() async {
    final result = await _pb.collection('stores').getList(
      page: q.page,
      perPage: q.size,
      filter: _filter(q),
      sort: '${q.sortAscending ? '' : '-'}${q.sortField}',
    );
    return PageResult<Store>(
      items: result.items.map(_fromRecord).toList(),
      page: result.page,
      size: result.perPage,
      total: result.totalItems,
    );
  });

  @override
  Future<List<Store>> listAll() => guard(() async {
    final items = await _pb.collection('stores').getFullList(filter: 'is_deleted = false', sort: 'name');
    return items.map(_fromRecord).toList();
  });

  @override
  Future<Store?> findById(String id) async {
    try {
      return await guard(() async => _fromRecord(await _pb.collection('stores').getOne(id)));
    } on NotFoundException {
      return null;
    }
  }

  Map<String, dynamic> _body(Store s) => {'name': s.name, 'address': s.address};

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
  Future<Store> create(Store draft) => _rethrowNameConflict(
    () => guard(() async => _fromRecord(await _pb.collection('stores').create(body: _body(draft)))),
  );

  @override
  Future<Store> update(Store store) => _rethrowNameConflict(
    () => guard(() async => _fromRecord(await _pb.collection('stores').update(store.id, body: _body(store)))),
  );

  @override
  Future<void> softDelete(String id) => guard(() => _pb.collection('stores').update(
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
      _rethrowConflict(() => guard(() => _pb.collection('stores').delete(id)));

  @override
  Future<void> restore(String id) => guard(
    () => _pb.collection('stores').update(id, body: {'is_deleted': false, 'deleted_at': ''}),
  );

  @override
  Future<int> deleteMany(List<String> ids) => guard(() async {
    for (final id in ids) {
      await _pb.collection('stores').update(
        id,
        body: {'is_deleted': true, 'deleted_at': DateTime.now().toUtc().toIso8601String()},
      );
    }
    return ids.length;
  });
}
