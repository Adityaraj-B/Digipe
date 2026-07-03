class ErrorScrubber {
  static String sanitize(String error) {
    // SECTION 13: Scrub any string that looks like a JWT or Bearer token
    return error.replaceAll(RegExp(r'Bearer\s+[A-Za-z0-9\-_\.]+'), 'Bearer [REDACTED]');
  }
}
