import '../models/client.dart';
import '../models/client_query.dart';
import 'list_repository.dart';

/// В отличие от ПР1-6 здесь нет `create()`: запись `clients` неразрывно
/// связана 1:1 с `users` (см. models/client.dart) и появляется только через
/// самостоятельную регистрацию (AuthNotifier.register) — отдельного пути
/// «продавец завёл нового покупателя вручную» в этом домене больше нет.
abstract interface class ClientRepository
    implements ListRepository<Client, ClientQuery> {
  Future<Client?> findById(String id);

  /// Меняет только [Client.phone] — email/ФИО читаются из связанного users,
  /// не редактируются отсюда.
  Future<Client> update(Client client);

  Future<void> softDelete(String id);
  Future<void> hardDelete(String id);
  Future<void> restore(String id);
}
