/// Покупатель. Лицензия — теперь настоящая отдельная сущность ([License]),
/// не свёрнута в поля Client (в отличие от ПР1-6): итоговый проект требует
/// честную межсущностную связь 1:1, а не группу полей внутри владельца.
///
/// [fullName]/[email] не хранятся в коллекции `clients` — они приходят из
/// связанного аккаунта `users` (1:1 через [userId], читается через
/// `expand=user`) и попадают сюда только для отображения; при записи
/// (toJson) они не отправляются, чтобы не пытаться перезаписать чужую
/// коллекцию через это тело запроса.
class Client {
  final String id;
  final String userId;
  final String fullName;
  final String email;
  final String phone;
  final DateTime? deletedAt;

  const Client({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Client copyWith({
    String? phone,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Client(
      id: id,
      userId: userId,
      fullName: fullName,
      email: email,
      phone: phone ?? this.phone,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'userId': userId, 'phone': phone};

  factory Client.fromJson(Map<String, dynamic> json) => Client(
    id: json['id']?.toString() ?? '',
    userId: json['userId']?.toString() ?? '',
    fullName: json['fullName'] as String? ?? '',
    email: json['email'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    deletedAt: json['deletedAt'] == null
        ? null
        : DateTime.parse(json['deletedAt'] as String),
  );
}
