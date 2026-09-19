import 'package:pocketbase/pocketbase.dart';

import '../core/api_exceptions.dart';
import '../models/client.dart';
import '../models/client_query.dart';
import '../models/page_result.dart';
import 'client_repository.dart';

Client _fromRecord(RecordModel r) {
  final user = r.get<RecordModel?>('expand.user', null);
  return Client(
    id: r.id,
    userId: r.get<String>('user', ''),
    fullName: user == null
        ? ''
        : [
            user.get<String>('last_name', ''),
            user.get<String>('first_name', ''),
            user.get<String>('patronymic', ''),
          ].where((s) => s.isNotEmpty).join(' '),
    email: user?.get<String>('email', '') ?? '',
    phone: r.get<String>('phone', ''),
    deletedAt: r.get<bool>('is_deleted', false)
        ? (DateTime.tryParse(r.get<String>('deleted_at', '')) ?? DateTime.now())
        : null,
  );
}

class PbClientRepository implements ClientRepository {
  PbClientRepository(this._pb);
  final PocketBase _pb;

  String _filter(ClientQuery q) {
    final parts = <String>['is_deleted = ${q.includeDeleted ? 'true' : 'false'}'];
    if (q.search.isNotEmpty) {
      parts.add(_pb.filter(
        '(user.last_name ~ {:s} || user.first_name ~ {:s} || user.email ~ {:s} || phone ~ {:s})',
        {'s': q.search},
      ));
    }
    return parts.join(' && ');
  }

  @override
  Future<PageResult<Client>> find(ClientQuery q) => guard(() async {
    final sortField = q.sortField == 'fullName' ? 'created' : q.sortField;
    final result = await _pb.collection('clients').getList(
      page: q.page,
      perPage: q.size,
      filter: _filter(q),
      sort: '${q.sortAscending ? '' : '-'}$sortField',
      expand: 'user',
    );
    return PageResult<Client>(
      items: result.items.map(_fromRecord).toList(),
      page: result.page,
      size: result.perPage,
      total: result.totalItems,
    );
  });

  @override
  Future<Client?> findById(String id) async {
    try {
      return await guard(
        () async => _fromRecord(await _pb.collection('clients').getOne(id, expand: 'user')),
      );
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<Client> update(Client client) => guard(() async => _fromRecord(
        await _pb.collection('clients').update(
          client.id,
          body: {'phone': client.phone},
          expand: 'user',
        ),
      ));

  @override
  Future<void> softDelete(String id) => guard(() => _pb.collection('clients').update(
        id,
        body: {'is_deleted': true, 'deleted_at': DateTime.now().toUtc().toIso8601String()},
      ));

  @override
  Future<void> hardDelete(String id) => guard(() => _pb.collection('clients').delete(id));

  @override
  Future<void> restore(String id) => guard(
    () => _pb.collection('clients').update(id, body: {'is_deleted': false, 'deleted_at': ''}),
  );

  @override
  Future<int> deleteMany(List<String> ids) => guard(() async {
    for (final id in ids) {
      await _pb.collection('clients').update(
        id,
        body: {'is_deleted': true, 'deleted_at': DateTime.now().toUtc().toIso8601String()},
      );
    }
    return ids.length;
  });
}
