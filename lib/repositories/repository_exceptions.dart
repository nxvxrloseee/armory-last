/// Значение поля [field] должно быть уникальным (SKU оружия, email
/// покупателя), но уже занято другой записью. Форма ловит это исключение
/// после отправки и показывает [message] под соответствующим полем — так
/// же, как обычную ошибку validator, а не общим баннером.
class UniqueConstraintException implements Exception {
  final String field;
  final String message;
  const UniqueConstraintException(this.field, this.message);

  @override
  String toString() => message;
}

/// Запись нельзя удалить: на неё ссылаются другие записи ([referencingCount]
/// штук). Экран показывает [message] вместо выполнения удаления.
class ReferentialIntegrityException implements Exception {
  final int referencingCount;
  final String message;
  const ReferentialIntegrityException(this.referencingCount, this.message);

  @override
  String toString() => message;
}
