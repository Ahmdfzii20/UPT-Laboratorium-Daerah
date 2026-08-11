import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/firestore_service.dart';
import '../models/laporan_model.dart';

/// Semua laporan milik satu puskesmas (untuk dashboard & histori petugas).
final laporanPuskesmasProvider =
    StreamProvider.family<List<LaporanModel>, String>((ref, puskesmasId) {
  return FirestoreService.instance.streamLaporanByPuskesmas(puskesmasId);
});

/// Semua laporan seluruh puskesmas (untuk admin), optional filter tahun.
final semuaLaporanProvider = StreamProvider.family<List<LaporanModel>, int?>(
  (ref, tahun) {
    return FirestoreService.instance.streamSemuaLaporan(tahun: tahun);
  },
);

/// Sub-koleksi histori (audit trail) sebuah laporan.
final historiLaporanProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, laporanId) {
  return FirestoreService.instance.streamHistori(laporanId);
});
