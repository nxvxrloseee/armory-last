/// Тело регистрации — покупатель (единственная роль, доступная для
/// самостоятельной регистрации; продавца/админа заводит только уже
/// залогиненный админ — см. armory_last/pocketbase/README.md,
/// `users.createRule`).
///
/// В отличие от ПР5 тут нет паспортных данных/лицензии при регистрации:
/// лицензию на оружие выписывает продавец очно (это отдельная сущность
/// [License], создать её может только seller+ — самому покупателю
/// назначить себе лицензию через форму регистрации было бы бессмысленно).
class RegisterInput {
  const RegisterInput({
    required this.email,
    required this.password,
    required this.lastName,
    required this.firstName,
    this.patronymic,
    required this.phone,
  });

  final String email;
  final String password;
  final String lastName;
  final String firstName;
  final String? patronymic;
  final String phone;
}
