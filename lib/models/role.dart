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
