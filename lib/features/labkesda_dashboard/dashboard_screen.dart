import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/status_utils.dart';
import '../../../models/deadline_model.dart';
import '../../../models/laporan_model.dart';
import '../../../models/puskesmas_model.dart';
import '../../../providers/laporan_providers.dart';
import '../../../providers/master_data_providers.dart';
import '../../../providers/settings_provider.dart';
import '../shared/widgets/dashboard_cards.dart';
import '../shared/widgets/dashboard_shell.dart';
import '../shared/widgets/mini_bar_chart.dart';

class LabkesdaDashboardScreen extends ConsumerStatefulWidget {
  const LabkesdaDashboardScreen({super.key});

  @override
  ConsumerState<LabkesdaDashboardScreen> createState() =>
      _LabkesdaDashboardScreenState();
}

class _LabkesdaDashboardScreenState
    extends ConsumerState<LabkesdaDashboardScreen> {
  int _tahun = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final puskesmas = ref.watch(puskesmasListProvider).value ?? [];
    final laporan = ref.watch(semuaLaporanProvider(_tahun)).value ?? [];
    final deadline =
        ref.watch(deadlineProvider).value ?? const DeadlineModel();

    final puskesmasAktif = puskesmas.where((p) => p.aktif).toList()
      ..sort((a, b) => a.urutan.compareTo(b.urutan));

    final stats = _hitungStatistik(
      laporan: laporan,
      puskesmasAktif: puskesmasAktif,
      deadline: deadline,
    );

    return DashboardShell(
      title: 'Dashboard Labkesda',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GradientHeader(
            judul: 'Dashboard Admin Labkesmas',
            subjudul: 'Deli Serdang • $_tahun',
            child: Row(
              children: [
                const Icon(Icons.science_outlined, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selamat datang kembali 👋',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pantau pelaporan ${puskesmasAktif.length} puskesmas & kelola data secara cepat.',
                        style:
                            TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: SegmentedButton<int>(
              segments: [
                for (final y in [DateTime.now().year, DateTime.now().year - 1])
                  ButtonSegment(value: y, label: Text('$y')),
              ],
              selected: {_tahun},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _tahun = s.first),
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 700 ? 4 : 2;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: constraints.maxWidth > 700 ? 1.6 : 1.5,
                children: [
                  StatCard(
                    label: 'Puskesmas Aktif',
                    value: '${puskesmasAktif.length}',
                    icon: Icons.local_hospital_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  StatCard(
                    label: 'Laporan Terkirim',
                    value: '${stats.terkirim}',
                    icon: Icons.task_alt,
                    color: Colors.green.shade700,
                  ),
                  StatCard(
                    label: 'Revisi Diminta',
                    value: '${stats.revisi}',
                    icon: Icons.refresh,
                    color: Colors.orange.shade800,
                  ),
                  StatCard(
                    label: 'Terlambat',
                    value: '${stats.terlambat}',
                    icon: Icons.error_outline,
                    color: Colors.red.shade700,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 900;
              final kepatuhan = _KartuKepatuhan(
                terkirim: stats.terkirim,
                totalSel: stats.totalSel,
                persen: stats.persenKepatuhan,
              );
              final tren = _KartuTren(
                perBulan: stats.perBulan,
                warna: Theme.of(context).colorScheme.primary,
              );
              if (!wide) {
                return Column(
                  children: [
                    kepatuhan,
                    const SizedBox(height: 12),
                    tren,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: kepatuhan),
                  const SizedBox(width: 12),
                  Expanded(child: tren),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          SectionTitle(
            title: 'Kepatuhan per Puskesmas',
            trailing: Text(
              '${puskesmasAktif.length} puskesmas • ${AppConstants.namaBulanSingkat.length} bulan',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 8),
          _DaftarKepatuhanPuskesmas(
            puskesmas: puskesmasAktif,
            laporan: laporan,
            tahun: _tahun,
          ),
          const SizedBox(height: 24),
          SectionTitle(title: 'Menu Cepat'),
          const SizedBox(height: 8),
          _MenuGrid(
            items: [
              _MenuItem(
                icon: Icons.grid_view,
                color: Colors.teal,
                title: 'Monitoring Status',
                subtitle: 'Matriks puskesmas × bulan',
                path: '/labkesda/monitoring',
              ),
              _MenuItem(
                icon: Icons.table_chart,
                color: Colors.indigo,
                title: 'Rekap & Export Excel',
                subtitle: 'Tabel gabungan + .xlsx',
                path: '/labkesda/rekap',
              ),
              _MenuItem(
                icon: Icons.storage,
                color: Colors.brown,
                title: 'Master Data',
                subtitle: 'Puskesmas & jenis pemeriksaan',
                path: '/labkesda/master-data',
              ),
              _MenuItem(
                icon: Icons.manage_accounts,
                color: Colors.purple,
                title: 'Manajemen Akun',
                subtitle: 'Buat/nonaktifkan akun',
                path: '/labkesda/akun',
              ),
              _MenuItem(
                icon: Icons.schedule,
                color: Colors.blueGrey,
                title: 'Batas Waktu',
                subtitle: 'Atur deadline input & revisi',
                path: '/labkesda/deadline',
              ),
            ],
          ),
        ],
      ),
    );
  }

  _StatistikLabkesda _hitungStatistik({
    required List<LaporanModel> laporan,
    required List<PuskesmasModel> puskesmasAktif,
    required DeadlineModel deadline,
  }) {
    var terkirim = 0;
    var revisi = 0;
    var terlambat = 0;
    final perBulan = List<int>.filled(12, 0);
    final terkirimPerPuskesmas = <String, int>{
      for (final p in puskesmasAktif) p.id: 0,
    };

    for (final l in laporan) {
      switch (statusTampilan(
        laporan: l,
        batasInputHari: deadline.batasInputHari,
        batasRevisiHari: deadline.batasRevisiHari,
      )) {
        case 'Terkirim':
          terkirim++;
          perBulan[l.bulan - 1]++;
          if (terkirimPerPuskesmas.containsKey(l.puskesmasId)) {
            terkirimPerPuskesmas[l.puskesmasId] =
                terkirimPerPuskesmas[l.puskesmasId]! + 1;
          }
        case 'Revisi Diminta':
          revisi++;
        case 'Terlambat':
          terlambat++;
      }
    }

    final totalSel = puskesmasAktif.length * 12;
    final totalTerkirim = terkirimPerPuskesmas.values.fold<int>(
      0,
      (sum, v) => sum + v,
    );
    final persen = totalSel == 0
        ? 0.0
        : (totalTerkirim / totalSel).clamp(0.0, 1.0).toDouble();

    return _StatistikLabkesda(
      terkirim: terkirim,
      revisi: revisi,
      terlambat: terlambat,
      perBulan: perBulan,
      terkirimPerPuskesmas: terkirimPerPuskesmas,
      totalSel: totalSel,
      persenKepatuhan: persen,
    );
  }
}

class _StatistikLabkesda {
  const _StatistikLabkesda({
    required this.terkirim,
    required this.revisi,
    required this.terlambat,
    required this.perBulan,
    required this.terkirimPerPuskesmas,
    required this.totalSel,
    required this.persenKepatuhan,
  });

  final int terkirim;
  final int revisi;
  final int terlambat;
  final List<int> perBulan;
  final Map<String, int> terkirimPerPuskesmas;
  final int totalSel;
  final double persenKepatuhan;
}

class _KartuKepatuhan extends StatelessWidget {
  const _KartuKepatuhan({
    required this.terkirim,
    required this.totalSel,
    required this.persen,
  });

  final int terkirim;
  final int totalSel;
  final double persen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pct = (persen * 100).round();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.insights, color: scheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kepatuhan Tahunan',
                          style: Theme.of(context).textTheme.titleSmall),
                      Text(
                        '$terkirim dari $totalSel laporan terkirim',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  '$pct%',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: persen,
                minHeight: 12,
                backgroundColor: scheme.primary.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(scheme.primary),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Jumlah laporan terkirim dibanding total periode pelaporan tahun berjalan.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _KartuTren extends StatelessWidget {
  const _KartuTren({required this.perBulan, required this.warna});

  final List<int> perBulan;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tren Laporan Terkirim',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              'Per bulan • ${DateTime.now().year}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            MiniBarChart(
              color: warna,
              height: 130,
              points: [
                for (var m = 0; m < 12; m++)
                  BarChartPoint(
                    AppConstants.namaBulanSingkat[m],
                    perBulan[m],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DaftarKepatuhanPuskesmas extends StatelessWidget {
  const _DaftarKepatuhanPuskesmas({
    required this.puskesmas,
    required this.laporan,
    required this.tahun,
  });

  final List<PuskesmasModel> puskesmas;
  final List<LaporanModel> laporan;
  final int tahun;

  @override
  Widget build(BuildContext context) {
    final laporanTahun = laporan.where((l) => l.tahun == tahun).toList();

    if (puskesmas.isEmpty) {
      return const EmptyState(
        icon: Icons.local_hospital_outlined,
        teks: 'Belum ada puskesmas terdaftar.',
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            for (var i = 0; i < puskesmas.length; i++)
              _RowKepatuhan(
                puskesmas: puskesmas[i],
                laporan: laporanTahun,
                nomor: i + 1,
              ),
          ],
        ),
      ),
    );
  }
}

class _RowKepatuhan extends StatelessWidget {
  const _RowKepatuhan({
    required this.puskesmas,
    required this.laporan,
    required this.nomor,
  });

  final PuskesmasModel puskesmas;
  final List<LaporanModel> laporan;
  final int nomor;

  @override
  Widget build(BuildContext context) {
    final laporanPuskesmas =
        laporan.where((l) => l.puskesmasId == puskesmas.id).toList();
    final terkirim = laporanPuskesmas
        .where((l) => l.status == LaporanStatus.submitted)
        .length;

    return ProgressRow(
      label: '$nomor. ${puskesmas.nama}',
      value: terkirim,
      max: 12,
      detail: '$terkirim/12 bulan',
      color: Colors.teal.shade700,
      onTap: () => context.go('/labkesda/monitoring'),
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.path,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String path;
}

class _MenuGrid extends StatelessWidget {
  const _MenuGrid({required this.items});

  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 700 ? 2 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 88,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final m = items[index];
            return Card(
              child: InkWell(
                onTap: () => context.go(m.path),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: m.color.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(m.icon, color: m.color, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.title,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              m.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
