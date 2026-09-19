class Manufacturer {
  final String id;
  final String name;
  final String country;
  final int founded;
  final DateTime? deletedAt;

  const Manufacturer({
    required this.id,
    required this.name,
    required this.country,
    required this.founded,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Manufacturer copyWith({
    String? name,
    String? country,
    int? founded,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Manufacturer(
      id: id,
      name: name ?? this.name,
      country: country ?? this.country,
      founded: founded ?? this.founded,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'country': country,
    'founded': founded,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Manufacturer.fromJson(Map<String, dynamic> json) => Manufacturer(
    id: json['id']?.toString() ?? '',
    name: json['name'] as String? ?? '',
    country: json['country'] as String? ?? '',
    founded: json['founded'] as int? ?? 0,
    deletedAt: json['deletedAt'] == null
        ? null
        : DateTime.parse(json['deletedAt'] as String),
  );
}
