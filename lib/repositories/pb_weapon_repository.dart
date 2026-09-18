import 'package:pocketbase/pocketbase.dart';

import '../core/api_exceptions.dart';
import '../models/page_result.dart';
import '../models/weapon.dart';
import '../models/weapon_query.dart';
import 'repository_exceptions.dart';
import 'weapon_repository.dart';

Weapon _fromRecord(RecordModel r) => Weapon(
  id: r.id,
  name: r.get<String>('name', ''),
  sku: r.get<String>('sku', ''),
  year: r.get<int>('year', 0),
  caliber: r.get<String>('caliber', ''),
  manufacturerId: r.get<String>('manufacturer', ''),
  categoryIds: r.get<List<String>>('categories', const []),
  designerIds: r.get<List<String>>('designers', const []),
  price: r.get<int>('price', 0),
  stockTotal: r.get<int>('stock_total', 0),
  stockAvailable: r.get<int>('stock_available', 0),
  deletedAt: r.get<bool>('is_deleted', false)
      ? (DateTime.tryParse(r.get<String>('deleted_at', '')) ?? DateTime.now())
      : null,
);

/// Третья по счёту реализация [WeaponRepository] (см. класс-doc в самом
/// интерфейсе): сначала данные в памяти, потом собственный Go-сервер
/// (ПР4/5/6), теперь PocketBase — экраны и интерфейс не изменились.
class PbWeaponRepository implements WeaponRepository {
  PbWeaponRepository(this._pb);
  final PocketBase _pb;

  String _filter(WeaponQuery q) {
    final parts = <String>['is_deleted = ${q.includeDeleted ? 'true' : 'false'}'];
    if (q.search.isNotEmpty) {
      parts.add(_pb.filter('(name ~ {:s} || sku ~ {:s})', {'s': q.search}));
    }
    if (q.manufacturerId != null) {
      parts.add(_pb.filter('manufacturer = {:m}', {'m': q.manufacturerId}));
    }
    if (q.categoryId != null) {
      parts.add(_pb.filter('categories ?= {:c}', {'c': q.categoryId}));
    }
    if (q.designerId != null) {
      parts.add(_pb.filter('designers ?= {:d}', {'d': q.designerId}));
    }
    if (q.yearFrom != null) {
      parts.add(_pb.filter('year >= {:yf}', {'yf': q.yearFrom}));
    }
    if (q.yearTo != null) {
      parts.add(_pb.filter('year <= {:yt}', {'yt': q.yearTo}));
    }
    return parts.join(' && ');
  }

  @override
  Future<PageResult<Weapon>> find(WeaponQuery q) => guard(() async {
    final result = await _pb.collection('weapons').getList(
      page: q.page,
      perPage: q.size,
      filter: _filter(q),
      sort: '${q.sortAscending ? '' : '-'}${q.sortField}',
    );
    return PageResult<Weapon>(
      items: result.items.map(_fromRecord).toList(),
      page: result.page,
      size: result.perPage,
      total: result.totalItems,
    );
  });

  @override
  Future<Weapon?> findById(String id) async {
    try {
      return await guard(() async {
        final r = await _pb.collection('weapons').getOne(id);
        return _fromRecord(r);
      });
    } on NotFoundException {
      return null;
    }
  }

  Map<String, dynamic> _body(Weapon w) => {
    'name': w.name,
    'sku': w.sku,
    'year': w.year,
    'caliber': w.caliber,
    'manufacturer': w.manufacturerId,
    'categories': w.categoryIds,
    'designers': w.designerIds,
    'price': w.price,
    'stock_total': w.stockTotal,
    'stock_available': w.stockAvailable,
  };

  /// Ошибка уникальности артикула приходит как [ValidationException] с
  /// полем `sku` — здесь она превращается в тот же [UniqueConstraintException],
  /// который ловит weapon_form_screen.dart, чтобы форма не менялась.
  Future<T> _rethrowSkuConflict<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ValidationException catch (e) {
      final skuError = e.errors['sku'];
      if (skuError != null) throw UniqueConstraintException('sku', skuError);
      rethrow;
    }
  }

  @override
  Future<Weapon> create(Weapon draft) => _rethrowSkuConflict(
    () => guard(() async {
      final r = await _pb.collection('weapons').create(body: _body(draft));
      return _fromRecord(r);
    }),
  );

  @override
  Future<Weapon> update(Weapon weapon) => _rethrowSkuConflict(
    () => guard(() async {
      final r = await _pb
          .collection('weapons')
          .update(weapon.id, body: _body(weapon));
      return _fromRecord(r);
    }),
  );

  @override
  Future<void> softDelete(String id) => guard(
    () => _pb.collection('weapons').update(
      id,
      body: {'is_deleted': true, 'deleted_at': DateTime.now().toUtc().toIso8601String()},
    ),
  );

  /// Бросает [ReferentialIntegrityException], если это оружие ещё
  /// фигурирует в заказах — PocketBase проверяет это сам
  /// (`cascadeDelete: false` на relation-полях orders), число ссылающихся
  /// записей при этом не присылает (платформенное ограничение, count = 0).
  Future<T> _rethrowConflict<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ConflictException catch (e) {
      throw ReferentialIntegrityException(e.count, e.message);
    }
  }

  @override
  Future<void> hardDelete(String id) =>
      _rethrowConflict(() => guard(() => _pb.collection('weapons').delete(id)));

  @override
  Future<void> restore(String id) => guard(
    () => _pb.collection('weapons').update(id, body: {'is_deleted': false, 'deleted_at': ''}),
  );

  @override
  Future<int> deleteMany(List<String> ids) => guard(() async {
    for (final id in ids) {
      await _pb.collection('weapons').update(
        id,
        body: {'is_deleted': true, 'deleted_at': DateTime.now().toUtc().toIso8601String()},
      );
    }
    return ids.length;
  });
}
