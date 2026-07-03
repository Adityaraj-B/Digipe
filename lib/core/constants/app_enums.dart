/// Ground truth status enums matched to backend contracts.
class AppStatuses {
  // Applications
  static const String appApproved = 'APPROVED';
  static const String appUnderReview = 'UNDER_REVIEW';
  static const String appRejected = 'REJECTED';

  // Orders
  static const String orderConfirmed = 'CONFIRMED';
  static const String orderCancelled = 'CANCELLED';

  // Claims
  static const String claimUnderReview = 'UNDER_REVIEW';
  static const String claimSettled = 'SETTLED';
  static const String claimRejected = 'REJECTED';
}
