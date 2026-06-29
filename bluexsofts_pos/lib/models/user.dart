class AppUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final String shopId;
  final bool isActive;
  final bool emailVerified;
  final DateTime? createdAt;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.shopId,
    this.isActive = true,
    this.emailVerified = false,
    this.createdAt,
  });

  bool get isAdmin => role == 'ADMIN';
  bool get isSuperAdmin => role == 'SUPER_ADMIN';

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      shopId: json['shopId'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      emailVerified: json['emailVerified'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'shopId': shopId,
    'isActive': isActive,
    'emailVerified': emailVerified,
  };
}

class Shop {
  final String id;
  final String shopName;
  final String subscriptionPlan;
  final String subscriptionStatus;
  final DateTime? subscriptionEndsAt;
  final bool isActive;

  Shop({
    required this.id,
    required this.shopName,
    this.subscriptionPlan = 'NONE',
    this.subscriptionStatus = 'NONE',
    this.subscriptionEndsAt,
    this.isActive = true,
  });

  bool get hasActiveSubscription => subscriptionStatus == 'ACTIVE';
  bool get requiresPayment => subscriptionStatus == 'NONE' || subscriptionStatus == 'EXPIRED';

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'] as String,
      shopName: json['shopName'] as String,
      subscriptionPlan: json['subscriptionPlan'] as String? ?? 'NONE',
      subscriptionStatus: json['subscriptionStatus'] as String? ?? 'NONE',
      subscriptionEndsAt: json['subscriptionEndsAt'] != null
          ? DateTime.parse(json['subscriptionEndsAt'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'shopName': shopName,
    'subscriptionPlan': subscriptionPlan,
    'subscriptionStatus': subscriptionStatus,
    'subscriptionEndsAt': subscriptionEndsAt?.toIso8601String(),
    'isActive': isActive,
  };
}

class Plan {
  final String id;
  final String name;
  final int price;
  final String priceLabel;
  final List<String> features;
  final bool popular;

  Plan({
    required this.id,
    required this.name,
    required this.price,
    required this.priceLabel,
    required this.features,
    this.popular = false,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: json['id'] as String,
      name: json['name'] as String,
      price: json['price'] as int,
      priceLabel: json['priceLabel'] as String,
      features: (json['features'] as List).cast<String>(),
      popular: json['popular'] as bool? ?? false,
    );
  }
}
