import 'package:pocketbase/pocketbase.dart';

import '../core/api_exceptions.dart';
import '../models/designer.dart';
import '../models/designer_query.dart';
import '../models/page_result.dart';
import 'designer_repository.dart';
import 'repository_exceptions.dart';

Designer _fromRecord(RecordModel r) => Designer(
  id: r.id,
  fullName: r.get<String>('full_name', ''),
  country: r.get<String>('country', ''),
  activeSince: r.get<int>('active_since', 0),
  deletedAt: r.get<bool>('is_deleted', false)
      ? (DateTime.tryParse(r.get<String>('deleted_at', '')) ?? DateTime.now())
      : null,
);

const _sortFieldMap = {'fullName': 'full_name', 'activeSince': 'active_since'};

class PbDesignerRepository implements DesignerRepository {
  PbDesignerRepository(this._pb);
  final PocketBase _pb;

  String _filter(DesignerQuery q) {
    final parts = <String>['is_deleted = ${q.includeDeleted ? 'true' : 'false'}'];
    if (q.search.isNotEmpty) {
      parts.add(_pb.filter('(full_name ~ {:s} || country ~ {:s})', {'s': q.search}));
    }
    return parts.join(' && ');
  }

  @override
  Future<PageResult<Designer>> find(DesignerQuery q) => guard(() async {
    final sortField = _sortFieldMap[q.sortField] ?? q.sortField;
    final result = await _pb.collection('designers').getList(
      page: q.page,
      perPage: q.size,
      filter: _filter(q),
      sort: '${q.sortAscending ? '' : '-'}$sortField',
    );
    return PageResult<Designer>(
      items: result.items.map(_fromRecord).toList(),
      page: result.page,
      size: result.perPage,
      total: result.totalItems,
    );
  });

  @override
  Future<List<Designer>> listAll() => guard(() async {
    final items =
        await _pb.collection('designers').getFullList(filter: 'is_deleted = false', sort: 'full_name');
    return items.map(_fromRecord).toList();
  });

  @override
  Future<Designer?> findById(String id) async {
    try {
      return await guard(() async => _fromRecord(await _pb.collection('designers').getOne(id)));
    } on NotFoundException {
      return null;
    }
  }

  Map<String, dynamic> _body(Designer d) =>
      {'full_name': d.fullName, 'country': d.country, 'active_since': d.activeSince};

  Future<T> _rethrowNameConflict<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ValidationException catch (e) {
      final nameError = e.errors['full_name'];
      if (nameError != null) throw UniqueConstraintException('fullName', nameError);
      rethrow;
    }
  }

  @override
  Future<Designer> create(Designer draft) => _rethrowNameConflict(
    () => guard(() async => _fromRecord(await _pb.collection('designers').create(body: _body(draft)))),
  );

  @override
  Future<Designer> update(Designer designer) => _rethrowNameConflict(
    () => guard(() async =>
        _fromRecord(await _pb.collection('designers').update(designer.id, body: _body(designer)))),
  );

  @override
  Future<void> softDelete(String id) => guard(() => _pb.collection('designers').update(
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
      _rethrowConflict(() => guard(() => _pb.collection('designers').delete(id)));

  @override
  Future<void> restore(String id) => guard(
    () => _pb.collection('designers').update(id, body: {'is_deleted': false, 'deleted_at': ''}),
  );

  @override
  Future<int> deleteMany(List<String> ids) => guard(() async {
    for (final id in ids) {
      await _pb.collection('designers').update(
        id,
        body: {'is_deleted': true, 'deleted_at': DateTime.now().toUtc().toIso8601String()},
      );
    }
    return ids.length;
  });
}
