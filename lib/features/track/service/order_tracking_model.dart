// ─────────────────────────────────────────────────────────────────────────────
// order_tracking_model.dart
//
// Pure data layer — no Flutter imports.
// ─────────────────────────────────────────────────────────────────────────────

enum OrderStatus {
  pendingApproval,
  underReview,
  paymentEligible,
  approved,
  active,
  claimRaised,
  claimApproved,
  rejected,
  expired,
  cancelled;

  static OrderStatus fromString(String value) {
    switch (value.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '')) {
      case 'pendingapproval':
        return OrderStatus.pendingApproval;
      case 'underreview':
        return OrderStatus.underReview;
      case 'paymenteligible':
      case 'approvedpaynow':
        return OrderStatus.paymentEligible;
      case 'approved':
        return OrderStatus.approved;
      case 'active':
        return OrderStatus.active;
      case 'claimraised':
        return OrderStatus.claimRaised;
      case 'claimapproved':
      case 'claimsettled':
        return OrderStatus.claimApproved;
      case 'rejected':
        return OrderStatus.rejected;
      case 'expired':
        return OrderStatus.expired;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pendingApproval;
    }
  }

  String get displayLabel {
    switch (this) {
      case OrderStatus.pendingApproval:
        return 'PENDING APPROVAL';
      case OrderStatus.underReview:
        return 'UNDER REVIEW';
      case OrderStatus.paymentEligible:
        return 'PAYMENT ELIGIBLE';
      case OrderStatus.approved:
        return 'APPROVED';
      case OrderStatus.active:
        return 'ACTIVE';
      case OrderStatus.claimRaised:
        return 'CLAIM RAISED';
      case OrderStatus.claimApproved:
        return 'CLAIM APPROVED';
      case OrderStatus.rejected:
        return 'REJECTED';
      case OrderStatus.expired:
        return 'EXPIRED';
      case OrderStatus.cancelled:
        return 'CANCELLED';
    }
  }

  bool get isPolicyActive => this == OrderStatus.active;

  bool get canDownloadPolicy =>
      this == OrderStatus.active ||
          this == OrderStatus.claimRaised ||
          this == OrderStatus.claimApproved ||
          this == OrderStatus.expired;

  bool get canViewInvoice =>
      this != OrderStatus.pendingApproval && this != OrderStatus.rejected;

  String get policyNotice {
    switch (this) {
      case OrderStatus.pendingApproval:
      case OrderStatus.underReview:
        return 'Application is under review. Not eligible for claims yet.';
      case OrderStatus.paymentEligible:
      case OrderStatus.approved:
        return 'Payment eligibility confirmed. Awaiting policy generation.';
      case OrderStatus.active:
        return 'Policy is active. You are eligible to file claims.';
      case OrderStatus.claimRaised:
        return 'Claim Raised. Pending Admin Review.';
      case OrderStatus.claimApproved:
        return 'Claim Settled and Approved!';
      case OrderStatus.rejected:
        return 'Policy application was rejected. Contact support for details.';
      case OrderStatus.expired:
      case OrderStatus.cancelled:
        return 'Policy is inactive. Not eligible for claims.';
    }
  }
}

enum LifecycleStepState {
  done,
  active,
  pending,
  failed; // Added for rejections/cancellations

  static LifecycleStepState fromString(String value) {
    switch (value.toLowerCase()) {
      case 'done':
      case 'completed':
        return LifecycleStepState.done;
      case 'active':
      case 'inprogress':
      case 'in_progress':
      case 'current':
        return LifecycleStepState.active;
      case 'failed':
        return LifecycleStepState.failed;
      default:
        return LifecycleStepState.pending;
    }
  }
}

class LifecycleStep {
  final String title;
  final String subtitle;
  final LifecycleStepState state;
  final DateTime? completedAt;

  const LifecycleStep({
    required this.title,
    required this.subtitle,
    required this.state,
    this.completedAt,
  });

  factory LifecycleStep.fromJson(Map<String, dynamic> json) {
    return LifecycleStep(
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      state: LifecycleStepState.fromString(json['state'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'subtitle': subtitle,
    'state': state.name,
    'completed_at': completedAt?.toIso8601String(),
  };
}

class OrderTracking {
  final String orderId;
  final OrderStatus status;
  final String policyType;
  final DateTime purchaseDate;
  final double amountPaid;
  final String coveragePeriod;
  final String currencySymbol;
  final String? planId;
  final int years;
  final List<LifecycleStep> lifecycleSteps;
  final String? invoiceUrl;
  final String? policyDocumentUrl;

  const OrderTracking({
    required this.orderId,
    required this.status,
    required this.policyType,
    required this.purchaseDate,
    required this.amountPaid,
    required this.coveragePeriod,
    this.currencySymbol = 'Rs.',
    this.planId,
    this.years = 1,
    required this.lifecycleSteps,
    this.invoiceUrl,
    this.policyDocumentUrl,
  });

  String get formattedAmount =>
      '$currencySymbol ${amountPaid.toStringAsFixed(0)}';

  String get formattedPurchaseDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[purchaseDate.month - 1]} ${purchaseDate.day}, ${purchaseDate.year}';
  }
}