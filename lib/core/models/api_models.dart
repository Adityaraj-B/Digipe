import 'dart:convert';

class AuthUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  
  // Optional location details synced from forms
  final String? house;
  final String? area;
  final String? city;
  final String? state;
  final String? pin;

  AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.house,
    this.area,
    this.city,
    this.state,
    this.pin,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['_id'] ?? json['id'] ?? '',
    name: json['name'] ?? '',
    email: json['email'] ?? '',
    phone: json['mobileNumber'] ?? json['phone'] ?? '',
    role: json['role'] ?? 'user',
    house: json['house'],
    area: json['area'],
    city: json['city'],
    state: json['state'],
    pin: json['pin'],
  );

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    'email': email,
    'mobileNumber': phone,
    'role': role,
    'house': house,
    'area': area,
    'city': city,
    'state': state,
    'pin': pin,
  };

  AuthUser copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? house,
    String? area,
    String? city,
    String? state,
    String? pin,
  }) {
    return AuthUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      house: house ?? this.house,
      area: area ?? this.area,
      city: city ?? this.city,
      state: state ?? this.state,
      pin: pin ?? this.pin,
    );
  }
}

class Category {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final String? image;
  final bool isActive;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.image,
    this.isActive = true,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['_id'] ?? json['id'] ?? '',
    name: json['name'] ?? '',
    description: json['description'],
    icon: json['icon'],
    image: json['image'],
    isActive: json['isActive'] ?? true,
  );
}

class Product {
  final String id;
  final String category;
  final String name;
  final Map<String, dynamic> pricingConfig;
  final String? shortDescription;
  final String? image;
  final List<String> features;
  final bool isActive;

  Product({
    required this.id,
    required this.category,
    required this.name,
    required this.pricingConfig,
    this.shortDescription,
    this.image,
    this.features = const [],
    this.isActive = true,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    var desc = json['description'] ?? '{}';
    Map<String, dynamic> config = {};
    try {
      if (desc is String) {
        config = jsonDecode(desc);
      } else {
        config = desc;
      }
    } catch (_) {}

    return Product(
      id: json['_id'] ?? json['id'] ?? '',
      category: json['category'] is Map ? (json['category']['_id'] ?? json['category']['id'] ?? '') : (json['category'] ?? ''),
      name: json['name'] ?? '',
      pricingConfig: config,
      shortDescription: json['shortDescription'],
      image: json['image'],
      features: List<String>.from(json['features'] ?? []),
      isActive: json['isActive'] ?? true,
    );
  }
}

class Plan {
  final String id;
  final String productId;
  final String name;
  final num coverageAmount;
  final num premium;
  final String premiumFrequency;
  final int durationMonths;
  final List<String> features;
  final List<String> benefits;

  Plan({
    required this.id,
    required this.productId,
    required this.name,
    required this.coverageAmount,
    required this.premium,
    required this.premiumFrequency,
    required this.durationMonths,
    this.features = const [],
    this.benefits = const [],
  });

  factory Plan.fromJson(Map<String, dynamic> json) => Plan(
    id: json['_id'] ?? json['id'] ?? '',
    productId: json['product'] is Map ? (json['product']['_id'] ?? json['product']['id'] ?? '') : (json['product'] ?? ''),
    name: json['name'] ?? '',
    coverageAmount: json['coverageAmount'] ?? 0,
    premium: json['premium'] ?? 0,
    premiumFrequency: json['premiumFrequency'] ?? 'YEARLY',
    durationMonths: json['duration'] ?? 12,
    features: List<String>.from(json['features'] ?? []),
    benefits: List<String>.from(json['benefits'] ?? []),
  );
}

class ProductField {
  final String id;
  final String productId;
  final String fieldName;
  final String fieldLabel;
  final String fieldType; // TEXT, FILE, CHECKBOX
  final String? placeholder;
  final bool isRequired;
  final int sortOrder;

  ProductField({
    required this.id,
    required this.productId,
    required this.fieldName,
    required this.fieldLabel,
    required this.fieldType,
    this.placeholder,
    this.isRequired = false,
    this.sortOrder = 0,
  });

  factory ProductField.fromJson(Map<String, dynamic> json) => ProductField(
    id: json['_id'] ?? json['id'] ?? '',
    productId: json['product'] is Map ? (json['product']['_id'] ?? json['product']['id'] ?? '') : (json['product'] ?? ''),
    fieldName: json['fieldName'] ?? '',
    fieldLabel: json['fieldLabel'] ?? '',
    fieldType: json['fieldType'] ?? 'TEXT',
    placeholder: json['placeholder'],
    isRequired: json['isRequired'] ?? false,
    sortOrder: json['sortOrder'] ?? 0,
  );
}

class OrderSummary {
  final String orderId;
  final String product;
  final String? applicationId;
  final String amount;
  final String date;
  final String status;
  final bool canClaim;
  final String? cashfreeOrderId;

  OrderSummary({
    required this.orderId,
    required this.product,
    required this.amount,
    this.applicationId,
    required this.date,
    required this.status,
    required this.canClaim,
    this.cashfreeOrderId,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    // NEW: application can arrive as a raw ObjectId string or a populated Map
    final rawApplication = json['application'];
    final applicationId = rawApplication is Map
        ? (rawApplication['_id'] ?? rawApplication['id'])?.toString()
        : rawApplication?.toString();

    return OrderSummary(
      orderId: json['_id'] ?? json['id'] ?? json['orderId'] ?? json['order_id'] ?? '',
      applicationId: applicationId, // NEW
      product: json['product'] is Map ? (json['product']['name'] ?? '') : (json['productName'] ?? json['product'] ?? ''),
      amount: json['totalAmount']?.toString() ?? json['amount']?.toString() ?? '',
      date: json['createdAt'] ?? json['date'] ?? '',
      status: json['status'] ?? '',
      canClaim: json['status'] == 'CONFIRMED',
      cashfreeOrderId: json['payment']?['cashfreeOrderId'] ?? json['cashfreeOrderId'],
    );
  }
}