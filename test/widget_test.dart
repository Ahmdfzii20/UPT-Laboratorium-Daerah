import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:labkesda_app/core/utils/formatters.dart';
import 'package:labkesda_app/core/utils/status_utils.dart';
import 'package:labkesda_app/models/laporan_model.dart';
import 'package:labkesda_app/models/deadline_model.dart';
import 'package:labkesda_app/features/shared/widgets/status_chip.dart';

void main() {
  group('StatusChip', () {
    testWidgets('menampilkan label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StatusChip(label: 'Terkirim', color: Colors.green)),
        ),
      );
      expect(find.text('TERKIRIM'), findsOneWidget);
    });
  });

  group('status_utils', () {
    test('isOverdue benar saat lewat batas', () {
      final laporan = LaporanModel(
        id: 'x',
        puskesmasId: 'p1',
        tahun: 2026,
        bulan: 1,
        status: LaporanStatus.draft,
        hasil: const {},
      );
      // Laporan Januari 2026 => batas 1 Feb 2026 + 10 hari = 11 Feb 2026.
      expect(
        isOverdue(laporan: laporan, batasInputHari: 10, now: DateTime(2026, 2, 12)),
        isTrue,
      );
      expect(
        isOverdue(laporan: laporan, batasInputHari: 10, now: DateTime(2026, 2, 10)),
        isFalse,
      );
    });

    test('masihBisaDirevisi menghitung batas revisi', () {
      final disubmitPada = DateTime(2026, 2, 1);
      expect(
        masihBisaDirevisi(disubmitPada: disubmitPada, batasRevisiHari: 10, now: DateTime(2026, 2, 5)),
        isTrue,
      );
      expect(
        masihBisaDirevisi(disubmitPada: disubmitPada, batasRevisiHari: 10, now: DateTime(2026, 2, 12)),
        isFalse,
      );
      expect(
        masihBisaDirevisi(disubmitPada: null, batasRevisiHari: 10, now: DateTime(2026, 2, 12)),
        isTrue,
      );
    });
  });

  test('DeadlineModel default', () {
    const d = DeadlineModel();
    expect(d.batasInputHari, 10);
    expect(d.satuanBatasInput, 'kalender');
    expect(d.batasRevisiHari, 10);
  });

  group('formatters', () {
    test('formatTanggal tidak gagal setelah initializeDateFormatting(id_ID)', () async {
      await initializeDateFormatting('id_ID');
      expect(formatTanggal(DateTime(2026, 8, 11)), '11 Agu 2026');
      expect(
        formatTanggalWaktu(DateTime(2026, 8, 11, 14, 5)),
        contains('11 Agu 2026'),
      );
    });

    test('formatAngka memakai separator titik', () {
      expect(formatAngka(1234567), '1.234.567');
    });
  });
}
