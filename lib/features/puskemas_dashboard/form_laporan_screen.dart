import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/firestore_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/status_utils.dart';
import '../../../models/deadline_model.dart';
import '../../../models/exam_type_model.dart';
import '../../../models/laporan_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/master_data_providers.dart';
import '../../../providers/settings_provider.dart';

class FormLaporanScreen extends ConsumerStatefulWidget {
  const FormLaporanScreen({super.key});

  static void push(BuildContext context, int tahun, int bulan) {
    context.push('/puskesmas/form?tahun=$tahun&bulan=$bulan');
  }

  @override
  ConsumerState<FormLaporanScreen> createState() => _FormLaporanScreenState();
}

class _FormLaporanScreenState extends ConsumerState<FormLaporanScreen> {
  final _searchController = TextEditingController();
  Map<String, TextEditingController> _controllers = {};
  String _search = '';
  bool _loadingData = true;
  bool _saving = false;
  LaporanModel? _laporan;

  int get _tahun {
    final t = GoRouterState.of(context).uri.queryParameters['tahun'];
    return int.tryParse(t ?? '') ?? DateTime.now().year;
  }

  int get _bulan {
    final b = GoRouterState.of(context).uri.queryParameters['bulan'];
    return int.tryParse(b ?? '') ?? DateTime.now().month;
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _mulaiLoadData());
  }

  Future<void> _mulaiLoadData() async {
    final user = ref.read(currentUserProvider).value;
    final puskesmasId = user?.puskesmasId;
    if (puskesmasId == null) return;
    final examTypes = ref.read(examTypesProvider).value ?? [];
    if (examTypes.isEmpty) return;

    final laporan = await FirestoreService.instance
        .getLaporan(puskesmasId, _tahun, _bulan);
    if (!mounted) return;
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers = {
      for (final e in examTypes)
        e.id: TextEditingController(
          text: (laporan?.hasil[e.id] ?? 0).toString(),
        ),
    };
    setState(() {
      _laporan = laporan;
      _loadingData = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool _isEditable(DeadlineModel deadline) {
    if (_laporan == null) return true;
    if (_laporan!.status == LaporanStatus.draft ||
        _laporan!.status == LaporanStatus.revisionRequested) {
      return true;
    }
    return masihBisaDirevisi(
      disubmitPada: _laporan!.disubmitPada,
      batasRevisiHari: deadline.batasRevisiHari,
    );
  }

  Map<String, num> _collectHasil(List<ExamTypeModel> examTypes) {
    final hasil = <String, num>{};
    for (final e in examTypes) {
      hasil[e.id] = int.tryParse(_controllers[e.id]?.text ?? '') ?? 0;
    }
    return hasil;
  }

  Future<void> _simpan({required bool submit}) async {
    final examTypes = ref.read(examTypesProvider).value ?? [];
    if (examTypes.isEmpty) {
      _showSnack('Data jenis pemeriksaan belum tersedia.');
      return;
    }
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      final hasil = _collectHasil(examTypes);
      final now = DateTime.now();
      final existing = _laporan;
      final laporanId = FirestoreService.instance
          .generateLaporanId(user.puskesmasId!, _tahun, _bulan);

      if (existing == null) {
        final laporan = LaporanModel(
          id: laporanId,
          puskesmasId: user.puskesmasId!,
          tahun: _tahun,
          bulan: _bulan,
          status: submit ? LaporanStatus.submitted : LaporanStatus.draft,
          hasil: hasil,
          dibuatOleh: user.uid,
          dibuatPada: now,
          diubahPada: now,
          disubmitPada: submit ? now : null,
        );
        await FirestoreService.instance.createLaporan(laporan, user.uid);
      } else {
        final laporan = existing.copyWith(
          hasil: hasil,
          diubahPada: now,
          status: submit
              ? LaporanStatus.submitted
              : existing.status,
          disubmitPada: (submit && existing.disubmitPada == null)
              ? now
              : existing.disubmitPada,
          clearCatatanRevisi: submit && existing.status == LaporanStatus.revisionRequested,
        );
        await FirestoreService.instance.updateLaporan(
          laporan,
          user.uid,
          aksi: submit ? 'submit' : 'update',
        );
      }

      if (mounted) {
        _showSnack(submit
            ? 'Laporan berhasil dikirim ke Labkesda.'
            : 'Draft berhasil disimpan.');
        _kembali();
      }
    } catch (e) {
      if (mounted) _showSnack('Gagal menyimpan: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Kembali aman: jika layar dibuka lewat `push` cukup pop, tapi jika dibuka
  /// lewat menu navigasi (`context.go`) dan tidak ada tumpukan, kembali ke
  /// dashboard.
  void _kembali() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/puskesmas/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final examTypesRaw = ref.watch(examTypesProvider).value ?? [];
    final examTypes = [...examTypesRaw]
      ..sort((a, b) => a.urutan.compareTo(b.urutan));
    final deadline = ref.watch(deadlineProvider).value ?? const DeadlineModel();

    final editable = _isEditable(deadline);
    final filtered = examTypes
        .where((e) =>
            e.aktif &&
            (_search.isEmpty || e.nama.toLowerCase().contains(_search.toLowerCase())))
        .toList();

    final appBar = AppBar(
      title: Text(
        'Laporan ${AppConstantsBulan.nama(_bulan)} $_tahun',
        style: const TextStyle(fontSize: 18),
      ),
      leading: BackButton(onPressed: _kembali),
    );

    return Scaffold(
      appBar: appBar,
      body: Column(
        children: [
          if (_laporan != null)
            _PanelStatusLaporan(
              laporan: _laporan!,
              deadline: deadline,
              editable: editable,
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Cari jenis pemeriksaan…',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _search = v.trim()),
            ),
          ),
          Expanded(
            child: _loadingData
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: filtered.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '${filtered.length} jenis pemeriksaan ditemukan',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        );
                      }
                      final e = filtered[index - 1];
                      return _FieldJenisPemeriksaan(
                        examType: e,
                        controller: _controllers[e.id]!,
                        enabled: editable,
                        isLast: index == filtered.length,
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: (_saving || !editable) ? null : () => _simpan(submit: false),
                      child: const Text('Simpan Draft'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: (_saving || !editable) ? null : () => _simpan(submit: true),
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Submit'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldJenisPemeriksaan extends StatelessWidget {
  const _FieldJenisPemeriksaan({
    required this.examType,
    required this.controller,
    required this.enabled,
    required this.isLast,
  });

  final ExamTypeModel examType;
  final TextEditingController controller;
  final bool enabled;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(examType.nama, style: const TextStyle(fontSize: 14)),
            ),
            SizedBox(
              width: 120,
              child: TextFormField(
                controller: controller,
                enabled: enabled,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  labelText: 'Jumlah',
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelStatusLaporan extends StatelessWidget {
  const _PanelStatusLaporan({
    required this.laporan,
    required this.deadline,
    required this.editable,
  });

  final LaporanModel laporan;
  final DeadlineModel deadline;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final terkunci = !editable;
    return Container(
      width: double.infinity,
      color: terkunci ? Colors.red.shade50 : Colors.amber.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            terkunci ? Icons.lock_outline : Icons.info_outline,
            size: 18,
            color: terkunci ? Colors.red : Colors.orange.shade800,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              terkunci
                  ? 'Laporan terkunci (batas revisi terlewati). Hubungi Labkesda jika ingin merevisi.'
                  : 'Status: ${laporan.status.label}'
                        '${laporan.disubmitPada != null ? ' • Disubmit ${formatTanggalWaktu(laporan.disubmitPada)}' : ''}'
                        '${laporan.catatanRevisi != null ? '\nCatatan Labkesda: ${laporan.catatanRevisi}' : ''}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class AppConstantsBulan {
  static String nama(int month) {
    const list = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return list[month - 1];
  }
}
