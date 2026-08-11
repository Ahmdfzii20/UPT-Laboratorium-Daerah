import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/firestore_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/deadline_model.dart';
import '../../../models/laporan_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/master_data_providers.dart';
import 'laporan_status_badge.dart';

/// Dialog admin: detail laporan + aksi "Minta Revisi", "Buka Kunci" (override),
/// dan tombol lihat histori (audit trail).
Future<void> showAdminLaporanDialog(
  BuildContext context,
  LaporanModel laporan,
  DeadlineModel deadline,
) {
  return showDialog(
    context: context,
    builder: (_) => _AdminLaporanDialog(laporan: laporan, deadline: deadline),
  );
}

class _AdminLaporanDialog extends ConsumerStatefulWidget {
  const _AdminLaporanDialog({required this.laporan, required this.deadline});

  final LaporanModel laporan;
  final DeadlineModel deadline;

  @override
  ConsumerState<_AdminLaporanDialog> createState() => _AdminLaporanDialogState();
}

class _AdminLaporanDialogState extends ConsumerState<_AdminLaporanDialog> {
  final _catatanController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _mintaRevisi() async {
    final catatan = _catatanController.text.trim();
    if (catatan.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Catatan revisi wajib diisi.')));
      return;
    }
    final admin = ref.read(currentUserProvider).value;
    if (admin == null) return;
    setState(() => _saving = true);
    try {
      final updated = widget.laporan.copyWith(
        status: LaporanStatus.revisionRequested,
        catatanRevisi: catatan,
        diubahPada: DateTime.now(),
      );
      await FirestoreService.instance
          .updateLaporan(updated, admin.uid, aksi: 'request_revision');
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Permintaan revisi dikirim.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _bukaKunci() async {
    final admin = ref.read(currentUserProvider).value;
    if (admin == null) return;
    final alasan = _catatanController.text.trim();
    setState(() => _saving = true);
    try {
      final updated = widget.laporan.copyWith(
        status: LaporanStatus.draft,
        catatanRevisi: alasan.isEmpty ? 'Dibuka kunci oleh Labkesda' : alasan,
        diubahPada: DateTime.now(),
      );
      await FirestoreService.instance
          .updateLaporan(updated, admin.uid, aksi: 'admin_override');
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Laporan dibuka kunci.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final examTypes = ref.watch(examTypesProvider).value ?? [];
    final puskesmas = ref.watch(puskesmasListProvider).value ?? [];
    final namaPuskesmas = puskesmas
        .where((p) => p.id == widget.laporan.puskesmasId)
        .firstOrNull
        ?.nama;

    return AlertDialog(
      title: Text('Laporan ${widget.laporan.labelBulanTahun}'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Puskesmas: ${namaPuskesmas ?? '-'}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  LaporanStatusBadge(
                    laporan: widget.laporan,
                    deadline: widget.deadline,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Total: ${widget.laporan.total} pemeriksaan',
                  style: Theme.of(context).textTheme.bodySmall),
              Text('Disubmit: ${formatTanggalWaktu(widget.laporan.disubmitPada)}',
                  style: Theme.of(context).textTheme.bodySmall),
              if (widget.laporan.catatanRevisi != null) ...[
                const SizedBox(height: 8),
                Text('Catatan: ${widget.laporan.catatanRevisi}',
                    style: const TextStyle(fontStyle: FontStyle.italic)),
              ],
              const Divider(height: 24),
              Text('Rincian (nonzero):',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              ...[
                for (final e in examTypes)
                  if ((widget.laporan.hasil[e.id] ?? 0) > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(e.nama)),
                          Text(formatAngka(widget.laporan.hasil[e.id])),
                        ],
                      ),
                    ),
              ],
              if (examTypes.every((e) => (widget.laporan.hasil[e.id] ?? 0) == 0))
                const Text('Semua jenis bernilai 0.'),
              const Divider(height: 24),
              TextField(
                controller: _catatanController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Catatan',
                  hintText: 'Isi catatan revisi / alasan buka kunci',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Tutup'),
        ),
        OutlinedButton(
          onPressed: _saving ? null : _bukaKunci,
          child: const Text('Buka Kunci'),
        ),
        FilledButton(
          onPressed: _saving ? null : _mintaRevisi,
          child: const Text('Minta Revisi'),
        ),
        TextButton.icon(
          onPressed: _saving
              ? null
              : () {
                  Navigator.of(context).pop();
                  context.push('/labkesda/audit/${widget.laporan.id}');
                },
          icon: const Icon(Icons.history),
          label: const Text('Histori'),
        ),
      ],
    );
  }
}
