import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/status_utils.dart';
import '../../../models/deadline_model.dart';
import '../../../models/laporan_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/laporan_providers.dart';
import '../../../providers/master_data_providers.dart';
import '../../../providers/settings_provider.dart';
import '../shared/widgets/dashboard_cards.dart';
import '../shared/widgets/dashboard_shell.dart';
import '../shared/widgets/laporan_status_badge.dart';
import 'form_laporan_screen.dart';

class PuskesmasDashboardScreen extends ConsumerWidget {
  const PuskesmasDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final puskesmasId = user?.puskesmasId ?? '';
    final laporan = ref.watch(laporanPuskesmasProvider(puskesmasId));
    final deadline = ref.watch(deadlineProvider).value ?? const DeadlineModel();
    final puskesmasList = ref.watch(puskesmasListProvider).value ?? [];

    final puskesmas =
        puskesmasList.where((p) => p.id == puskesmasId).firstOrNull;
    final namaPuskesmas = user?.nama.isNotEmpty == true
        ? user!.nama
        : (puskesmas?.nama ?? 'Puskesmas');

    final now = DateTime.now();
    final semuaLaporan = laporan.value ?? [];
    final laporanBulanIni = semuaLaporan
        .where((l) => l.tahun == now.year && l.bulan == now.month)
        .firstOrNull;
    final periode = laporanBulanIni?.labelBulanTahun ??
        '${AppConstants.namaBulan[now.month - 1]} ${now.year}';

    final terkirim = semuaLaporan
        .where((l) => statusTampilan(
              laporan: l,
              batasInputHari: deadline.batasInputHari,
              batasRevisiHari: deadline.batasRevisiHari,
            ) ==
            'Terkirim')
        .length;
    final perluAksi = semuaLaporan.length - terkirim;

