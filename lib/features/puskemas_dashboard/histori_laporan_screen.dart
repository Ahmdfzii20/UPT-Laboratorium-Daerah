import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/status_utils.dart';
import '../../../models/deadline_model.dart';
import '../../../models/laporan_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/laporan_providers.dart';
import '../../../providers/settings_provider.dart';
import '../shared/widgets/dashboard_shell.dart';
import '../shared/widgets/laporan_status_badge.dart';

class HistoriLaporanScreen extends ConsumerStatefulWidget {
  const HistoriLaporanScreen({super.key});

  @override
  ConsumerState<HistoriLaporanScreen> createState() =>
      _HistoriLaporanScreenState();
}

class _HistoriLaporanScreenState extends ConsumerState<HistoriLaporanScreen> {
  final _searchController = TextEditingController();
  String _search = '';
  bool _filterExpanded = false;
  String? _filterStatus;
  int? _filterTahun;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _search = '';
      _filterStatus = null;
      _filterTahun = null;
      _filterExpanded = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    final puskesmasId = user?.puskesmasId ?? '';
    final laporan = ref.watch(laporanPuskesmasProvider(puskesmasId));
    final deadline = ref.watch(deadlineProvider).value ?? const DeadlineModel();

    final years = _tahunList();
    final semua = laporan.value ?? [];

    final filtered = semua.where((l) {
      final statusDisplay = statusTampilan(
        laporan: l,
        batasInputHari: deadline.batasInputHari,
        batasRevisiHari: deadline.batasRevisiHari,
      );

      final matchSearch = _search.isEmpty ||
          l.labelBulanTahun.toLowerCase().contains(_search.toLowerCase());

      final matchStatus = _filterStatus == null ||
          (_filterStatus == 'terkirim' && statusDisplay == 'Terkirim') ||
          (_filterStatus == 'revisi' && statusDisplay == 'Revisi Diminta') ||
          (_filterStatus == 'terlambat' && statusDisplay == 'Terlambat') ||
          (_filterStatus == 'draft' && statusDisplay == 'Draft');

      final matchTahun = _filterTahun == null || l.tahun == _filterTahun;

      return matchSearch && matchStatus && matchTahun;
    }).toList();

    final hasActiveFilter =
        _search.isNotEmpty || _filterStatus != null || _filterTahun != null;

