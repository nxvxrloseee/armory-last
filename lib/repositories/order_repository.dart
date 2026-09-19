import '../models/order.dart';
import '../models/page_result.dart';

abstract interface class OrderRepository {
  Future<PageResult<Order>> find({int page = 1, int size = 10});

  Future<Order> create({required String weaponId, required String storeId});

  Future<Order> cancel(String id);
  Future<Order> pickup(String id, String serialNumber);
}
