import 'role.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.lastName,
    required this.firstName,
    this.patronymic,
    required this.role,
    this.clientId,
  });

  final String id;
  final String email;
  final String lastName;
  final String firstName;
  final String? patronymic;
  final Role role;
  final String? clientId;

  /// «Фамилия Имя Отчество» одной строкой — для отображения, не хранится.
  String get fullName => [
    lastName,
    firstName,
    if (patronymic != null && patronymic!.isNotEmpty) patronymic,
  ].join(' ');

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    lastName: json['lastName']?.toString() ?? '',
    firstName: json['firstName']?.toString() ?? '',
    patronymic: (json['patronymic'] as String?)?.isEmpty ?? true
        ? null
        : json['patronymic'] as String,
    role: Role.fromWire(json['role']?.toString() ?? 'buyer'),
    clientId: json['clientId']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'lastName': lastName,
    'firstName': firstName,
    if (patronymic != null) 'patronymic': patronymic,
    'role': role.wireValue,
    if (clientId != null) 'clientId': clientId,
  };
}
