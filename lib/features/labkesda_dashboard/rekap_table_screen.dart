import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/download_helper.dart';
import '../../../core/services/excel_export_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/exam_type_model.dart';
import '../../../models/laporan_model.dart';
import '../../../models/puskesmas_model.dart';
import '../../../providers/laporan_providers.dart';
import '../../../providers/master_data_providers.dart';
import '../shared/widgets/dashboard_shell.dart';

class RekapTableScreen extends ConsumerStatefulWidget {
  const RekapTableScreen({super.key});

  @override
  ConsumerState<RekapTableScreen> createState() => _RekapTableScreenState();
}

class _RekapTableScreenState extends ConsumerState<RekapTableScreen> {
  int _tahun = DateTime.now().year;
  int? _bulan = DateTime.now().month; // null = seluruh tahun
  bool _exporting = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final puskesmas = ref.watch(puskesmasListProvider).value ?? [];
    final examTypes = ref.watch(examTypesProvider).value ?? [];
    final laporan = ref.watch(semuaLaporanProvider(_tahun)).value ?? [];

    final sortedPuskesmas = [...puskesmas]
      ..sort((a, b) => a.urutan.compareTo(b.urutan));
    final sortedExamTypes = [...examTypes]
      ..sort((a, b) => a.urutan.compareTo(b.urutan));

    final filteredLaporan = laporan.where((l) {
      if (l.status == LaporanStatus.draft) return false;
      if (_bulan != null && l.bulan != _bulan) return false;
      return true;
    }).toList();

    return DashboardShell(
      title: 'Rekap Data',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            tooltip: 'Export Excel',
            onPressed: _exporting ? null : () => _export(context, _tahun),
            icon: _exporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_download_outlined),
          ),
        ),
      ],
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              DropdownButton<int?>(
                value: _bulan,
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Seluruh tahun'),
                  ),
                  for (var m = 1; m <= 12; m++)
                    DropdownMenuItem<int?>(
                      value: m,
                      child: Text(AppConstants.namaBulan[m - 1]),
                    ),
                ],
                onChanged: (v) => setState(() => _bulan = v),
              ),
              DropdownButton<int>(
                value: _tahun,
                items: [
                  for (var y = DateTime.now().year; y >= 2025; y--)
                    DropdownMenuItem(value: y, child: Text('$y')),
                ],
                onChanged: (v) => setState(() => _tahun = v ?? _tahun),
              ),
              Text(
                '${sortedPuskesmas.length} puskesmas • ${sortedExamTypes.length} jenis',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
          Expanded(
            child: (sortedPuskesmas.isEmpty || sortedExamTypes.isEmpty)
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: _RekapTabel(
                            puskesmas: sortedPuskesmas,
                            examTypes: sortedExamTypes,
                            laporan: filteredLaporan,
                            availableHeight: constraints.maxHeight,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context, int tahun) async {
    setState(() => _exporting = true);
    try {
      final puskesmas = ref.read(puskesmasListProvider).value ?? [];
      final examTypes = ref.read(examTypesProvider).value ?? [];
      final laporan = ref.read(semuaLaporanProvider(tahun)).value ?? [];

      final bytes = ExcelExportService.instance.generateRekap(
        tahun: tahun,
        puskesmas: puskesmas,
        examTypes: examTypes,
        semuaLaporan: laporan,
      );

      if (bytes == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Gagal membuat file Excel.')));
        }
        return;
      }
      await downloadFile(Uint8List.fromList(bytes), 'REKAP_PUSKESMAS_$tahun.xlsx');
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Export berhasil.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal export: $e')));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }
}

class _RekapTabel extends StatelessWidget {
  const _RekapTabel({
    required this.puskesmas,
    required this.examTypes,
    required this.laporan,
    required this.availableHeight,
  });

  final List<PuskesmasModel> puskesmas;
  final List<ExamTypeModel> examTypes;
  final List<LaporanModel> laporan;
  final double availableHeight;

  double _totalFor(String puskesmasId, String examTypeId) {
    num total = 0;
    for (final l in laporan) {
      if (l.puskesmasId == puskesmasId) total += l.hasil[examTypeId] ?? 0;
    }
    return total.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final totalWidth = 200.0 + examTypes.length * 90.0;

    Widget buildCell(Widget child, double width, {bool isHeader = false}) {
      return Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        alignment: isHeader ? Alignment.bottomLeft : Alignment.centerLeft,
        child: child,
      );
    }

    // Header Row
    final headerRow = Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black12, width: 2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          buildCell(const Text('NO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), 60, isHeader: true),
          buildCell(const Text('PUSKESMAS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), 130, isHeader: true),
          for (final e in examTypes)
            buildCell(
              Text(
                e.nama,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 9),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              90,
              isHeader: true,
            ),
        ],
      ),
    );

    // Footer Row (Jumlah)
    final footerRow = Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF0F4F8), // Subtle highlight for footer
        border: Border(top: BorderSide(color: Colors.black12, width: 2)),
      ),
      child: Row(
        children: [
          buildCell(const SizedBox(), 60),
          buildCell(const Text('JUMLAH', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), 130),
          for (final e in examTypes)
            buildCell(
              Center(
                child: Text(
                  formatAngka(
                    puskesmas.fold<num>(0, (sum, p) => sum + _totalFor(p.id, e.id)),
                  ),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
              90,
            ),
        ],
      ),
    );

    const headerHeight = 64.0;
    const footerHeight = 40.0;
    final bodyHeight = (availableHeight - headerHeight - footerHeight).clamp(80.0, double.infinity);

    return SizedBox(
      width: totalWidth,
      child: Column(
        children: [
          headerRow,
          SizedBox(
            height: bodyHeight,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                children: [
                  for (var i = 0; i < puskesmas.length; i++)
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.black12)),
                      ),
                      child: Row(
                        children: [
                          buildCell(Text('${i + 1}', style: const TextStyle(fontSize: 11)), 60),
                          buildCell(Text(puskesmas[i].nama, style: const TextStyle(fontSize: 11)), 130),
                          for (final e in examTypes)
                            buildCell(
                              Center(
                                child: Text(
                                  formatAngka(_totalFor(puskesmas[i].id, e.id)),
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                              90,
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          footerRow,
        ],
      ),
    );
  }
}
