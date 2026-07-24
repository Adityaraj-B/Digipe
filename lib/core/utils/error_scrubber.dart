class ErrorScrubber {
  static String sanitize(String error) {
    // Scrub JWT/Bearer tokens
    String sanitized = error.replaceAll(RegExp(r'Bearer\s+[A-Za-z0-9\-_\.]+'), 'Bearer [REDACTED]');
    
    // Scrub Coordinates (Lat/Lng patterns)
    sanitized = sanitized.replaceAllMapped(
      RegExp(r'(lat|latitude|lng|longitude)[:\s]+[-+]?([0-9]+\.[0-9]+|[0-9]+)', caseSensitive: false),
      (match) => '${match.group(1)}: [SCRUBBED]'
    );

    // Scrub Gift Card / Voucher Numbers (16-19 digits, with or without spaces)
    sanitized = sanitized.replaceAll(
      RegExp(r'\b(?:\d[ -]*?){16,19}\b'),
      '[CARD_NUMBER_REDACTED]'
    );

    return sanitized;
  }
}
