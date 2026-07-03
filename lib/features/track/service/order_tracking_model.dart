// ─────────────────────────────────────────────────────────────────────────────
// order_tracking_model.dart
//
// Pure data layer — no Flutter imports.
// Deserialise straight from your API JSON with `OrderTracking.fromJson(json)`.
// ─────────────────────────────────────────────────────────────────────────────

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

/// Overall order status — maps to the badge on the order card.
enum OrderStatus {
  pendingApproval,
  underReview,
  paymentEligible,
  active,
  rejected,
  expired;

  /// Deserialise the string your API sends.
  static OrderStatus fromString(String value) {
    switch (value.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '')) {
      case 'pendingapproval':
        return OrderStatus.pendingApproval;
      case 'underreview':
        return OrderStatus.underReview;
      case 'paymenteligible':
        return OrderStatus.paymentEligible;
      case 'active':
        return OrderStatus.active;
      case 'rejected':
        return OrderStatus.rejected;
      case 'expired':
        return OrderStatus.expired;
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
      case OrderStatus.active:
        return 'ACTIVE';
      case OrderStatus.rejected:
        return 'REJECTED';
      case OrderStatus.expired:
        return 'EXPIRED';
    }
  }

  /// Whether the policy is fully active and eligible for claims.
  bool get isPolicyActive => this == OrderStatus.active;

  /// Whether Download Policy button should be enabled.
  bool get canDownloadPolicy => this == OrderStatus.active;

  /// Whether View Invoice button should be enabled.
  bool get canViewInvoice =>
      this != OrderStatus.pendingApproval && this != OrderStatus.rejected;

  /// Human-readable notice shown in Quick Actions.
  String get policyNotice {
    switch (this) {
      case OrderStatus.pendingApproval:
        return 'Policy is inactive (Pending Approval). Not eligible for claims.';
      case OrderStatus.underReview:
        return 'Documents are under review. Not eligible for claims yet.';
      case OrderStatus.paymentEligible:
        return 'Payment eligibility confirmed. Awaiting policy generation.';
      case OrderStatus.active:
        return 'Policy is active. You are eligible to file claims.';
      case OrderStatus.rejected:
        return 'Policy application was rejected. Contact support for details.';
      case OrderStatus.expired:
        return 'Policy has expired. Renew to continue coverage.';
    }
  }
}

/// Per-step state in the lifecycle stepper.
enum LifecycleStepState {
  done,
  active,
  pending;

  static LifecycleStepState fromString(String value) {
    switch (value.toLowerCase()) {
      case 'done':
      case 'completed':
        return LifecycleStepState.done;
      case 'active':
      case 'inprogress':
      case 'in_progress':
        return LifecycleStepState.active;
      default:
        return LifecycleStepState.pending;
    }
  }
}

// ---------------------------------------------------------------------------
// LifecycleStep
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// OrderTracking  (root model)
// ---------------------------------------------------------------------------

class OrderTracking {
  final String orderId;
  final OrderStatus status;
  final String policyType;
  final DateTime purchaseDate;
  final double amountPaid;
  final String coveragePeriod;
  final String currencySymbol;
  final String? planId;   // NEW
  final int years;

  /// The lifecycle steps. Order matters — rendered top-to-bottom.
  final List<LifecycleStep> lifecycleSteps;

  /// Optional URLs returned by the backend for quick-action buttons.
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
    this.planId,           // NEW
    this.years = 1,
    required this.lifecycleSteps,
    this.invoiceUrl,
    this.policyDocumentUrl,
  });

  // ── Deserialisation ──────────────────────────────────────────────────────

  factory OrderTracking.fromJson(Map<String, dynamic> json) {
    return OrderTracking(
      orderId: json['order_id'] as String,
      status: OrderStatus.fromString(json['status'] as String),
      policyType: json['policy_type'] as String,
      purchaseDate: DateTime.parse(json['purchase_date'] as String),
      amountPaid: (json['amount_paid'] as num).toDouble(),
      coveragePeriod: json['coverage_period'] as String,
      currencySymbol: json['currency_symbol'] as String? ?? 'Rs.',
      planId: json['plan_id'] as String?,                    // NEW
      years: (json['years'] as num?)?.toInt() ?? 1,
      lifecycleSteps: (json['lifecycle_steps'] as List<dynamic>)
          .map((e) => LifecycleStep.fromJson(e as Map<String, dynamic>))
          .toList(),
      invoiceUrl: json['invoice_url'] as String?,
      policyDocumentUrl: json['policy_document_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'order_id': orderId,
    'status': status.name,
    'policy_type': policyType,
    'purchase_date': purchaseDate.toIso8601String(),
    'amount_paid': amountPaid,
    'coverage_period': coveragePeriod,
    'currency_symbol': currencySymbol,
    'plan_id': planId,     // NEW
    'years': years,
    'lifecycle_steps': lifecycleSteps.map((s) => s.toJson()).toList(),
    'invoice_url': invoiceUrl,
    'policy_document_url': policyDocumentUrl,
  };

  // ── Formatted helpers used directly by the UI ────────────────────────────

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

// ---------------------------------------------------------------------------
// Mock factory — replace with real API call later
// ---------------------------------------------------------------------------

class OrderTrackingMock {
  static OrderTracking get sample => OrderTracking.fromJson({
    'order_id': 'APP-90058A02',
    'status': 'pending_approval',
    'policy_type': 'amit yadssv',
    'purchase_date': '2026-06-12T00:00:00.000Z',
    'amount_paid': 899,
    'coverage_period': '1 Year',
    'currency_symbol': 'Rs.',
    'invoice_url': null,
    'policy_document_url': null,
    'lifecycle_steps': [
      {
        'title': 'Application Submitted',
        'subtitle': 'Jun 12, 2026',
        'state': 'done',
        'completed_at': '2026-06-12T10:00:00.000Z',
      },
      {
        'title': 'Under Document Review',
        'subtitle': 'In Progress',
        'state': 'active',
        'completed_at': null,
      },
      {
        'title': 'Payment Eligibility',
        'subtitle': 'Pending Verification',
        'state': 'pending',
        'completed_at': null,
      },
      {
        'title': 'Policy Generation',
        'subtitle': 'Pending Approval',
        'state': 'pending',
        'completed_at': null,
      },
    ],
  });
}