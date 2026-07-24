// lib/features/vouchers/models/voucher_models.dart

enum DenominationType { fixed, flexible }
enum CardType { cardNumberSecured, pinNoSecured, cardAndPinNoSecured }
enum RedemptionType { online, offline, onlineAndOffline }
enum VoucherOrderStatus { success, failed, processing }

class GiftCardBrand {
  final String productId;
  final String name;
  final String? thumbnailUrl;
  final String? category;
  final DenominationType denominationType;
  final List<int>? denominations;
  final num? minVoucherAmount;
  final num? maxVoucherAmount;
  final CardType cardType;
  final RedemptionType redemptionType;
  final String redemptionTypeName;
  final String? howToUseInstructions;
  final int? maxVouchersPerOrder;
  final int? maxVouchersPerDenomination;
  final int? maxDenominationsPerOrder;
  final num? minOrderAmount;
  final num? maxOrderAmount;

  GiftCardBrand({
    required this.productId,
    required this.name,
    this.thumbnailUrl,
    this.category,
    required this.denominationType,
    this.denominations,
    this.minVoucherAmount,
    this.maxVoucherAmount,
    required this.cardType,
    required this.redemptionType,
    required this.redemptionTypeName,
    this.howToUseInstructions,
    this.maxVouchersPerOrder,
    this.maxVouchersPerDenomination,
    this.maxDenominationsPerOrder,
    this.minOrderAmount,
    this.maxOrderAmount,
  });

  factory GiftCardBrand.fromJson(Map<String, dynamic> json) => GiftCardBrand(
    productId: json['productId'] ?? '',
    name: json['name'] ?? '',
    thumbnailUrl: json['thumbnailUrl'],
    category: json['category'],
    denominationType: json['denominationType'] == 'FIXED'
        ? DenominationType.fixed
        : DenominationType.flexible,
    denominations: (json['denominations'] as List?)?.map((e) => (e as num).toInt()).toList(),
    minVoucherAmount: json['minVoucherAmount'],
    maxVoucherAmount: json['maxVoucherAmount'],
    cardType: _parseCardType(json['cardType']),
    redemptionType: _parseRedemptionType(json['redemptionType']),
    redemptionTypeName: json['redemptionTypeName'] ?? json['redemptionType'] ?? '',
    howToUseInstructions: json['howToUseInstructions'],
    maxVouchersPerOrder: json['maxVouchersPerOrder'],
    maxVouchersPerDenomination: json['maxVouchersPerDenomination'],
    maxDenominationsPerOrder: json['maxDenominationsPerOrder'],
    minOrderAmount: json['minOrderAmount'],
    maxOrderAmount: json['maxOrderAmount'],
  );

  static CardType _parseCardType(String? v) {
    switch (v) {
      case 'CARD_NUMBER_SECURED': return CardType.cardNumberSecured;
      case 'PIN_NO_SECURED': return CardType.pinNoSecured;
      default: return CardType.cardAndPinNoSecured;
    }
  }

  static RedemptionType _parseRedemptionType(String? v) {
    switch (v) {
      case 'ONLINE': return RedemptionType.online;
      case 'OFFLINE': return RedemptionType.offline;
      default: return RedemptionType.onlineAndOffline;
    }
  }

  bool get isFixed => denominationType == DenominationType.fixed;

  bool isValidAmount(num amount) {
    if (isFixed) {
      return denominations?.contains(amount.toInt()) ?? false;
    }
    final min = minVoucherAmount ?? 0;
    final max = maxVoucherAmount ?? double.infinity;
    return amount >= min && amount <= max;
  }
}

class VoucherCredential {
  final String id;
  final CardType cardType;
  final String? cardNumber;
  final String? cardPin;
  final DateTime? validTill;
  final num amount;

  VoucherCredential({
    required this.id,
    required this.cardType,
    this.cardNumber,
    this.cardPin,
    this.validTill,
    required this.amount,
  });

  factory VoucherCredential.fromJson(Map<String, dynamic> json) => VoucherCredential(
    id: json['id'] ?? '',
    cardType: GiftCardBrand._parseCardType(json['cardType']),
    cardNumber: json['cardNumber'],
    cardPin: json['cardPin'],
    validTill: json['validTill'] != null ? DateTime.tryParse(json['validTill']) : null,
    amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
  );

  bool get showCardNumber => cardType != CardType.pinNoSecured;
  bool get showCardPin => cardType != CardType.cardNumberSecured;
}

class VoucherOrderResult {
  final String orderId;
  final VoucherOrderStatus status;
  final List<VoucherCredential> vouchers;
  final String? failureReason;

  VoucherOrderResult({
    required this.orderId,
    required this.status,
    required this.vouchers,
    this.failureReason,
  });

  factory VoucherOrderResult.fromJson(Map<String, dynamic> json) => VoucherOrderResult(
    orderId: json['orderId'] ?? '',
    status: _parseStatus(json['status']),
    vouchers: (json['vouchers'] as List? ?? [])
        .map((v) => VoucherCredential.fromJson(v as Map<String, dynamic>))
        .toList(),
    failureReason: json['failureReason'],
  );

  static VoucherOrderStatus _parseStatus(String? v) {
    switch (v) {
      case 'SUCCESS': return VoucherOrderStatus.success;
      case 'FAILED': return VoucherOrderStatus.failed;
      default: return VoucherOrderStatus.processing;
    }
  }
}
