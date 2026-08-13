import 'package:excel/excel.dart';

import '../../models/exam_type_model.dart';
import '../../models/laporan_model.dart';
import '../../models/puskesmas_model.dart';

/// Membuat file .xlsx rekap dengan struktur identik format existing:
/// 1 sheet per bulan + sheet rekap semester, baris JUMLAH otomatis.
class ExcelExportService {
  ExcelExportService._();

  static final ExcelExportService instance = ExcelExportService._();

  static const List<String> _namaBulan = [
    'JANUARI', 'FEBRUARI', 'MARET', 'APRIL', 'MEI', 'JUNI',
    'JULI', 'AGUSTUS', 'SEPTEMBER', 'OKTOBER', 'NOVEMBER', 'DESEMBER',
  ];

  /// [semuaLaporan] berisi semua laporan pada tahun [tahun].
  /// Laporan yang masih draft tidak dimasukkan ke rekap.
  List<int>? generateRekap({
    required int tahun,
    required List<PuskesmasModel> puskesmas,
    required List<ExamTypeModel> examTypes,
    required List<LaporanModel> semuaLaporan,
    String periode = 'all',
  }) {
    final sortedPuskesmas = [...puskesmas]
      ..sort((a, b) => a.urutan.compareTo(b.urutan));
    final sortedExamTypes = [...examTypes]
      ..sort((a, b) => a.urutan.compareTo(b.urutan));
    final laporanSubmitted = semuaLaporan
        .where((l) => l.status != LaporanStatus.draft)
        .toList();
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();

    // Hapus sheet default
    if (defaultSheet != null) {
      excel.delete(defaultSheet);
    }

    // Sheet Bulanan
    for (var i = 0; i < 12; i++) {
      final bulan = i + 1;
      
      bool shouldInclude = false;
      if (periode == 'all') shouldInclude = true;
      else if (periode == 's1' && bulan <= 6) shouldInclude = true;
      else if (periode == 's2' && bulan > 6) shouldInclude = true;
      else if (periode == 'm$bulan') shouldInclude = true;

      if (!shouldInclude) continue;

      final bulanLaporan = laporanSubmitted
          .where((l) => l.bulan == bulan)
          .toList();
      final sheet = excel[_namaBulan[i]];
      _isikanSheet(
        sheet,
        tahun: tahun,
        puskesmas: sortedPuskesmas,
        examTypes: sortedExamTypes,
        laporan: bulanLaporan,
        judul: 'REKAP PUSKESMAS BULAN ${_namaBulan[i]} $tahun',
      );
    }

    // Sheet Rekap Semester
    for (final semester in const [
      ('REKAP SEMESTER I', [1, 2, 3, 4, 5, 6], 's1'),
      ('REKAP SEMESTER II', [7, 8, 9, 10, 11, 12], 's2'),
    ]) {
      bool shouldInclude = false;
      if (periode == 'all') shouldInclude = true;
      else if (periode == semester.$3) shouldInclude = true;

      if (!shouldInclude) continue;

      final nama = semester.$1;
      final bulanList = semester.$2;
      final semesterLaporan = laporanSubmitted
          .where((l) => bulanList.contains(l.bulan))
          .toList();
      final sheet = excel[nama];
      _isikanSheet(
        sheet,
        tahun: tahun,
        puskesmas: sortedPuskesmas,
        examTypes: sortedExamTypes,
        laporan: semesterLaporan,
        judul: '$nama $tahun',
      );
    }

    if (excel.tables.keys.isNotEmpty) {
      excel.setDefaultSheet(excel.tables.keys.first);
    }
    
    return excel.encode();
  }

  void _isikanSheet(
    Sheet sheet, {
    required int tahun,
    required List<PuskesmasModel> puskesmas,
    required List<ExamTypeModel> examTypes,
    required List<LaporanModel> laporan,
    required String judul,
  }) {
    // Kolom: 0 = NO, 1 = PUSKESMAS/UPT, 2.. = jenis pemeriksaan
    final jumlahKolom = 2 + examTypes.length;

    // --- Baris judul (merge) ---
    final startJudul = CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0);
    final endJudul = CellIndex.indexByColumnRow(columnIndex: jumlahKolom - 1, rowIndex: 0);
    sheet.merge(startJudul, endJudul);
    sheet.updateCell(
      startJudul,
      TextCellValue(judul),
      cellStyle: CellStyle(
        bold: true,
        fontSize: 13,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        backgroundColorHex: ExcelColor.fromHexString('FFD9E2F3'),
      ),
    );
    sheet.setRowHeight(0, 22);

    // --- Baris header ---
    final headerRow = <CellValue?>[
      TextCellValue('NO'),
      TextCellValue('PUSKESMAS'),
    ];
    for (final e in examTypes) {
      headerRow.add(TextCellValue(e.nama));
    }
    sheet.appendRow(headerRow);

    final headerStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('FFF2F2F2'),
      textWrapping: TextWrapping.WrapText,
      fontSize: 9,
    );
    for (var c = 0; c < jumlahKolom; c++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 1));
      cell.cellStyle = headerStyle;
    }
    sheet.setRowHeight(1, 28);

    // --- Baris data ---
    var baris = 2;
    for (var i = 0; i < puskesmas.length; i++) {
      final p = puskesmas[i];
      final laporanPuskesmas = laporan
          .where((l) => l.puskesmasId == p.id)
          .toList();

      // Sum hasil per examType (bisa lebih dari satu laporan mis. semester).
      final row = <CellValue?>[IntCellValue(i + 1), TextCellValue(p.nama)];
      for (final e in examTypes) {
        num total = 0;
        for (final l in laporanPuskesmas) {
          total += l.hasil[e.id] ?? 0;
        }
        row.add(IntCellValue(total.toInt()));
      }
      sheet.appendRow(row);
      baris++;
    }

    // --- Baris JUMLAH ---
    final jumlahRow = <CellValue?>[TextCellValue(''), TextCellValue('JUMLAH')];
    for (var c = 0; c < examTypes.length; c++) {
      num total = 0;
      for (var r = 2; r < baris; r++) {
        final val = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: c + 2, rowIndex: r),
        ).value;
        if (val is IntCellValue) total += val.value;
        if (val is DoubleCellValue) total += val.value;
      }
      jumlahRow.add(IntCellValue(total.toInt()));
    }
    sheet.appendRow(jumlahRow);

    final jumlahStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('FFD9E2F3'),
    );
    final lastRowIndex = baris; // baris data terakhir (index JUMLAH)
    for (var c = 0; c < jumlahKolom; c++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: c, rowIndex: lastRowIndex),
      );
      cell.cellStyle = jumlahStyle;
    }

    // Lebar kolom
    sheet.setColumnWidth(0, 5);
    sheet.setColumnWidth(1, 22);
    for (var c = 0; c < examTypes.length; c++) {
      sheet.setColumnWidth(c + 2, 10);
    }
  }
}
