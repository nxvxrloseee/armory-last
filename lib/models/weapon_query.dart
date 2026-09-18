/// Все условия отбора собраны в один неизменяемый объект — так их удобно
/// передавать одним аргументом и целиком класть в query-параметры адреса,
/// например: `/weapons?search=falcon&categoryId=abc123&sort=year,desc&page=3`.
class WeaponQuery {
  final String search;
  final String? categoryId;
  final String? manufacturerId;
  final String? designerId;
  final int? yearFrom;
  final int? yearTo;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const WeaponQuery({
    this.search = '',
    this.categoryId,
    this.manufacturerId,
    this.designerId,
    this.yearFrom,
    this.yearTo,
    this.sortField = 'name',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  static const _unset = Object();

  /// Приём с сигнальной константой [_unset] позволяет отличить «параметр не
  /// передан» (оставить как есть) от «передан null» (сбросить фильтр).
  WeaponQuery copyWith({
    String? search,
    Object? categoryId = _unset,
    Object? manufacturerId = _unset,
    Object? designerId = _unset,
    Object? yearFrom = _unset,
    Object? yearTo = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return WeaponQuery(
      search: search ?? this.search,
      categoryId: identical(categoryId, _unset)
          ? this.categoryId
          : categoryId as String?,
      manufacturerId: identical(manufacturerId, _unset)
          ? this.manufacturerId
          : manufacturerId as String?,
      designerId: identical(designerId, _unset)
          ? this.designerId
          : designerId as String?,
      yearFrom: identical(yearFrom, _unset) ? this.yearFrom : yearFrom as int?,
      yearTo: identical(yearTo, _unset) ? this.yearTo : yearTo as int?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      // Любое изменение условий отбора возвращает на первую страницу: иначе
      // пользователь на седьмой странице после ввода поиска увидит пустой
      // экран. Единственное место, которое осознанно передаёт page, —
      // сама пагинация.
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  Map<String, String> toQueryParameters() {
    final map = <String, String>{};
    if (search.isNotEmpty) map['search'] = search;
    if (categoryId != null) map['categoryId'] = categoryId!;
    if (manufacturerId != null) map['manufacturerId'] = manufacturerId!;
    if (designerId != null) map['designerId'] = designerId!;
    if (yearFrom != null) map['yearFrom'] = '$yearFrom';
    if (yearTo != null) map['yearTo'] = '$yearTo';
    if (sortField != 'name' || !sortAscending) {
      map['sort'] = '$sortField,${sortAscending ? 'asc' : 'desc'}';
    }
    if (page != 1) map['page'] = '$page';
    if (size != 10) map['size'] = '$size';
    if (includeDeleted) map['deleted'] = '1';
    return map;
  }

  factory WeaponQuery.fromQueryParameters(Map<String, String> q) {
    final sortRaw = q['sort']?.split(',');
    return WeaponQuery(
      search: q['search'] ?? '',
      categoryId: q['categoryId'],
      manufacturerId: q['manufacturerId'],
      designerId: q['designerId'],
      yearFrom: int.tryParse(q['yearFrom'] ?? ''),
      yearTo: int.tryParse(q['yearTo'] ?? ''),
      sortField:
          (sortRaw != null && sortRaw.isNotEmpty && sortRaw[0].isNotEmpty)
          ? sortRaw[0]
          : 'name',
      sortAscending:
          !(sortRaw != null && sortRaw.length > 1 && sortRaw[1] == 'desc'),
      page: int.tryParse(q['page'] ?? '') ?? 1,
      size: int.tryParse(q['size'] ?? '') ?? 10,
      includeDeleted: q['deleted'] == '1',
    );
  }

  String get _encoded {
    final map = toQueryParameters();
    final keys = map.keys.toList()..sort();
    return keys.map((k) => '$k=${map[k]}').join('&');
  }

  @override
  bool operator ==(Object other) =>
      other is WeaponQuery && other._encoded == _encoded;

  @override
  int get hashCode => _encoded.hashCode;
}
