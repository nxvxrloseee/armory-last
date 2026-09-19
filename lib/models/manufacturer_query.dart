class ManufacturerQuery {
  final String search;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const ManufacturerQuery({
    this.search = '',
    this.sortField = 'name',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  ManufacturerQuery copyWith({
    String? search,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return ManufacturerQuery(
      search: search ?? this.search,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  Map<String, String> toQueryParameters() {
    final map = <String, String>{};
    if (search.isNotEmpty) map['search'] = search;
    if (sortField != 'name' || !sortAscending) {
      map['sort'] = '$sortField,${sortAscending ? 'asc' : 'desc'}';
    }
    if (page != 1) map['page'] = '$page';
    if (size != 10) map['size'] = '$size';
    if (includeDeleted) map['deleted'] = '1';
    return map;
  }

  factory ManufacturerQuery.fromQueryParameters(Map<String, String> q) {
    final sortRaw = q['sort']?.split(',');
    return ManufacturerQuery(
      search: q['search'] ?? '',
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
      other is ManufacturerQuery && other._encoded == _encoded;

  @override
  int get hashCode => _encoded.hashCode;
}
