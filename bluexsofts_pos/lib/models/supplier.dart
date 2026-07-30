class Supplier {
  final String id;
  final String userId;
  final String supplierName;
  final String businessName;
  final String? gstNumber;
  final String? panNumber;
  final String? bankAccountNo;
  final String? bankName;
  final String? ifscCode;
  final String phone;
  final String email;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final double totalSalesValue;
  final double totalPayments;
  final double pendingBalance;
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;

  Supplier({
    required this.id,
    required this.userId,
    required this.supplierName,
    required this.businessName,
    this.gstNumber,
    this.panNumber,
    this.bankAccountNo,
    this.bankName,
    this.ifscCode,
    required this.phone,
    required this.email,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    this.totalSalesValue = 0,
    this.totalPayments = 0,
    this.pendingBalance = 0,
    this.isVerified = false,
    this.isActive = true,
    required this.createdAt,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] as String,
      userId: json['userId'] as String,
      supplierName: json['supplierName'] as String? ?? '',
      businessName: json['businessName'] as String? ?? '',
      gstNumber: json['gstNumber'] as String?,
      panNumber: json['panNumber'] as String?,
      bankAccountNo: json['bankAccountNo'] as String?,
      bankName: json['bankName'] as String?,
      ifscCode: json['ifscCode'] as String?,
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
      totalSalesValue: (json['totalSalesValue'] as num?)?.toDouble() ?? 0,
      totalPayments: (json['totalPayments'] as num?)?.toDouble() ?? 0,
      pendingBalance: (json['pendingBalance'] as num?)?.toDouble() ?? 0,
      isVerified: json['isVerified'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'supplierName': supplierName,
    'businessName': businessName,
    'gstNumber': gstNumber,
    'panNumber': panNumber,
    'bankAccountNo': bankAccountNo,
    'bankName': bankName,
    'ifscCode': ifscCode,
    'phone': phone,
    'email': email,
    'address': address,
    'city': city,
    'state': state,
    'pincode': pincode,
    'totalSalesValue': totalSalesValue,
    'totalPayments': totalPayments,
    'pendingBalance': pendingBalance,
    'isVerified': isVerified,
    'isActive': isActive,
  };
}
