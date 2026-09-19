class Weapon {
  final String id;
  final String name;
  final String sku;
  final int year;
  final String caliber;
  final String manufacturerId;
  final List<String> categoryIds;
  final List<String> designerIds;
  final int price;
  final int stockTotal;
  final int stockAvailable;
  final DateTime? deletedAt;

  const Weapon({
    required this.id,
    required this.name,
    required this.sku,
    required this.year,
    required this.caliber,
    required this.manufacturerId,
    required this.categoryIds,
    required this.designerIds,
    required this.price,
    required this.stockTotal,
    required this.stockAvailable,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Weapon copyWith({
    String? name,
    String? sku,
    int? year,
    String? caliber,
    String? manufacturerId,
    List<String>? categoryIds,
    List<String>? designerIds,
    int? price,
    int? stockTotal,
    int? stockAvailable,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Weapon(
      id: id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      year: year ?? this.year,
      caliber: caliber ?? this.caliber,
      manufacturerId: manufacturerId ?? this.manufacturerId,
      categoryIds: categoryIds ?? this.categoryIds,
      designerIds: designerIds ?? this.designerIds,
      price: price ?? this.price,
      stockTotal: stockTotal ?? this.stockTotal,
      stockAvailable: stockAvailable ?? this.stockAvailable,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sku': sku,
    'year': year,
    'caliber': caliber,
    'manufacturerId': manufacturerId,
    'categoryIds': categoryIds,
    'designerIds': designerIds,
    'price': price,
    'stockTotal': stockTotal,
    'stockAvailable': stockAvailable,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Weapon.fromJson(Map<String, dynamic> json) => Weapon(
    id: json['id']?.toString() ?? '',
    name: json['name'] as String? ?? '',
    sku: json['sku'] as String? ?? '',
    year: json['year'] as int? ?? 0,
    caliber: json['caliber'] as String? ?? '',
    manufacturerId: json['manufacturerId']?.toString() ?? '',
    categoryIds:
        (json['categoryIds'] as List?)?.map((e) => e.toString()).toList() ??
        const [],
    designerIds:
        (json['designerIds'] as List?)?.map((e) => e.toString()).toList() ??
        const [],
    price: json['price'] as int? ?? 0,
    stockTotal: json['stockTotal'] as int? ?? 0,
    stockAvailable: json['stockAvailable'] as int? ?? 0,
    deletedAt: json['deletedAt'] == null
        ? null
        : DateTime.parse(json['deletedAt'] as String),
  );
}
