import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/status_utils.dart';
import '../../../models/deadline_model.dart';
import '../../../models/laporan_model.dart';
import '../../../providers/laporan_providers.dart';
import '../../../providers/master_data_providers.dart';
import '../../../providers/settings_provider.dart';
import '../shared/widgets/admin_laporan_dialog.dart';
import '../shared/widgets/dashboard_shell.dart';

class MonitoringStatusScreen extends ConsumerStatefulWidget {
  const MonitoringStatusScreen({super.key});

  @override
  ConsumerState<MonitoringStatusScreen> createState() =>
      _MonitoringStatusScreenState();
}

class _MonitoringStatusScreenState extends ConsumerState<MonitoringStatusScreen> {
  int _tahun = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final puskesmas = ref.watch(puskesmasListProvider).value ?? [];
    final laporan = ref.watch(semuaLaporanProvider(_tahun)).value ?? [];
    final deadline =
        ref.watch(deadlineProvider).value ?? const DeadlineModel();

    final sortedPuskesmas = [...puskesmas]
      ..sort((a, b) => a.urutan.compareTo(b.urutan));

    var terkirim = 0, revisi = 0, terlambat = 0, draft = 0;
    for (final l in laporan) {
      switch (statusTampilan(
        laporan: l,
        batasInputHari: deadline.batasInputHari,
        batasRevisiHari: deadline.batasRevisiHari,
      )) {
        case 'Terkirim':
          terkirim++;
        case 'Revisi Diminta':
          revisi++;
        case 'Terlambat':
          terlambat++;
        default:
          draft++;
      }
    }

    return DashboardShell(
      title: 'Monitoring Status Pelaporan',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Center(
            child: DropdownButton<int>(
              value: _tahun,
              dropdownColor: Theme.of(context).colorScheme.surface,
              items: [
                for (final y in [DateTime.now().year, DateTime.now().year - 1])
                  DropdownMenuItem(value: y, child: Text('$y')),
              ],
              onChanged: (v) => setState(() => _tahun = v ?? _tahun),
            ),
          ),
        ),
      ],
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ChipRingkasan(
                  ikon: Icons.task_alt,
                  warna: Colors.green,
                  teks: 'Terkirim $terkirim',
                ),
                _ChipRingkasan(
                  ikon: Icons.refresh,
                  warna: Colors.orange,
                  teks: 'Revisi $revisi',
                ),
                _ChipRingkasan(
                  ikon: Icons.error_outline,
                  warna: Colors.red,
                  teks: 'Terlambat $terlambat',
                ),
                _ChipRingkasan(
                  ikon: Icons.edit_note,
                  warna: Colors.blueGrey,
                  teks: 'Draft $draft',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: const [
                _Legenda(warna: Colors.grey, label: 'Belum diisi'),
                _Legenda(warna: Colors.blueGrey, label: 'Draft'),
                _Legenda(warna: Colors.red, label: 'Terlambat'),
                _Legenda(warna: Colors.green, label: 'Terkirim'),
                _Legenda(warna: Colors.orange, label: 'Revisi diminta'),
              ],
            ),
          ),
          Expanded(
            child: puskesmas.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        headingRowHeight: 48,
                        dataRowMinHeight: 40,
                        dataRowMaxHeight: 44,
                        columns: [
                          const DataColumn(label: Text('PUSKESMAS')),
                          for (var m = 1; m <= 12; m++)
                            DataColumn(
                              label: Text(
                                AppConstants.namaBulanSingkat[m - 1],
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                        ],
                        rows: [
                          for (final p in sortedPuskesmas)
                            DataRow(
                              cells: [
                                DataCell(
                                  SizedBox(
                                    width: 180,
                                    child: Text(
                                      p.nama,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                                for (var m = 1; m <= 12; m++)
                                  DataCell(
                                    _sel(
                                      laporan.where((l) =>
                                              l.puskesmasId == p.id &&
                                              l.bulan == m)
                                          .firstOrNull,
                                      deadline,
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _sel(LaporanModel? laporan, DeadlineModel deadline) {
    Color color = Colors.grey.shade300;
    IconData? icon;
    String tooltip = 'Belum diisi';
    if (laporan != null) {
      final status = statusTampilan(
        laporan: laporan,
        batasInputHari: deadline.batasInputHari,
        batasRevisiHari: deadline.batasRevisiHari,
      );
      tooltip = '${laporan.labelBulanTahun}\n'
          'Status: $status\n'
          'Total: ${laporan.total} pemeriksaan\n'
          'Ketuk untuk detail';
      switch (status) {
        case 'Terkirim':
          color = Colors.green;
          icon = Icons.check;
          break;
        case 'Revisi Diminta':
          color = Colors.orange;
          icon = Icons.refresh;
          break;
        case 'Terlambat':
          color = Colors.red;
          icon = Icons.error;
          break;
        default:
          color = Colors.blueGrey;
          icon = Icons.edit_note;
      }
    }
    return Tooltip(
      message: tooltip,
      triggerMode: TooltipTriggerMode.tap,
      waitDuration: const Duration(milliseconds: 400),
      child: InkWell(
        onTap: laporan == null
            ? null
            : () => showAdminLaporanDialog(context, laporan, deadline),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 34,
          height: 30,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: laporan == null ? 0.3 : 0.55),
            borderRadius: BorderRadius.circular(4),
          ),
          child: icon != null
              ? Icon(icon, size: 16, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}

class _ChipRingkasan extends StatelessWidget {
  const _ChipRingkasan({
    required this.ikon,
    required this.warna,
    required this.teks,
  });

  final IconData ikon;
  final Color warna;
  final String teks;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: warna.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikon, size: 14, color: warna),
          const SizedBox(width: 6),
          Text(
            teks,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: warna,
            ),
          ),
        ],
      ),
    );
  }
}

class _Legenda extends StatelessWidget {
  const _Legenda({required this.warna, required this.label});

  final Color warna;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: warna,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
