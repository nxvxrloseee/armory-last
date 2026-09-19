import 'package:pocketbase/pocketbase.dart';

import '../core/api_exceptions.dart';
import '../models/role.dart';

class AdminUserRow {
  const AdminUserRow({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
  });
  final String id;
  final String email;
  final String fullName;
  final Role role;

  factory AdminUserRow.fromRecord(RecordModel r) => AdminUserRow(
    id: r.id,
    email: r.get<String>('email', ''),
    fullName: [
      r.get<String>('last_name', ''),
      r.get<String>('first_name', ''),
      r.get<String>('patronymic', ''),
    ].where((s) => s.isNotEmpty).join(' '),
    role: Role.fromWire(r.get<String>('role', 'buyer')),
  );
}

class AdminApi {
  AdminApi(this._pb);
  final PocketBase _pb;

  Future<List<AdminUserRow>> listUsers() => guard(() async {
    final result = await _pb
        .collection('users')
        .getList(perPage: 200, sort: 'last_name');
    return result.items.map(AdminUserRow.fromRecord).toList();
  });

  Future<void> setRole(String userId, Role role) => guard(
    () => _pb.collection('users').update(
      userId,
      body: {'role': role.wireValue},
    ),
  );

  Future<Map<String, dynamic>> stats() => guard(() async {
    Future<int> count(String collection, [String? filter]) async {
      final result = await _pb
          .collection(collection)
          .getList(perPage: 1, filter: filter ?? 'is_deleted = false');
      return result.totalItems;
    }

    final results = await Future.wait([
      count('weapons'),
      count('manufacturers'),
      count('categories'),
      count('designers'),
      count('clients'),
      count('orders', 'status = "ordered"'),
      count('orders', 'status = "picked_up"'),
      count('users', ''),
    ]);
    return {
      'weapons': results[0],
      'manufacturers': results[1],
      'categories': results[2],
      'designers': results[3],
      'clients': results[4],
      'ordersActive': results[5],
      'ordersPickedUp': results[6],
      'usersTotal': results[7],
    };
  });
}
