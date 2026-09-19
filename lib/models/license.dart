class License {
  final String id;
  final String clientId;
  final String number;
  final String type;
  final DateTime issuedAt;
  final DateTime expiresAt;

  const License({
    required this.id,
    required this.clientId,
    required this.number,
    required this.type,
    required this.issuedAt,
    required this.expiresAt,
  });

  bool get isExpired => expiresAt.isBefore(DateTime.now());

  static const typeLabels = {
    'rifle': 'Нарезное',
    'shotgun': 'Гладкоствольное',
    'pistol': 'Пистолет',
    'other': 'Прочее',
  };

  String get typeLabel => typeLabels[type] ?? type;

  License copyWith({
    String? number,
    String? type,
    DateTime? issuedAt,
    DateTime? expiresAt,
  }) {
    return License(
      id: id,
      clientId: clientId,
      number: number ?? this.number,
      type: type ?? this.type,
      issuedAt: issuedAt ?? this.issuedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'clientId': clientId,
    'number': number,
    'type': type,
    'issuedAt': issuedAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
  };

  factory License.fromJson(Map<String, dynamic> json) => License(
    id: json['id']?.toString() ?? '',
    clientId: json['clientId']?.toString() ?? '',
    number: json['number'] as String? ?? '',
    type: json['type'] as String? ?? 'other',
    issuedAt:
        DateTime.tryParse(json['issuedAt']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
    expiresAt:
        DateTime.tryParse(json['expiresAt']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );
}
