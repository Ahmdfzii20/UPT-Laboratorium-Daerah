import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/status_utils.dart';
import '../../../models/deadline_model.dart';
import '../../../models/exam_type_model.dart';
import '../../../models/laporan_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/master_data_providers.dart';
import '../../../providers/settings_provider.dart';
import '../shared/widgets/app_logo.dart';

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

    final laporan = await FirestoreService.instance.getLaporan(
      puskesmasId,
      _tahun,
      _bulan,
    );
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
    final masihDalamBatasInput = masihBisaInput(
      tahun: _tahun,
      bulan: _bulan,
      batasInputHari: deadline.batasInputHari,
    );

    if (_laporan == null) return masihDalamBatasInput;
    if (_laporan!.status == LaporanStatus.draft ||
        _laporan!.status == LaporanStatus.revisionRequested) {
      return masihDalamBatasInput;
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
      await _showInputResult(
        title: 'Input belum dapat disimpan',
        message: 'Data jenis pemeriksaan belum tersedia.',
        isSuccess: false,
      );
      return;
    }
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    final deadline = ref.read(deadlineProvider).value ?? const DeadlineModel();

    if (!masihBisaInput(
      tahun: _tahun,
      bulan: _bulan,
      batasInputHari: deadline.batasInputHari,
    )) {
      await _showInputResult(
        title: 'Input ditolak',
        message: 'Batas waktu input laporan sudah terlewati.',
        isSuccess: false,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final hasil = _collectHasil(examTypes);
      final now = DateTime.now();
      final existing = _laporan;
      final laporanId = FirestoreService.instance.generateLaporanId(
        user.puskesmasId!,
        _tahun,
        _bulan,
      );

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
          status: submit ? LaporanStatus.submitted : existing.status,
          disubmitPada: (submit && existing.disubmitPada == null)
              ? now
              : existing.disubmitPada,
          clearCatatanRevisi:
              submit && existing.status == LaporanStatus.revisionRequested,
        );
        await FirestoreService.instance.updateLaporan(
          laporan,
          user.uid,
          aksi: submit ? 'submit' : 'update',
        );
      }

      if (mounted) {
        await _showInputResult(
          title: submit ? 'Laporan berhasil dikirim' : 'Draft tersimpan',
          message: submit
              ? 'Laporan sudah berhasil dikirim ke Labkesda.'
              : 'Draft laporan berhasil disimpan dan dapat dilanjutkan nanti.',
          isSuccess: true,
        );
        _kembali();
      }
    } catch (e) {
      if (mounted) {
        await _showInputResult(
          title: 'Input gagal disimpan',
          message: 'Terjadi kesalahan saat menyimpan laporan.\n$e',
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showInputResult({
    required String title,
    required String message,
    required bool isSuccess,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final color = isSuccess
            ? Colors.green
            : Theme.of(context).colorScheme.error;
        return AlertDialog(
          icon: Icon(
            isSuccess ? Icons.check_circle_outline : Icons.error_outline,
            color: color,
            size: 64,
          ),
          title: Text(title, textAlign: TextAlign.center),
          content: Text(message, textAlign: TextAlign.center),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(),
              icon: Icon(isSuccess ? Icons.done : Icons.close),
              label: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

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
        .where(
          (e) =>
              e.aktif &&
              (_search.isEmpty ||
                  e.nama.toLowerCase().contains(_search.toLowerCase()) ||
                  e.kategori.toLowerCase().contains(_search.toLowerCase())),
        )
        .toList();

    // Group filtered items by category
    final grouped = <String, List<ExamTypeModel>>{};
    for (final e in filtered) {
      final cat = e.kategori.isNotEmpty ? e.kategori : 'Pemeriksaan Lainnya';
      grouped.putIfAbsent(cat, () => []).add(e);
    }

    final namaBulan = AppConstantsBulan.nama(_bulan);

    return Scaffold(
      backgroundColor: AppTheme.surfaceContainerLow,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
          onPressed: _kembali,
        ),
        title: Text(
          'Form Input',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: AppLogo(size: 28),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Locked / Status Bar Banner
              if (_laporan != null)
                _PanelStatusLaporan(
                  laporan: _laporan!,
                  deadline: deadline,
                  editable: editable,
                ),

              // Search & Parameter Count Header
              Container(
                color: AppTheme.surface,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari jenis pemeriksaan...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppTheme.onSurfaceVariant,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: AppTheme.surfaceContainerLow,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onChanged: (v) => setState(() => _search = v.trim()),
                    ),
                    const SizedBox(height: 8),
                    // Parameter count & draft indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Menampilkan ${filtered.length} Parameter',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: AppTheme.onSurfaceVariant),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryContainer.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Periode $namaBulan $_tahun',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Form Items List
              Expanded(
                child: _loadingData
                    ? const Center(child: CircularProgressIndicator())
                    : grouped.isEmpty
                    ? const Center(
                        child: Text(
                          'Tidak ada jenis pemeriksaan yang cocok.',
                          style: TextStyle(color: AppTheme.onSurfaceVariant),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                        itemCount: grouped.keys.length,
                        itemBuilder: (context, catIndex) {
                          final catName = grouped.keys.elementAt(catIndex);
                          final catItems = grouped[catName]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 12,
                                  bottom: 8,
                                ),
                                child: Text(
                                  catName,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.onSurface,
                                      ),
                                ),
                              ),
                              ...catItems.map((e) {
                                return _ExamItemCard(
                                  examType: e,
                                  controller:
                                      _controllers[e.id] ??
                                      TextEditingController(),
                                  enabled: editable,
                                );
                              }),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),

          // Fixed Bottom Action Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface.withValues(alpha: 0.95),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: SafeArea(
                top: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: (_saving || !editable)
                                  ? null
                                  : () => _simpan(submit: false),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppTheme.primary),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Simpan Draft'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: SizedBox(
                            height: 48,
                            child: FilledButton.icon(
                              onPressed: (_saving || !editable)
                                  ? null
                                  : () => _simpan(submit: true),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: _saving
                                  ? const SizedBox.shrink()
                                  : const Icon(Icons.send, size: 18),
                              label: _saving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Text('Kirim Laporan'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamItemCard extends StatelessWidget {
  const _ExamItemCard({
    required this.examType,
    required this.controller,
    required this.enabled,
  });

  final ExamTypeModel examType;
  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    const satuan = 'sampel';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: enabled
            ? AppTheme.surfaceContainerLowest
            : AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x0F000000)),
        boxShadow: enabled
            ? const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  examType.nama,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: enabled
                        ? AppTheme.onSurface
                        : AppTheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 130,
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: TextFormField(
                          controller: controller,
                          enabled: enabled,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            fillColor: enabled
                                ? AppTheme.surfaceContainerLow
                                : AppTheme.surfaceContainerHigh,
                            hintText: '0',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 36,
                      child: Text(
                        satuan,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (!enabled) ...[
            const SizedBox(height: 4),
            Row(
              children: const [
                Icon(Icons.lock, size: 12, color: AppTheme.onSurfaceVariant),
                SizedBox(width: 4),
                Text(
                  'TERKUNCI',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
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
    final bgColor = terkunci
        ? AppTheme.errorContainer.withValues(alpha: 0.5)
        : AppTheme.tertiaryContainer.withValues(alpha: 0.15);
    final iconColor = terkunci ? AppTheme.error : AppTheme.tertiaryContainer;

    return Container(
      width: double.infinity,
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(
            terkunci ? Icons.lock : Icons.info_outline,
            size: 18,
            color: iconColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              terkunci
                  ? 'Laporan terkunci (batas revisi terlewati). Hubungi Labkesda jika ingin merevisi.'
                  : 'Status: ${laporan.status.label}'
                        '${laporan.disubmitPada != null ? ' • Disubmit ${formatTanggalWaktu(laporan.disubmitPada)}' : ''}'
                        '${laporan.catatanRevisi != null ? '\nCatatan Labkesda: ${laporan.catatanRevisi}' : ''}',
              style: TextStyle(
                fontSize: 12,
                color: terkunci ? AppTheme.error : AppTheme.tertiaryContainer,
                fontWeight: FontWeight.w500,
              ),
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
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return list[month - 1];
  }
}