    return DashboardShell(
      title: 'Histori Laporan',
      sectionName: 'Histori',
      child: Column(
        children: [
          // Filter Bar Section
          Container(
            color: AppTheme.surfaceContainerLow,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    // Search Pill Input
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Cari laporan...',
                            prefixIcon: Icon(
                              Icons.search,
                              color: AppTheme.onSurfaceVariant,
                              size: 20,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          onChanged: (v) => setState(() => _search = v.trim()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Expand Filter Button
                    Stack(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLowest,
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0A000000),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(
                              _filterExpanded
                                  ? Icons.tune
                                  : Icons.tune_outlined,
                              color: AppTheme.primary,
                              size: 20,
                            ),
                            onPressed: () => setState(
                                () => _filterExpanded = !_filterExpanded),
                          ),
                        ),
                        if (hasActiveFilter)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                // Expanded Filters Panel
                if (_filterExpanded) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x0F000000)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Tahun Dropdown
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tahun',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: AppTheme.onSurfaceVariant,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  DropdownButtonFormField<int?>(
                                    initialValue: _filterTahun,
                                    decoration: InputDecoration(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                      fillColor: AppTheme.surfaceContainerLow,
                                    ),
                                    items: [
                                      const DropdownMenuItem<int?>(
                                        value: null,
                                        child: Text('Semua'),
                                      ),
                                      ...years.map(
                                        (y) => DropdownMenuItem<int?>(
                                          value: y,
                                          child: Text('$y'),
                                        ),
                                      ),
                                    ],
                                    onChanged: (v) =>
                                        setState(() => _filterTahun = v),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Status Dropdown
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Status',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: AppTheme.onSurfaceVariant,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  DropdownButtonFormField<String?>(
                                    initialValue: _filterStatus,
                                    decoration: InputDecoration(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                      fillColor: AppTheme.surfaceContainerLow,
                                    ),
                                    items: const [
                                      DropdownMenuItem<String?>(
                                        value: null,
                                        child: Text('Semua Status'),
                                      ),
                                      DropdownMenuItem<String?>(
                                        value: 'terkirim',
                                        child: Text('Terkirim'),
                                      ),
                                      DropdownMenuItem<String?>(
                                        value: 'revisi',
                                        child: Text('Revisi'),
                                      ),
                                      DropdownMenuItem<String?>(
                                        value: 'terlambat',
                                        child: Text('Terlambat'),
                                      ),
                                      DropdownMenuItem<String?>(
                                        value: 'draft',
                                        child: Text('Draft'),
                                      ),
                                    ],
                                    onChanged: (v) =>
                                        setState(() => _filterStatus = v),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _resetFilters,
                            child: const Text('Reset'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Content List / Empty State
          Expanded(
            child: laporan.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? _EmptyStateHistori(onReset: _resetFilters)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return _HistoryCardItem(
                            laporan: item,
                            deadline: deadline,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  List<int> _tahunList() {
    final now = DateTime.now().year;
    return [for (var y = now; y >= now - 5; y--) y];
  }
}

class _HistoryCardItem extends StatelessWidget {
  const _HistoryCardItem({
    required this.laporan,
    required this.deadline,
  });

  final LaporanModel laporan;
  final DeadlineModel deadline;

  @override
  Widget build(BuildContext context) {
    final statusDisplay = statusTampilan(
      laporan: laporan,
      batasInputHari: deadline.batasInputHari,
      batasRevisiHari: deadline.batasRevisiHari,
    );

    final stripeColor = switch (statusDisplay) {
      'Terkirim' => AppTheme.primary,
      'Revisi Diminta' || 'Revisi' => AppTheme.tertiaryContainer,
      'Terlambat' => AppTheme.error,
      _ => AppTheme.secondary,
    };

    final isRevisi = statusDisplay == 'Revisi Diminta' || statusDisplay == 'Revisi';
    final dikirimLabel = laporan.disubmitPada != null
        ? 'Dikirim: ${formatTanggalWaktu(laporan.disubmitPada)}'
        : 'Diubah: ${formatTanggalWaktu(laporan.diubahPada)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Left Stripe
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              color: stripeColor,
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push(
                  '/puskesmas/form?tahun=${laporan.tahun}&bulan=${laporan.bulan}'),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row: Title & Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                laporan.labelBulanTahun,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.onSurface,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dikirimLabel,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppTheme.onSurfaceVariant,
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

                    // Revisi Note Box if applicable
                    if (isRevisi && laporan.catatanRevisi != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.tertiaryContainer
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 16,
                              color: AppTheme.tertiaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                laporan.catatanRevisi!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppTheme.onSurface,
                                      fontSize: 13,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    const Divider(height: 1, color: AppTheme.surfaceContainerHigh),
                    const SizedBox(height: 10),

                    // Footer Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              statusDisplay == 'Terkirim'
                                  ? Icons.verified_user_outlined
                                  : (isRevisi
                                      ? Icons.edit_document
                                      : Icons.history),
                              size: 18,
                              color: isRevisi
                                  ? AppTheme.tertiaryContainer
                                  : AppTheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              statusDisplay == 'Terkirim'
                                  ? 'Diverifikasi oleh Labkesda'
                                  : (isRevisi
                                      ? 'Perlu Tindakan'
                                      : '${laporan.total} Pemeriksaan'),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: isRevisi
                                        ? AppTheme.tertiaryContainer
                                        : AppTheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: AppTheme.primary,
                          size: 20,
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
}

class _EmptyStateHistori extends StatelessWidget {
  const _EmptyStateHistori({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppTheme.secondaryContainer.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.history_outlined,
                  size: 48,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Belum ada histori laporan',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Data histori untuk filter yang dipilih tidak ditemukan. Coba ubah pencarian atau filter Anda.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 44,
                child: FilledButton(
                  onPressed: onReset,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: const Text('Tampilkan Semua'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
