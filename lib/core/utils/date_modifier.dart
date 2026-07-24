import 'package:intl/intl.dart';

String formatDate(String date) {
  try {
    return DateFormat('dd MMM yyyy')
        .format(DateTime.parse(date).toLocal());
  } catch (_) {
    return date;
  }
}