import 'package:intl/intl.dart';

String formatAmount(dynamic amount) {
  try {
    final value = amount is num
        ? amount.toDouble()
        : double.parse(amount.toString());

    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    ).format(value);
  } catch (_) {
    return '₹0.00';
  }
}