    return DashboardShell(
      title: 'Dashboard Puskesmas',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GradientHeader(
            judul: 'Dashboard Puskesmas',
            subjudul: 'Kab. Deli Serdang',
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.local_hospital_outlined,
                      color: Theme.of(context).colorScheme.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selamat datang,',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13),
                      ),
                      Text(
                        namaPuskesmas,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Periode berjalan: $periode',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _KartuBulanIni(
            laporan: laporanBulanIni,
            deadline: deadline,
            tahun: now.year,
            bulan: now.month,
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 700 ? 3 : 3;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: constraints.maxWidth > 700 ? 2.4 : 1.15,
                children: [
                  StatCard(
                    label: 'Total Laporan',
                    value: '${semuaLaporan.length}',
                    icon: Icons.inbox_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  StatCard(
                    label: 'Terkirim',
                    value: '$terkirim',
                    icon: Icons.task_alt,
                    color: Colors.green.shade700,
                  ),
                  StatCard(
                    label: 'Perlu Aksi',
                    value: '$perluAksi',
                    icon: Icons.pending_actions,
                    color: Colors.orange.shade800,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          SectionTitle(
            title: 'Aksi Cepat',
            trailing: Text(
              'Deadline input ${deadline.batasInputHari} hari',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () =>
                      FormLaporanScreen.push(context, now.year, now.month),
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Isi / Ubah Laporan'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/puskesmas/histori'),
                  icon: const Icon(Icons.history),
                  label: const Text('Histori'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SectionTitle(
            title: 'Laporan Tahun ${now.year}',
            trailing: Text(
              '${semuaLaporan.length} laporan',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 8),
          _PetaBulanTahun(
            laporan: semuaLaporan,
            deadline: deadline,
            tahun: now.year,
          ),
          const SizedBox(height: 24),
          SectionTitle(title: 'Laporan Terbaru'),
          const SizedBox(height: 8),
          if (laporan.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (semuaLaporan.isEmpty)
            EmptyState(
              icon: Icons.inbox_outlined,
              teks:
                  'Belum ada laporan. Tekan "Isi / Ubah Laporan" untuk periode $periode.',
            )
          else
            ..._buildKartuLaporan(context, ref, semuaLaporan, deadline),
        ],
      ),
    );
  }

  List<Widget> _buildKartuLaporan(
    BuildContext context,
    WidgetRef ref,
    List<LaporanModel> list,
    DeadlineModel deadline,
  ) {
    return list.take(3).map((l) {
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context)
                .colorScheme
                .primary
                .withValues(alpha: 0.12),
            child: Icon(
              Icons.calendar_month,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          title: Text(l.labelBulanTahun),
          subtitle: Text(
            'Total ${l.total} pemeriksaan • Diubah ${formatTanggal(l.diubahPada)}',
          ),
          trailing: LaporanStatusBadge(laporan: l, deadline: deadline),
          onTap: () => FormLaporanScreen.push(context, l.tahun, l.bulan),
        ),
      );
    }).toList();
  }
}

/// Kartu status + sisa waktu deadline untuk bulan berjalan.
class _KartuBulanIni extends StatelessWidget {
  const _KartuBulanIni({
    required this.laporan,
    required this.deadline,
    required this.tahun,
    required this.bulan,
  });

  final LaporanModel? laporan;
  final DeadlineModel deadline;
  final int tahun;
  final int bulan;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final belumAda = laporan == null;
    final status = statusTampilan(
      laporan: laporan ?? LaporanModel(
        id: '',
        puskesmasId: '',
        tahun: tahun,
        bulan: bulan,
        status: LaporanStatus.draft,
        hasil: const {},
      ),
      batasInputHari: deadline.batasInputHari,
      batasRevisiHari: deadline.batasRevisiHari,
    );

    final (warna, ikon) = switch (status) {
      'Terkirim' => (Colors.green, Icons.assignment_turned_in_outlined),
      'Revisi Diminta' => (Colors.orange, Icons.refresh),
      'Terlambat' => (Colors.red, Icons.error_outline),
      _ => (Colors.blueGrey, Icons.assignment_late_outlined),
    };

    final sisaHari = _sisaHariDeadline();
    final deadlineInfo = belumAda || status == 'Terlambat'
        ? (sisaHari < 0
            ? 'Deadline sudah terlewati'
            : 'Sisa $sisaHari hari untuk submit')
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: warna.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(ikon, size: 32, color: warna),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status laporan periode berjalan:',
                      style: Theme.of(context).textTheme.bodySmall),
                  Text(status,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: warna,
                            fontWeight: FontWeight.bold,
                          )),
                  if (deadlineInfo != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      deadlineInfo,
                      style: TextStyle(
                        fontSize: 12,
                        color: status == 'Terlambat' ? warna : scheme.onSurfaceVariant,
                        fontWeight: status == 'Terlambat'
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _sisaHariDeadline() {
    final batas = DateTime(tahun, bulan + 1, 1)
        .add(Duration(days: deadline.batasInputHari));
    return batas.difference(DateTime.now()).inDays;
  }
}

/// Peta 12 bulan: warna menandakan status pelaporan tiap bulan, dapat diketuk
/// untuk membuka form bulan tersebut.
class _PetaBulanTahun extends StatelessWidget {
  const _PetaBulanTahun({
    required this.laporan,
    required this.deadline,
    required this.tahun,
  });

  final List<LaporanModel> laporan;
  final DeadlineModel deadline;
  final int tahun;

  @override
  Widget build(BuildContext context) {
    final skema = _WarnaBulan();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Periode pelaporan',
                    style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                Text('$tahun', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 6,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.1,
              children: [
                for (var m = 1; m <= 12; m++)
                  _SelBulan(
                    bulan: m,
                    tahun: tahun,
                    laporan: laporan
                        .where((l) => l.bulan == m && l.tahun == tahun)
                        .firstOrNull,
                    deadline: deadline,
                    warna: skema,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: const [
                _LegendaMini(warna: Colors.blueGrey, label: 'Draft'),
                _LegendaMini(warna: Colors.green, label: 'Terkirim'),
                _LegendaMini(warna: Colors.orange, label: 'Revisi'),
                _LegendaMini(warna: Colors.red, label: 'Terlambat'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SelBulan extends StatelessWidget {
  const _SelBulan({
    required this.bulan,
    required this.tahun,
    required this.laporan,
    required this.deadline,
    required this.warna,
  });

  final int bulan;
  final int tahun;
  final LaporanModel? laporan;
  final DeadlineModel deadline;
  final _WarnaBulan warna;

  @override
  Widget build(BuildContext context) {
    final status = statusTampilan(
      laporan: laporan ??
          LaporanModel(
            id: '',
            puskesmasId: '',
            tahun: tahun,
            bulan: bulan,
            status: LaporanStatus.draft,
            hasil: const {},
          ),
      batasInputHari: deadline.batasInputHari,
      batasRevisiHari: deadline.batasRevisiHari,
    );
    final isi = laporan != null;
    final color = warna.warna(status, isi);

    return Tooltip(
      message: isi
          ? '${AppConstants.namaBulan[bulan - 1]} • $status'
          : '${AppConstants.namaBulan[bulan - 1]} • Belum diisi',
      child: InkWell(
        onTap: () => FormLaporanScreen.push(context, tahun, bulan),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: isi ? 0.55 : 0.25),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Center(
            child: Text(
              AppConstants.namaBulanSingkat[bulan - 1],
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isi ? color : color.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WarnaBulan {
  Color warna(String status, bool isi) {
    if (!isi) return Colors.grey;
    return switch (status) {
      'Terkirim' => Colors.green,
      'Revisi Diminta' => Colors.orange,
      'Terlambat' => Colors.red,
      _ => Colors.blueGrey,
    };
  }
}

class _LegendaMini extends StatelessWidget {
  const _LegendaMini({required this.warna, required this.label});

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
            color: warna.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
