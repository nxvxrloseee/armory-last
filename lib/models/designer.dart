class Designer {
  final String id;
  final String fullName;
  final String country;
  final int activeSince;
  final DateTime? deletedAt;

  const Designer({
    required this.id,
    required this.fullName,
    required this.country,
    required this.activeSince,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Designer copyWith({
    String? fullName,
    String? country,
    int? activeSince,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Designer(
      id: id,
      fullName: fullName ?? this.fullName,
      country: country ?? this.country,
      activeSince: activeSince ?? this.activeSince,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'country': country,
    'activeSince': activeSince,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Designer.fromJson(Map<String, dynamic> json) => Designer(
    id: json['id']?.toString() ?? '',
    fullName: json['fullName'] as String? ?? '',
    country: json['country'] as String? ?? '',
    activeSince: json['activeSince'] as int? ?? 0,
    deletedAt: json['deletedAt'] == null
        ? null
        : DateTime.parse(json['deletedAt'] as String),
  );
}
