import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../models/deadline_model.dart';
import '../../../models/laporan_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/laporan_providers.dart';
import '../../../providers/master_data_providers.dart';
import '../../../providers/settings_provider.dart';
import '../shared/widgets/dashboard_shell.dart';
import '../shared/widgets/laporan_status_badge.dart';
import 'form_laporan_screen.dart';

class HistoriLaporanScreen extends ConsumerStatefulWidget {
  const HistoriLaporanScreen({super.key});

  @override
  ConsumerState<HistoriLaporanScreen> createState() => _HistoriLaporanScreenState();
}

class _HistoriLaporanScreenState extends ConsumerState<HistoriLaporanScreen> {
  final _searchController = TextEditingController();
  String _search = '';
  String? _filterStatus;
  int? _filterTahun;
  String? _filterJenisId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    final puskesmasId = user?.puskesmasId ?? '';
    final laporan = ref.watch(laporanPuskesmasProvider(puskesmasId));
    final deadline = ref.watch(deadlineProvider).value ?? const DeadlineModel();
    final examTypes = ref.watch(examTypesProvider).value ?? [];

    final years = _tahunList();
    final sortedExamTypes = [...examTypes]
      ..sort((a, b) => a.urutan.compareTo(b.urutan));
    final filtered = (laporan.value ?? []).where((l) {
      final matchSearch = _search.isEmpty ||
          l.labelBulanTahun.toLowerCase().contains(_search.toLowerCase());
      final matchStatus =
          _filterStatus == null || l.status.value == _filterStatus;
      final matchTahun = _filterTahun == null || l.tahun == _filterTahun;
      final matchJenis = _filterJenisId == null ||
          (l.hasil[_filterJenisId] ?? 0) > 0;
      return matchSearch && matchStatus && matchTahun && matchJenis;
    }).toList();

    return DashboardShell(
      title: 'Histori Laporan',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Cari bulan/tahun…',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _search = v.trim()),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: 120,
                      child: DropdownButtonFormField<int?>(
                        initialValue: _filterTahun,
                        decoration: const InputDecoration(
                          labelText: 'Tahun',
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Semua'),
                          ),
                          ...years.map((y) => DropdownMenuItem<int?>(
                                value: y,
                                child: Text('$y'),
                              )),
                        ],
                        onChanged: (v) => setState(() => _filterTahun = v),
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: DropdownButtonFormField<String?>(
                        initialValue: _filterStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Semua'),
                          ),
                          ...LaporanStatus.values.map((s) =>
                              DropdownMenuItem<String?>(
                                value: s.value,
                                child: Text(s.label),
                              )),
                        ],
                        onChanged: (v) => setState(() => _filterStatus = v),
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      child: DropdownButtonFormField<String?>(
                        initialValue: _filterJenisId,
                        decoration: const InputDecoration(
                          labelText: 'Jenis Pemeriksaan',
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Semua'),
                          ),
                          ...[...sortedExamTypes]
                              .map((e) => DropdownMenuItem<String?>(
                                    value: e.id,
                                    child: Text(e.nama, overflow: TextOverflow.ellipsis),
                                  )),
                        ],
                        onChanged: (v) => setState(() => _filterJenisId = v),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: laporan.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(child: Text('Tidak ada laporan ditemukan.'))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final l = filtered[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(Icons.calendar_month),
                              title: Text(l.labelBulanTahun),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Total: ${l.total} pemeriksaan'),
                                  Text(
                                    'Diubah: ${formatTanggalWaktu(l.diubahPada)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                              trailing: LaporanStatusBadge(
                                laporan: l,
                                deadline: deadline,
                              ),
                              onTap: () => FormLaporanScreen.push(
                                context,
                                l.tahun,
                                l.bulan,
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

  List<int> _tahunList() {
    final now = DateTime.now().year;
    return [for (var y = now; y >= now - 5; y--) y];
  }
}
