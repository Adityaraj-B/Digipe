class AuthUtils {
  /// Returns a clean 10-digit raw number (used strictly for registration payload)
  static String rawTenDigits(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 10) {
      return digits.substring(digits.length - 10);
    }
    return digits;
  }

  /// Ensures the phone number is prefixed with '+91' (used for login and verification)
  static String formatWithCountryCode(String raw) {
    if (raw.contains('@')) return raw.trim().toLowerCase();

    // If it already has a country code prefix, leave it be
    if (raw.trim().startsWith('+')) return raw.trim();

    final tenDigits = rawTenDigits(raw);
    return '+91$tenDigits';
  }

  /// Basic email regex validation
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}