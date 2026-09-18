import 'package:pocketbase/pocketbase.dart';

import '../core/api_exceptions.dart';
import '../models/license.dart';
import '../models/order.dart';
import '../models/page_result.dart';
import 'order_repository.dart';

Order _fromRecord(RecordModel r) {
  final client = r.get<RecordModel?>('expand.client', null);
  final clientUser = client?.get<RecordModel?>('expand.user', null);
  final weapon = r.get<RecordModel?>('expand.weapon', null);
  final store = r.get<RecordModel?>('expand.store', null);
  return Order(
    id: r.id,
    clientId: r.get<String>('client', ''),
    weaponId: r.get<String>('weapon', ''),
    storeId: r.get<String>('store', ''),
    status: r.get<String>('status', 'ordered'),
    serialNumber: r.get<String>('serial_number', '').isEmpty
        ? null
        : r.get<String>('serial_number', ''),
    createdAt: DateTime.tryParse(r.get<String>('created', '')) ?? DateTime.now(),
    pickedUpAt: r.get<String>('picked_up_at', '').isEmpty
        ? null
        : DateTime.tryParse(r.get<String>('picked_up_at', '')),
    clientName: clientUser == null
        ? ''
        : [
            clientUser.get<String>('last_name', ''),
            clientUser.get<String>('first_name', ''),
          ].where((s) => s.isNotEmpty).join(' '),
    weaponName: weapon?.get<String>('name', '') ?? '',
    storeName: store?.get<String>('name', '') ?? '',
    price: weapon?.get<int>('price', 0) ?? 0,
  );
}

/// PocketBase (в отличие от armory_api) не даёт клиенту межколлекционных
/// транзакций через REST — списание остатка при заказе делается отдельным
/// запросом после создания заказа, не атомарно в одной транзакции с ним.
/// При гонке двух одновременных заказов на последнюю единицу теоретически
/// возможен уход остатка в 0 у обоих раньше, чем каждый успеет списать —
/// осознанное упрощение платформы, задокументировано и в отчёте.
class PbOrderRepository implements OrderRepository {
  PbOrderRepository(this._pb);
  final PocketBase _pb;

  static const _expand = 'client.user,weapon,store';

  @override
  Future<PageResult<Order>> find({int page = 1, int size = 10}) => guard(() async {
    final result = await _pb.collection('orders').getList(
      page: page,
      perPage: size,
      filter: 'is_deleted = false',
      sort: '-created',
      expand: _expand,
    );
    return PageResult<Order>(
      items: result.items.map(_fromRecord).toList(),
      page: result.page,
      size: result.perPage,
      total: result.totalItems,
    );
  });

  @override
  Future<Order> create({required String weaponId, required String storeId}) => guard(() async {
    final weapon = await _pb.collection('weapons').getOne(weaponId, expand: 'categories');
    final stock = weapon.get<int>('stock_available', 0);
    if (stock <= 0) {
      throw const ConflictException('Нет в наличии.');
    }
    final client = await _pb
        .collection('clients')
        .getFirstListItem(_pb.filter('user = {:u}', {'u': _pb.authStore.record?.id}));

    // Предварительная (не единственная — сервер перепроверяет то же самое
    // через createRule, см. pb_migrations) проверка лицензии — нужна только
    // ради понятного сообщения об ошибке: сам PocketBase на отказе правила
    // возвращает общий "Failed to create record." без деталей.
    final requiredTypes = (weapon.get<List<RecordModel>>('expand.categories', const []))
        .map((c) => c.get<String>('license_type', 'other'))
        .toSet();
    License? license;
    try {
      final licenseRecord = await _pb
          .collection('licenses')
          .getFirstListItem(_pb.filter('client = {:c}', {'c': client.id}));
      license = License(
        id: licenseRecord.id,
        clientId: client.id,
        number: licenseRecord.get<String>('number', ''),
        type: licenseRecord.get<String>('type', 'other'),
        issuedAt: DateTime.tryParse(licenseRecord.get<String>('issued_at', '')) ?? DateTime(1970),
        expiresAt: DateTime.tryParse(licenseRecord.get<String>('expires_at', '')) ?? DateTime(1970),
      );
    } on ClientException {
      license = null; // лицензии ещё нет — сообщение ниже это учитывает
    }
    if (license == null) {
      throw const ConflictException(
        'У вас нет оформленной лицензии — обратитесь к продавцу.',
      );
    }
    if (license.isExpired) {
      throw const ConflictException('Срок действия вашей лицензии истёк.');
    }
    if (!requiredTypes.contains(license.type)) {
      throw ConflictException(
        'Ваша лицензия (${license.typeLabel}) не покрывает категорию этого оружия.',
      );
    }

    final record = await _pb.collection('orders').create(
      body: {
        'client': client.id,
        'weapon': weaponId,
        'store': storeId,
        'status': 'ordered',
      },
      expand: _expand,
    );
    await _pb.collection('weapons').update(weaponId, body: {'stock_available': stock - 1});
    return _fromRecord(record);
  });

  @override
  Future<Order> cancel(String id) => guard(() async {
    final order = await _pb.collection('orders').getOne(id);
    final record = await _pb
        .collection('orders')
        .update(id, body: {'status': 'cancelled'}, expand: _expand);
    final weapon = await _pb.collection('weapons').getOne(order.get<String>('weapon', ''));
    await _pb.collection('weapons').update(
      weapon.id,
      body: {'stock_available': weapon.get<int>('stock_available', 0) + 1},
    );
    return _fromRecord(record);
  });

  @override
  Future<Order> pickup(String id, String serialNumber) => guard(() async {
    final record = await _pb.collection('orders').update(
      id,
      body: {
        'status': 'picked_up',
        'serial_number': serialNumber,
        'picked_up_at': DateTime.now().toUtc().toIso8601String(),
      },
      expand: _expand,
    );
    return _fromRecord(record);
  });
}
