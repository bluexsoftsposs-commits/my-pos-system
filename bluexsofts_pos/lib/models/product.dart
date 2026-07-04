class Product {
  final String id;
  final String shopId;
  final String name;
  final String description;
  final double price;
  int stock;
  final String sku;
  final String category;
  final String imageUrl;
  final String? barcode;
  int lowStockThreshold;
  final bool isActive;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.shopId,
    required this.name,
    this.description = '',
    required this.price,
    this.stock = 0,
    this.sku = '',
    this.category = 'General',
    this.imageUrl = '',
    this.barcode,
    this.lowStockThreshold = 5,
    this.isActive = true,
    required this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      shopId: json['shopId'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      stock: json['stock'] as int? ?? 0,
      sku: json['sku'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      imageUrl: json['imageUrl'] as String? ?? '',
      barcode: json['barcode'] as String?,
      lowStockThreshold: json['lowStockThreshold'] as int? ?? 5,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'shopId': shopId,
    'name': name,
    'description': description,
    'price': price,
    'stock': stock,
    'sku': sku,
    'category': category,
    'imageUrl': imageUrl,
    'barcode': barcode,
    'lowStockThreshold': lowStockThreshold,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
  };

  Product copyWith({
    String? name,
    String? description,
    double? price,
    int? stock,
    String? sku,
    String? category,
    String? imageUrl,
    String? barcode,
    int? lowStockThreshold,
    bool? isActive,
  }) {
    return Product(
      id: id,
      shopId: shopId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      barcode: barcode ?? this.barcode,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}
