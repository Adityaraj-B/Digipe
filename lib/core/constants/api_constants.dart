class ApiConstants {
  // Ground Truth Base URL from production environment
  static const String baseUrl = 'https://api.digipe.in';

  // Auth (Your own backend, strictly following the hardened contract)
  static const String sendOtp = '/api/auth/send-otp';
  static const String verifyOtp = '/api/auth/verify-otp';
  static const String register = '/api/auth/register';

  // Categories
  static const String categories = '/api/categories';

  // Products
  static const String products = '/api/products';

  // Plans
  static const String plans = '/api/plans';
  static const String productPlans = '/api/plans/product';

  // Product Fields (per product)
  static const String productFieldsByProduct = '/api/product-fields/product';
  static const String productFields = '/api/product-fields';

  // Applications
  static const String applications = '/api/applications';

  // Orders
  static const String consumerOrders = '/api/orders/my';
  static const String adminOrders = '/api/admin/orders';
  static const String paymentStatus = '/api/payments/status';

  // Policies
  static const String myPolicies = '/api/policies/my';

  // Claims
  static const String claims = '/api/claims';

  // Admin Only
  static const String adminLogins = '/api/admin/logins';

  // Document Upload (2-step submission process)
  static const String upload = '/api/documents/upload';

  // Hubble SDK (Gift Card / Voucher Store)
  static const String hubbleSdkToken = '/api/hubble/sdk-token';
  static const String hubbleTransactions = '/api/hubble/transactions';
}
