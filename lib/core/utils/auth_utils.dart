class AuthUtils {
  /// Returns raw 10-digit number for the backend.
  static String normalizePhoneNumber(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 10) {
      // If it has +91 or 91, take only the last 10 digits
      return digits.substring(digits.length - 10);
    }
    return digits;
  }

  /// Basic email regex validation
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
