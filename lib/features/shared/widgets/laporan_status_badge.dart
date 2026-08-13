import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/status_utils.dart';
import '../../../models/deadline_model.dart';
import '../../../models/laporan_model.dart';
import 'status_chip.dart';

(Color, IconData?) statusVisuals(String status) {
  return switch (status) {
    'submitted' || 'Terkirim' => (const Color(0xFF005B6F), Icons.check_circle),
    'revision_requested' || 'Revisi Diminta' || 'Revisi' => (
        const Color(0xFF774815),
        Icons.warning,
      ),
    'Terlambat' => (const Color(0xFFBA1A1A), Icons.error_outline),
    'TERKUNCI' => (const Color(0xFF555F71), Icons.lock),
    _ => (const Color(0xFF555F71), null),
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
    final (color, icon) = statusVisuals(status);

    return StatusChip(
      label: status,
      color: color,
      icon: icon,
    );
  }
}
