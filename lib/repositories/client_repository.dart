import '../models/client.dart';
import '../models/client_query.dart';
import 'list_repository.dart';

abstract interface class ClientRepository
    implements ListRepository<Client, ClientQuery> {
  Future<Client?> findById(String id);

  Future<Client> update(Client client);

  Future<void> softDelete(String id);
  Future<void> hardDelete(String id);
  Future<void> restore(String id);
}
