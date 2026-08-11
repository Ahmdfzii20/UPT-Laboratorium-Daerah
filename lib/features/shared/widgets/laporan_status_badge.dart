import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/deadline_model.dart';
import '../../../models/laporan_model.dart';
import '../../../core/utils/status_utils.dart';
import 'status_chip.dart';

Color statusColor(String status) {
  return switch (status) {
    'submitted' || 'Terkirim' => Colors.green,
    'revision_requested' || 'Revisi Diminta' => Colors.orange,
    'Terlambat' => Colors.red,
    _ => Colors.blueGrey,
  };
}

class LaporanStatusBadge extends ConsumerWidget {
  const LaporanStatusBadge({
    super.key,
    required this.laporan,
    required this.deadline,
  });

  final LaporanModel laporan;
  final DeadlineModel deadline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = statusTampilan(
      laporan: laporan,
      batasInputHari: deadline.batasInputHari,
      batasRevisiHari: deadline.batasRevisiHari,
    );
    return StatusChip(
      label: status,
      color: statusColor(status),
    );
  }
}
