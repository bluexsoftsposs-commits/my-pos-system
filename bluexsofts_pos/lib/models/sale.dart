import 'product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get subtotal => product.price * quantity;

  Map<String, dynamic> toJson() => {
    'productId': product.id,
    'quantity': quantity,
    'price': product.price,
  };
}

class Sale {
  final String id;
  final String shopId;
  final String userId;
  final double total;
  final double subtotal;
  final double tax;
  final double discount;
  final String paymentMethod;
  final String status;
  final String notes;
  final DateTime createdAt;
  final List<SaleItem> saleItems;
  final Map<String, dynamic>? user;

  Sale({
    required this.id,
    required this.shopId,
    required this.userId,
    required this.total,
    required this.subtotal,
    this.tax = 0,
    this.discount = 0,
    this.paymentMethod = 'CASH',
    this.status = 'COMPLETED',
    this.notes = '',
    required this.createdAt,
    this.saleItems = const [],
    this.user,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'] as String,
      shopId: json['shopId'] as String,
      userId: json['userId'] as String,
      total: (json['total'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
      tax: (json['tax'] as num?)?.toDouble() ?? 0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['paymentMethod'] as String? ?? 'CASH',
      status: json['status'] as String? ?? 'COMPLETED',
      notes: json['notes'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      saleItems: (json['saleItems'] as List<dynamic>?)
          ?.map((e) => SaleItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      user: json['user'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'shopId': shopId,
    'userId': userId,
    'total': total,
    'subtotal': subtotal,
    'tax': tax,
    'discount': discount,
    'paymentMethod': paymentMethod,
    'status': status,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
  };
}

class SaleItem {
  final String id;
  final String productId;
  final int quantity;
  final double price;
  final double subtotal;
  final Map<String, dynamic>? product;

  SaleItem({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.price,
    required this.subtotal,
    this.product,
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      id: json['id'] as String,
      productId: json['productId'] as String,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
      product: json['product'] as Map<String, dynamic>?,
    );
  }
}

class OfflineSale {
  final String offlineId;
  final List<Map<String, dynamic>> items;
  final String paymentMethod;
  final double tax;
  final double discount;
  final String notes;
  final String createdAt;

  OfflineSale({
    required this.offlineId,
    required this.items,
    this.paymentMethod = 'CASH',
    this.tax = 0,
    this.discount = 0,
    this.notes = '',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'offlineId': offlineId,
    'items': items,
    'paymentMethod': paymentMethod,
    'tax': tax,
    'discount': discount,
    'notes': notes,
    'createdAt': createdAt,
  };

  factory OfflineSale.fromJson(Map<String, dynamic> json) {
    return OfflineSale(
      offlineId: json['offlineId'] as String,
      items: (json['items'] as List).cast<Map<String, dynamic>>(),
      paymentMethod: json['paymentMethod'] as String? ?? 'CASH',
      tax: (json['tax'] as num?)?.toDouble() ?? 0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      notes: json['notes'] as String? ?? '',
      createdAt: json['createdAt'] as String,
    );
  }
}
