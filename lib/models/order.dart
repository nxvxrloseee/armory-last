class Order {
  const Order({
    required this.id,
    required this.clientId,
    required this.weaponId,
    required this.storeId,
    required this.status,
    this.serialNumber,
    required this.createdAt,
    this.pickedUpAt,
    required this.clientName,
    required this.weaponName,
    required this.storeName,
    required this.price,
  });

  final String id;
  final String clientId;
  final String weaponId;
  final String storeId;
  final String status; // ordered | picked_up | cancelled
  final String? serialNumber;
  final DateTime createdAt;
  final DateTime? pickedUpAt;
  final String clientName;
  final String weaponName;
  final String storeName;
  final int price;

  bool get isOrdered => status == 'ordered';

  String get statusLabel => switch (status) {
    'ordered' => 'Оформлен',
    'picked_up' => 'Выдан',
    'cancelled' => 'Отменён',
    _ => status,
  };

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id']?.toString() ?? '',
    clientId: json['clientId']?.toString() ?? '',
    weaponId: json['weaponId']?.toString() ?? '',
    storeId: json['storeId']?.toString() ?? '',
    status: json['status']?.toString() ?? 'ordered',
    serialNumber: json['serialNumber']?.toString(),
    createdAt:
        DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
        DateTime.now(),
    pickedUpAt: json['pickedUpAt'] == null
        ? null
        : DateTime.tryParse(json['pickedUpAt'].toString()),
    clientName: json['clientName']?.toString() ?? '',
    weaponName: json['weaponName']?.toString() ?? '',
    storeName: json['storeName']?.toString() ?? '',
    price: json['price'] is int ? json['price'] as int : 0,
  );
}
