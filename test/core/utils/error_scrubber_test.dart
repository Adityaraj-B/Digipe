import 'package:flutter_test/flutter_test.dart';
import 'package:digipe/core/utils/error_scrubber.dart';

void main() {
  group('ErrorScrubber', () {
    test('should scrub Bearer tokens', () {
      const input = 'Error: Unauthorized. Token: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.abc';
      final output = ErrorScrubber.sanitize(input);
      expect(output, contains('Bearer [REDACTED]'));
      expect(output, isNot(contains('eyJhbGci')));
    });

    test('should scrub coordinates', () {
      const input = 'Failed to report location at lat: 12.9716 and lng: 77.5946';
      final output = ErrorScrubber.sanitize(input);
      expect(output, contains('lat: [SCRUBBED]'));
      expect(output, contains('lng: [SCRUBBED]'));
      expect(output, isNot(contains('12.9716')));
      expect(output, isNot(contains('77.5946')));
    });

    test('should scrub full latitude/longitude words', () {
      const input = 'Position error: latitude: -34.01, longitude: 151.21';
      final output = ErrorScrubber.sanitize(input);
      expect(output, contains('latitude: [SCRUBBED]'));
      expect(output, contains('longitude: [SCRUBBED]'));
    });

    test('should handle case insensitivity for coordinates', () {
      const input = 'LAT: 10.0, LNG: 20.0';
      final output = ErrorScrubber.sanitize(input);
      expect(output, contains('LAT: [SCRUBBED]'));
      expect(output, contains('LNG: [SCRUBBED]'));
    });

    test('should scrub 16-19 digit card numbers', () {
      const input = 'Voucher processed for card 4455 6677 8899 0011 and pin 1234';
      final output = ErrorScrubber.sanitize(input);
      expect(output, contains('[CARD_NUMBER_REDACTED]'));
      expect(output, isNot(contains('4455')));
    });

    test('should scrub card numbers without spaces', () {
      const input = 'Ref: 1234567890123456789';
      final output = ErrorScrubber.sanitize(input);
      expect(output, contains('[CARD_NUMBER_REDACTED]'));
    });
  });
}
