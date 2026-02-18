import 'package:intl/intl.dart';

String formatKsh(double amount) {
  final formatter = NumberFormat('#,##0.00', 'en_US');
  return 'KSH ${formatter.format(amount)}';
}

String formatDate(DateTime date) {
  return DateFormat('MMM dd, yyyy').format(date);
}

String formatTime(DateTime date) {
  return DateFormat('hh:mm a').format(date);
}

String formatDateTime(DateTime date) {
  return DateFormat('MMM dd, yyyy - hh:mm a').format(date);
}

String formatPhone(String phone) {
  if (phone.length == 12 && phone.startsWith('254')) {
    return '0${phone.substring(3, 6)} ${phone.substring(6, 9)} ${phone.substring(9)}';
  }
  return phone;
}
