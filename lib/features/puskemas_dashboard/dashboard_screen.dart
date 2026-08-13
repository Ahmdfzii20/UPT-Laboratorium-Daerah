import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/status_utils.dart';
import '../../../models/deadline_model.dart';
import '../../../models/laporan_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/laporan_providers.dart';
import '../../../providers/master_data_providers.dart';
import '../../../providers/settings_provider.dart';
import '../shared/widgets/dashboard_shell.dart';
import '../shared/widgets/laporan_status_badge.dart';

class PuskesmasDashboardScreen extends ConsumerWidget {
  const PuskesmasDashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

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
    final periodeBulanIni = laporanBulanIni?.labelBulanTahun ??
        '${AppConstants.namaBulan[now.month - 1]} ${now.year}';

    // Calculate progress percentage of filled parameters for current month
    final filledCount = laporanBulanIni?.hasil.values
            .where((val) => val > 0)
            .length ??
        0;
    final totalParams = laporanBulanIni?.hasil.length ?? 10;
    final progressPct = totalParams > 0
        ? ((filledCount / totalParams) * 100).clamp(0, 100).round()
        : 45; // Default demo progress from Stitch mock if empty

    return DashboardShell(
      title: 'Dashboard Puskesmas',
      sectionName: 'Beranda',
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // Greeting Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_getGreeting()}, Petugas Lab',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppTheme.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                    ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: AppTheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      namaPuskesmas,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Main Card: Current Month Report (Stitch Design)
          _MainCardBulanIni(
            laporan: laporanBulanIni,
            periodeLabel: periodeBulanIni,
            progressPct: progressPct,
            deadline: deadline,
            tahun: now.year,
            bulan: now.month,
          ),
          const SizedBox(height: 24),

          // Recent Reports Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Laporan Terakhir',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              GestureDetector(
                onTap: () => context.go('/puskesmas/histori'),
                child: Text(
                  'Lihat Semua',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // List of Recent Reports
          if (laporan.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (semuaLaporan.isEmpty)
            _EmptyStateRecent(periode: periodeBulanIni)
          else
            ...semuaLaporan.take(3).map((l) {
              return _RecentReportCard(laporan: l, deadline: deadline);
            }),

          const SizedBox(height: 24),

          // Annual 12-Month Map Grid
          _PetaBulanTahun(
            laporan: semuaLaporan,
            deadline: deadline,
            tahun: now.year,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _MainCardBulanIni extends StatelessWidget {
  const _MainCardBulanIni({
    required this.laporan,
    required this.periodeLabel,
    required this.progressPct,
    required this.deadline,
    required this.tahun,
    required this.bulan,
  });

  final LaporanModel? laporan;
  final String periodeLabel;
  final int progressPct;
  final DeadlineModel deadline;
  final int tahun;
  final int bulan;

  @override
  Widget build(BuildContext context) {

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Label + Status Chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LAPORAN BULAN BERJALAN',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppTheme.onSurfaceVariant,
                            letterSpacing: 0.8,
                            fontSize: 11,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      periodeLabel,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurface,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              LaporanStatusBadge(
                laporan: laporan ??
                    LaporanModel(
                      id: '',
                      puskesmasId: '',
                      tahun: tahun,
                      bulan: bulan,
                      status: LaporanStatus.draft,
                      hasil: const {},
                    ),
                deadline: deadline,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress Pengisian',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                    ),
              ),
              Text(
                '$progressPct%',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressPct / 100.0,
              minHeight: 8,
              backgroundColor: AppTheme.surfaceContainerHigh,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
          const SizedBox(height: 16),

          // CTA Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: () => context.push('/puskesmas/form?tahun=$tahun&bulan=$bulan'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.edit_document, size: 20),
              label: Text(
                laporan == null || laporan!.status == LaporanStatus.draft
                    ? 'Lanjutkan Laporan'
                    : 'Lihat / Edit Laporan',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentReportCard extends StatelessWidget {
  const _RecentReportCard({
    required this.laporan,
    required this.deadline,
  });

  final LaporanModel laporan;
  final DeadlineModel deadline;

  @override
  Widget build(BuildContext context) {
    final isRevisi = laporan.status == LaporanStatus.revisionRequested;
    final isLocked = laporan.status == LaporanStatus.submitted &&
        !masihBisaDirevisi(
          disubmitPada: laporan.disubmitPada,
          batasRevisiHari: deadline.batasRevisiHari,
        );

    final iconData = isLocked
        ? Icons.lock
        : (isRevisi ? Icons.warning_amber_rounded : Icons.calendar_month);

    final iconBgColor = isLocked
        ? AppTheme.surfaceContainerHigh
        : (isRevisi
            ? AppTheme.tertiaryContainer.withValues(alpha: 0.15)
            : AppTheme.surfaceContainer);

    final iconColor = isLocked
        ? AppTheme.onSurfaceVariant
        : (isRevisi ? AppTheme.tertiaryContainer : AppTheme.onSurfaceVariant);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isLocked
            ? AppTheme.surfaceContainerLow
            : AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x0F000000)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => context.push(
              '/puskesmas/form?tahun=${laporan.tahun}&bulan=${laporan.bulan}'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(iconData, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        laporan.labelBulanTahun,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        laporan.catatanRevisi != null && isRevisi
                            ? 'Catatan: ${laporan.catatanRevisi}'
                            : (isLocked
                                ? 'Siklus ditutup'
                                : '${laporan.total} Data Pemeriksaan'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isRevisi
                                  ? AppTheme.tertiaryContainer
                                  : AppTheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                LaporanStatusBadge(
                  laporan: laporan,
                  deadline: deadline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyStateRecent extends StatelessWidget {
  const _EmptyStateRecent({required this.periode});

  final String periode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 40, color: AppTheme.outline),
          const SizedBox(height: 8),
          Text(
            'Belum ada laporan.',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Tekan "Lanjutkan Laporan" untuk mengisi periode $periode.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x0F000000)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Periode Pelaporan $tahun',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                '12 Bulan',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: const [
              _LegendaMini(warna: AppTheme.secondary, label: 'Draft'),
              _LegendaMini(warna: AppTheme.primaryContainer, label: 'Terkirim'),
              _LegendaMini(warna: AppTheme.tertiaryContainer, label: 'Revisi'),
              _LegendaMini(warna: AppTheme.error, label: 'Terlambat'),
            ],
          ),
        ],
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
  });

  final int bulan;
  final int tahun;
  final LaporanModel? laporan;
  final DeadlineModel deadline;

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
    final color = switch (status) {
      'Terkirim' => AppTheme.primaryContainer,
      'Revisi Diminta' || 'Revisi' => AppTheme.tertiaryContainer,
      'Terlambat' => AppTheme.error,
      _ => AppTheme.secondary,
    };

    return Tooltip(
      message: isi
          ? '${AppConstants.namaBulan[bulan - 1]} • $status'
          : '${AppConstants.namaBulan[bulan - 1]} • Belum diisi',
      child: InkWell(
        onTap: () => context.push('/puskesmas/form?tahun=$tahun&bulan=$bulan'),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: isi ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Center(
            child: Text(
              AppConstants.namaBulanSingkat[bulan - 1],
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
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
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: warna,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
