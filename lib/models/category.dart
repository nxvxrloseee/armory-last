class Category {
  final String id;
  final String name;
  final String licenseType;
  final DateTime? deletedAt;

  const Category({
    required this.id,
    required this.name,
    required this.licenseType,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Category copyWith({
    String? name,
    String? licenseType,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      licenseType: licenseType ?? this.licenseType,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'licenseType': licenseType,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id']?.toString() ?? '',
    name: json['name'] as String? ?? '',
    licenseType: json['licenseType'] as String? ?? 'other',
    deletedAt: json['deletedAt'] == null
        ? null
        : DateTime.parse(json['deletedAt'] as String),
  );
}
