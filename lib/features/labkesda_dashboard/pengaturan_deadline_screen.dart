import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/firestore_service.dart';
import '../../../models/deadline_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/settings_provider.dart';
import '../shared/widgets/admin_portal_components.dart';
import '../shared/widgets/dashboard_shell.dart';

class PengaturanDeadlineScreen extends ConsumerStatefulWidget {
  const PengaturanDeadlineScreen({super.key});

  @override
  ConsumerState<PengaturanDeadlineScreen> createState() =>
      _PengaturanDeadlineScreenState();
}

class _PengaturanDeadlineScreenState
    extends ConsumerState<PengaturanDeadlineScreen> {
  late final TextEditingController _batasInput;
  late final TextEditingController _batasRevisi;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _batasInput = TextEditingController();
    _batasRevisi = TextEditingController();
    _bacaSettings();
  }

  void _bacaSettings() {
    final d = ref.read(deadlineProvider).value;
    if (d != null) {
      _batasInput.text = d.batasInputHari.toString();
      _batasRevisi.text = d.batasRevisiHari.toString();
    }
  }

  @override
  void dispose() {
    _batasInput.dispose();
    _batasRevisi.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    final input = int.tryParse(_batasInput.text);
    final revisi = int.tryParse(_batasRevisi.text);
    if (input == null || input < 0 || revisi == null || revisi < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nilai harus angka non-negatif.')),
      );
      return;
    }
    final admin = ref.read(currentUserProvider).value;
    if (admin == null) return;

    setState(() => _saving = true);
    try {
      await FirestoreService.instance.simpanDeadline(
        DeadlineModel(
          batasInputHari: input,
          satuanBatasInput: 'kalender',
          batasRevisiHari: revisi,
        ),
        admin.uid,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengaturan batas waktu disimpan.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(deadlineProvider, (prev, next) {
      if (next.hasValue && prev?.value == null) {
        final d = next.value!;
        _batasInput.text = d.batasInputHari.toString();
        _batasRevisi.text = d.batasRevisiHari.toString();
      }
    });

    return DashboardShell(
      title: 'Pengaturan Batas Waktu',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 700;
          return Column(
            children: [
              const ScreenHeader(
                title: 'Pengaturan Sistem',
                description:
                    'Atur batas input dan revisi laporan untuk semua puskesmas.',
                padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    isNarrow ? 16 : 24,
                    12,
                    isNarrow ? 16 : 24,
                    32,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildCalendarNotice(context),
                        const SizedBox(height: 16),
                        if (isNarrow) ...[
                          _DeadlineCard(
                            icon: Icons.edit_calendar_outlined,
                            title: 'Batas input laporan',
                            description:
                                'Waktu yang tersedia sejak awal bulan berikutnya untuk mengisi dan mengirim laporan.',
                            controller: _batasInput,
                          ),
                          const SizedBox(height: 16),
                          _DeadlineCard(
                            icon: Icons.history_edu_outlined,
                            title: 'Batas revisi laporan',
                            description:
                                'Waktu yang tersedia setelah laporan dikirim untuk melakukan perubahan.',
                            controller: _batasRevisi,
                          ),
                        ] else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _DeadlineCard(
                                  icon: Icons.edit_calendar_outlined,
                                  title: 'Batas input laporan',
                                  description:
                                      'Waktu yang tersedia sejak awal bulan berikutnya untuk mengisi dan mengirim laporan.',
                                  controller: _batasInput,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _DeadlineCard(
                                  icon: Icons.history_edu_outlined,
                                  title: 'Batas revisi laporan',
                                  description:
                                      'Waktu yang tersedia setelah laporan dikirim untuk melakukan perubahan.',
                                  controller: _batasRevisi,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 20),
                        Align(
                          alignment: isNarrow
                              ? Alignment.center
                              : Alignment.centerRight,
                          child: SizedBox(
                            width: isNarrow ? double.infinity : 220,
                            child: FilledButton.icon(
                              onPressed: _saving ? null : _simpan,
                              icon: _saving
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: Text(
                                _saving ? 'Menyimpan...' : 'Simpan pengaturan',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCalendarNotice(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.calendar_month_outlined, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: 'Semua batas waktu dihitung dalam ',
                children: [
                  TextSpan(
                    text: 'hari kalender',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: colors.primary,
                    ),
                  ),
                  const TextSpan(
                    text:
                        '. Sabtu, Minggu, dan hari libur tetap ikut dihitung.',
                  ),
                ],
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeadlineCard extends StatelessWidget {
  const _DeadlineCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.controller,
  });

  final IconData icon;
  final String title;
  final String description;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AdminCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: colors.secondaryContainer,
            foregroundColor: colors.primary,
            child: Icon(icon),
          ),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(description, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 20),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Jumlah hari kalender',
              suffixText: 'hari',
              helperText: 'Masukkan angka 0 atau lebih',
            ),
          ),
        ],
      ),
    );
  }
}
