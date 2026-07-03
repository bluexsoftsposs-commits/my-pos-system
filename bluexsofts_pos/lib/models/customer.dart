class Customer {
  final String id;
  final String shopId;
  final String name;
  final String phone;
  final double totalOwed;
  final double totalPaid;
  final double balance;
  final DateTime? lastPaymentAt;
  final DateTime createdAt;

  Customer({
    required this.id,
    required this.shopId,
    required this.name,
    this.phone = '',
    this.totalOwed = 0,
    this.totalPaid = 0,
    this.balance = 0,
    this.lastPaymentAt,
    required this.createdAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      shopId: json['shopId'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String? ?? '',
      totalOwed: (json['totalOwed'] as num?)?.toDouble() ?? 0,
      totalPaid: (json['totalPaid'] as num?)?.toDouble() ?? 0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      lastPaymentAt: json['lastPaymentAt'] != null ? DateTime.parse(json['lastPaymentAt'] as String) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
