class Store {
  final String id;
  final String name;
  final String address;
  final DateTime? deletedAt;

  const Store({
    required this.id,
    required this.name,
    required this.address,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Store copyWith({
    String? name,
    String? address,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Store(
      id: id,
      name: name ?? this.name,
      address: address ?? this.address,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Store.fromJson(Map<String, dynamic> json) => Store(
    id: json['id']?.toString() ?? '',
    name: json['name'] as String? ?? '',
    address: json['address'] as String? ?? '',
    deletedAt: json['deletedAt'] == null
        ? null
        : DateTime.parse(json['deletedAt'] as String),
  );
}
