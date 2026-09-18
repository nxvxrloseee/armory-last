/// Три роли ПР5. Level даёт "не ниже такой-то роли" одним сравнением —
/// тот же приём, что и на сервере (см. armory_api/internal/auth/roles.go),
/// намеренно продублированный: клиентская сторона решает, что показать,
/// сервер — что разрешить, и это две разные, независимо написанные проверки.
enum Role {
  buyer('buyer', 1, 'Покупатель'),
  seller('seller', 2, 'Продавец'),
  admin('admin', 3, 'Администратор');

  const Role(this.wireValue, this.level, this.label);

  final String wireValue;
  final int level;
  final String label;

  static Role fromWire(String value) => Role.values.firstWhere(
    (r) => r.wireValue == value,
    orElse: () => Role.buyer,
  );
}
