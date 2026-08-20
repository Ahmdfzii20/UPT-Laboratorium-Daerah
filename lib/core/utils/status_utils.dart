import '../../models/laporan_model.dart';

/// Menghitung status "Terlambat" (overdue) secara on-the-fly di client (§6.3).
/// Laporan dianggap terlambat jika masih draft/revision_requested dan
/// tanggal sekarang sudah melewati awal bulan berikutnya + batasInputHari.
bool isOverdue({
  required LaporanModel laporan,
  required int batasInputHari,
  DateTime? now,
}) {
  if (laporan.status == LaporanStatus.submitted) return false;
  final current = now ?? DateTime.now();
  final batasWaktu = DateTime(
    laporan.tahun,
    laporan.bulan + 1,
    1,
  ).add(Duration(days: batasInputHari));
  return current.isAfter(batasWaktu);
}

/// Menghitung apakah periode input laporan masih dibuka.
/// Batas dihitung dari awal bulan berikutnya ditambah batas input.
bool masihBisaInput({
  required int tahun,
  required int bulan,
  required int batasInputHari,
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  final batasWaktu = DateTime(
    tahun,
    bulan + 1,
    1,
  ).add(Duration(days: batasInputHari));
  return current.isBefore(batasWaktu);
}

/// Menghitung apakah laporan masih bisa direvisi/diedit oleh petugas puskesmas.
/// - Belum pernah submit → true (bebas edit).
/// - Sudah submit → true selama sekarang < disubmitPada + batasRevisiHari.
bool masihBisaDirevisi({
  required DateTime? disubmitPada,
  required int batasRevisiHari,
  DateTime? now,
}) {
  if (disubmitPada == null) return true;
  final current = now ?? DateTime.now();
  final batasRevisi = disubmitPada.add(Duration(days: batasRevisiHari));
  return current.isBefore(batasRevisi);
}

/// Status tampilan akhir sebuah laporan untuk UI (menyertakan hasil kalkulasi overdue).
String statusTampilan({
  required LaporanModel laporan,
  required int batasInputHari,
  required int batasRevisiHari,
  DateTime? now,
}) {
  if (laporan.status == LaporanStatus.draft &&
      isOverdue(laporan: laporan, batasInputHari: batasInputHari, now: now)) {
    return 'Terlambat';
  }
  return laporan.status.label;
}
