class UniqueConstraintException implements Exception {
  final String field;
  final String message;
  const UniqueConstraintException(this.field, this.message);

  @override
  String toString() => message;
}

class ReferentialIntegrityException implements Exception {
  final int referencingCount;
  final String message;
  const ReferentialIntegrityException(this.referencingCount, this.message);

  @override
  String toString() => message;
}
