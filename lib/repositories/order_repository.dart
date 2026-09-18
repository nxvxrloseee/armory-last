import '../models/order.dart';
import '../models/page_result.dart';

/// Список заказов уже отфильтрован по роли на стороне PocketBase
/// (`orders.listRule`: покупатель видит только свои) — клиенту не нужен
/// собственный Query-класс, как у остальных сущностей, только страница.
abstract interface class OrderRepository {
  Future<PageResult<Order>> find({int page = 1, int size = 10});

  /// Бросает [ConflictException]/[ValidationException], если у покупателя
  /// нет действующей лицензии нужного типа (см. armory_last/pocketbase/
  /// README.md — доменное правило проверяется сервером, не клиентом).
  Future<Order> create({required String weaponId, required String storeId});

  Future<Order> cancel(String id);
  Future<Order> pickup(String id, String serialNumber);
}
