import 'package:intl/intl.dart';

String formatTanggal(DateTime? dt, {String pattern = 'dd MMM yyyy'}) {
  if (dt == null) return '-';
  return DateFormat(pattern, 'id_ID').format(dt);
}

String formatTanggalWaktu(DateTime? dt) {
  if (dt == null) return '-';
  return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dt);
}

String formatAngka(num? value) {
  if (value == null) return '0';
  final nf = NumberFormat('#,##0', 'id_ID');
  return nf.format(value);
}
