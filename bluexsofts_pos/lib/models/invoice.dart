import 'sale.dart';

class Invoice {
  final String id;
  final String invoiceNumber;
  final String saleId;
  final String shopId;
  final String userId;
  final double total;
  final double subtotal;
  final double tax;
  final double discount;
  final String paymentMethod;
  final DateTime createdAt;
  final Sale? sale;
  final Map<String, dynamic>? user;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.saleId,
    required this.shopId,
    required this.userId,
    required this.total,
    required this.subtotal,
    this.tax = 0,
    this.discount = 0,
    this.paymentMethod = 'CASH',
    required this.createdAt,
    this.sale,
    this.user,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] as String,
      invoiceNumber: json['invoiceNumber'] as String,
      saleId: json['saleId'] as String,
      shopId: json['shopId'] as String,
      userId: json['userId'] as String,
      total: (json['total'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
      tax: (json['tax'] as num?)?.toDouble() ?? 0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['paymentMethod'] as String? ?? 'CASH',
      createdAt: DateTime.parse(json['createdAt'] as String),
      sale: json['sale'] != null ? Sale.fromJson(json['sale'] as Map<String, dynamic>) : null,
      user: json['user'] as Map<String, dynamic>?,
    );
  }
}
