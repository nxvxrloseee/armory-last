import 'package:pocketbase/pocketbase.dart';

import '../core/api_exceptions.dart';
import '../models/license.dart';
import 'license_repository.dart';
import 'repository_exceptions.dart';

License _fromRecord(RecordModel r) => License(
  id: r.id,
  clientId: r.get<String>('client', ''),
  number: r.get<String>('number', ''),
  type: r.get<String>('type', 'other'),
  issuedAt: DateTime.tryParse(r.get<String>('issued_at', '')) ?? DateTime.fromMillisecondsSinceEpoch(0),
  expiresAt: DateTime.tryParse(r.get<String>('expires_at', '')) ?? DateTime.fromMillisecondsSinceEpoch(0),
);

class PbLicenseRepository implements LicenseRepository {
  PbLicenseRepository(this._pb);
  final PocketBase _pb;

  @override
  Future<License?> findByClientId(String clientId) async {
    try {
      return await guard(() async => _fromRecord(
            await _pb.collection('licenses').getFirstListItem(
              _pb.filter('client = {:c}', {'c': clientId}),
            ),
          ));
    } on NotFoundException {
      return null;
    }
  }

  Map<String, dynamic> _body(License l) => {
    'client': l.clientId,
    'number': l.number,
    'type': l.type,
    'issued_at': l.issuedAt.toUtc().toIso8601String(),
    'expires_at': l.expiresAt.toUtc().toIso8601String(),
  };

  Future<T> _rethrowNumberConflict<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ValidationException catch (e) {
      final numberError = e.errors['number'];
      if (numberError != null) throw UniqueConstraintException('number', numberError);
      rethrow;
    }
  }

  @override
  Future<License> create(License draft) => _rethrowNumberConflict(
    () => guard(() async => _fromRecord(await _pb.collection('licenses').create(body: _body(draft)))),
  );

  @override
  Future<License> update(License license) => _rethrowNumberConflict(
    () => guard(() async =>
        _fromRecord(await _pb.collection('licenses').update(license.id, body: _body(license)))),
  );
}
