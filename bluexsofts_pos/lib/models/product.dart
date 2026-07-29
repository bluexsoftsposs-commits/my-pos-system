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

  // Grocery
  final String? unitType;
  final double? unitValue;

  // Electronics
  final String? imei;
  final int? warrantyMonths;
  final String? brand;
  final String? model;

  // Restaurant
  final bool isMenuItem;
  final String? recipe;

  // Pharmacy
  final String? batchNumber;
  final DateTime? expiryDate;
  final String? manufacturer;
  final String? composition;
  final String? dosageForm;
  final String? packing;
  final bool isControlled;
  final bool isPrescriptionOnly;

  // Clothing
  final String? size;
  final String? color;
  final String? season;

  // Supplier
  final String? supplierId;

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
    this.unitType,
    this.unitValue,
    this.imei,
    this.warrantyMonths,
    this.brand,
    this.model,
    this.isMenuItem = false,
    this.recipe,
    this.batchNumber,
    this.expiryDate,
    this.manufacturer,
    this.composition,
    this.dosageForm,
    this.packing,
    this.isControlled = false,
    this.isPrescriptionOnly = false,
    this.size,
    this.color,
    this.season,
    this.supplierId,
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
      unitType: json['unitType'] as String?,
      unitValue: (json['unitValue'] as num?)?.toDouble(),
      imei: json['imei'] as String?,
      warrantyMonths: json['warrantyMonths'] as int?,
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      isMenuItem: json['isMenuItem'] as bool? ?? false,
      recipe: json['recipe'] as String?,
      batchNumber: json['batchNumber'] as String?,
      expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate'] as String) : null,
      manufacturer: json['manufacturer'] as String?,
      composition: json['composition'] as String?,
      dosageForm: json['dosageForm'] as String?,
      packing: json['packing'] as String?,
      isControlled: json['isControlled'] as bool? ?? false,
      isPrescriptionOnly: json['isPrescriptionOnly'] as bool? ?? false,
      size: json['size'] as String?,
      color: json['color'] as String?,
      season: json['season'] as String?,
      supplierId: json['supplierId'] as String?,
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
    if (unitType != null) 'unitType': unitType,
    if (unitValue != null) 'unitValue': unitValue,
    if (imei != null) 'imei': imei,
    if (warrantyMonths != null) 'warrantyMonths': warrantyMonths,
    if (brand != null) 'brand': brand,
    if (model != null) 'model': model,
    'isMenuItem': isMenuItem,
    if (recipe != null) 'recipe': recipe,
    if (batchNumber != null) 'batchNumber': batchNumber,
    if (expiryDate != null) 'expiryDate': expiryDate!.toIso8601String(),
    if (manufacturer != null) 'manufacturer': manufacturer,
    if (composition != null) 'composition': composition,
    if (dosageForm != null) 'dosageForm': dosageForm,
    if (packing != null) 'packing': packing,
    'isControlled': isControlled,
    'isPrescriptionOnly': isPrescriptionOnly,
    if (size != null) 'size': size,
    if (color != null) 'color': color,
    if (season != null) 'season': season,
    if (supplierId != null) 'supplierId': supplierId,
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
    String? unitType,
    double? unitValue,
    String? imei,
    int? warrantyMonths,
    String? brand,
    String? model,
    bool? isMenuItem,
    String? recipe,
    String? batchNumber,
    DateTime? expiryDate,
    String? manufacturer,
    String? composition,
    String? dosageForm,
    String? packing,
    bool? isControlled,
    bool? isPrescriptionOnly,
    String? size,
    String? color,
    String? season,
    String? supplierId,
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
      unitType: unitType ?? this.unitType,
      unitValue: unitValue ?? this.unitValue,
      imei: imei ?? this.imei,
      warrantyMonths: warrantyMonths ?? this.warrantyMonths,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      isMenuItem: isMenuItem ?? this.isMenuItem,
      recipe: recipe ?? this.recipe,
      batchNumber: batchNumber ?? this.batchNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      manufacturer: manufacturer ?? this.manufacturer,
      composition: composition ?? this.composition,
      dosageForm: dosageForm ?? this.dosageForm,
      packing: packing ?? this.packing,
      isControlled: isControlled ?? this.isControlled,
      isPrescriptionOnly: isPrescriptionOnly ?? this.isPrescriptionOnly,
      size: size ?? this.size,
      color: color ?? this.color,
      season: season ?? this.season,
      supplierId: supplierId ?? this.supplierId,
    );
  }
}
