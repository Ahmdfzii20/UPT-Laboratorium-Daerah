import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/firestore_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/laporan_model.dart';
import '../../../providers/laporan_providers.dart';
import '../../../providers/master_data_providers.dart';

class AuditTrailScreen extends ConsumerStatefulWidget {
  const AuditTrailScreen({super.key, required this.laporanId});

  final String laporanId;

  @override
  ConsumerState<AuditTrailScreen> createState() => _AuditTrailScreenState();
}

class _AuditTrailScreenState extends ConsumerState<AuditTrailScreen> {
  LaporanModel? _laporan;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    try {
      final l = await FirestoreService.instance.getLaporanById(widget.laporanId);
      if (mounted) setState(() => _laporan = l);
    } catch (_) {}
  }

  String _labelAksi(String aksi) {
    return switch (aksi) {
      'create' => 'Dibuat',
      'update' => 'Diubah',
      'submit' => 'Disubmit',
      'request_revision' => 'Revisi Diminta (Labkesda)',
      'admin_override' => 'Override / Buka Kunci (Labkesda)',
      _ => aksi,
    };
  }

  @override
  Widget build(BuildContext context) {
    final histori = ref.watch(historiLaporanProvider(widget.laporanId));
    final puskesmas = ref.watch(puskesmasListProvider).value ?? [];

    final namaPuskesmas = puskesmas
        .where((p) => p.id == _laporan?.puskesmasId)
        .firstOrNull
        ?.nama;

    return Scaffold(
      appBar: AppBar(title: const Text('Audit Trail')),
      body: Column(
        children: [
          if (_laporan != null)
            Card(
              margin: const EdgeInsets.all(12),
              child: ListTile(
                leading: const Icon(Icons.assignment_outlined),
                title: Text(
                  'Laporan ${_laporan!.labelBulanTahun}',
                ),
                subtitle: Text(
                  '${namaPuskesmas ?? '-'}\n'
                  'Status: ${_laporan!.status.label} • Total: ${_laporan!.total}',
                ),
                isThreeLine: true,
              ),
            ),
          Expanded(
            child: histori.isLoading
                ? const Center(child: CircularProgressIndicator())
                : histori.value!.isEmpty
                    ? const Center(child: Text('Belum ada histori.'))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        itemCount: histori.value!.length,
                        itemBuilder: (context, index) {
                          final h = histori.value![index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Icon(
                                  switch (h['aksi']) {
                                    'submit' => Icons.send,
                                    'create' => Icons.add_circle_outline,
                                    'request_revision' => Icons.refresh,
                                    'admin_override' => Icons.lock_open,
                                    _ => Icons.edit,
                                  },
                                ),
                              ),
                              title: Text(_labelAksi(h['aksi']?.toString() ?? '')),
                              subtitle: Text(
                                '${formatTanggalWaktu(h['diubahPada'] as DateTime?)}\n'
                                'Oleh: ${h['diubahOleh']}',
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
