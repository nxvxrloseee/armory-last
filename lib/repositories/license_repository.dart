import '../models/license.dart';

abstract interface class LicenseRepository {
  Future<License?> findByClientId(String clientId);

  Future<License> create(License draft);

  Future<License> update(License license);
}
