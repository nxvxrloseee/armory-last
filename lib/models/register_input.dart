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
