import '../models/weapon.dart';
import '../models/weapon_query.dart';
import 'list_repository.dart';

abstract interface class WeaponRepository
    implements ListRepository<Weapon, WeaponQuery> {
  Future<Weapon?> findById(String id);

  Future<Weapon> create(Weapon draft);

  Future<Weapon> update(Weapon weapon);

  Future<void> softDelete(String id);
  Future<void> hardDelete(String id);
  Future<void> restore(String id);
}
