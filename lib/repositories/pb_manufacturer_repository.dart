import 'package:pocketbase/pocketbase.dart';

import '../core/api_exceptions.dart';
import '../models/manufacturer.dart';
import '../models/manufacturer_query.dart';
import '../models/page_result.dart';
import 'manufacturer_repository.dart';
import 'repository_exceptions.dart';

Manufacturer _fromRecord(RecordModel r) => Manufacturer(
  id: r.id,
  name: r.get<String>('name', ''),
  country: r.get<String>('country', ''),
  founded: r.get<int>('founded', 0),
  deletedAt: r.get<bool>('is_deleted', false)
      ? (DateTime.tryParse(r.get<String>('deleted_at', '')) ?? DateTime.now())
      : null,
);

class PbManufacturerRepository implements ManufacturerRepository {
  PbManufacturerRepository(this._pb);
  final PocketBase _pb;

  String _filter(ManufacturerQuery q) {
    final parts = <String>['is_deleted = ${q.includeDeleted ? 'true' : 'false'}'];
    if (q.search.isNotEmpty) {
      parts.add(_pb.filter('(name ~ {:s} || country ~ {:s})', {'s': q.search}));
    }
    return parts.join(' && ');
  }

  @override
  Future<PageResult<Manufacturer>> find(ManufacturerQuery q) => guard(() async {
    final result = await _pb.collection('manufacturers').getList(
      page: q.page,
      perPage: q.size,
      filter: _filter(q),
      sort: '${q.sortAscending ? '' : '-'}${q.sortField}',
    );
    return PageResult<Manufacturer>(
      items: result.items.map(_fromRecord).toList(),
      page: result.page,
      size: result.perPage,
      total: result.totalItems,
    );
  });

  @override
  Future<List<Manufacturer>> listAll() => guard(() async {
    final items = await _pb
        .collection('manufacturers')
        .getFullList(filter: 'is_deleted = false', sort: 'name');
    return items.map(_fromRecord).toList();
  });

  @override
  Future<Manufacturer?> findById(String id) async {
    try {
      return await guard(() async => _fromRecord(await _pb.collection('manufacturers').getOne(id)));
    } on NotFoundException {
      return null;
    }
  }

  Map<String, dynamic> _body(Manufacturer m) =>
      {'name': m.name, 'country': m.country, 'founded': m.founded};

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
  Future<Manufacturer> create(Manufacturer draft) => _rethrowNameConflict(
    () => guard(() async => _fromRecord(await _pb.collection('manufacturers').create(body: _body(draft)))),
  );

  @override
  Future<Manufacturer> update(Manufacturer manufacturer) => _rethrowNameConflict(
    () => guard(() async =>
        _fromRecord(await _pb.collection('manufacturers').update(manufacturer.id, body: _body(manufacturer)))),
  );

  @override
  Future<void> softDelete(String id) => guard(() => _pb.collection('manufacturers').update(
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
      _rethrowConflict(() => guard(() => _pb.collection('manufacturers').delete(id)));

  @override
  Future<void> restore(String id) => guard(
    () => _pb.collection('manufacturers').update(id, body: {'is_deleted': false, 'deleted_at': ''}),
  );

  @override
  Future<int> deleteMany(List<String> ids) => guard(() async {
    for (final id in ids) {
      await _pb.collection('manufacturers').update(
        id,
        body: {'is_deleted': true, 'deleted_at': DateTime.now().toUtc().toIso8601String()},
      );
    }
    return ids.length;
  });
}
