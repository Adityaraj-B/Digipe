class AuthUtils {
  /// Takes a raw string from user input and returns E.164 format for the backend.
  /// - Exactly 10 digits -> prepends '+91'
  /// - Already has '+' -> returns as is
  /// - Otherwise -> prepends '+'
  static String normalizePhoneNumber(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 10 && !raw.startsWith('+')) {
      return '+91$digits';
    }
    if (raw.startsWith('+')) {
      return raw;
    }
    return '+$raw';
  }

  /// Basic email regex validation
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
