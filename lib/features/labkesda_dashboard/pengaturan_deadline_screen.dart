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
  String _satuan = 'kalender';
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
      _satuan = d.satuanBatasInput;
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
          satuanBatasInput: _satuan,
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal: $e')));
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
        _satuan = d.satuanBatasInput;
      }
    });

    return DashboardShell(
      title: 'Pengaturan Batas Waktu',
      child: Column(
        children: [
          // Header Section
          ScreenHeader(
            title: 'Pengaturan Sistem',
            description: 'Atur batas waktu input dan revisi laporan untuk semua puskesmas',
          ),
          
          // Settings Content
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: AdminCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Batas Input Laporan (X)',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Jumlah hari sejak awal bulan berikutnya untuk laporan bulan N diinput/disubmit.',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _batasInput,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Batas input (hari)',
                            suffixText: 'hari',
                            helperText: 'Contoh: 15 hari setelah awal bulan berikutnya',
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Batas Revisi Setelah Submit (Y)',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Jumlah hari sejak laporan disubmit, selama itu petugas bebas mengedit.',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _batasRevisi,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Batas revisi (hari)',
                            suffixText: 'hari',
                            helperText: 'Contoh: 3 hari untuk revisi setelah submit',
                          ),
                        ),
                        const SizedBox(height: 24),
                        DropdownButtonFormField<String>(
                          initialValue: _satuan,
                          decoration: const InputDecoration(
                            labelText: 'Satuan Waktu',
                            helperText: 'Pilih jenis penghitungan hari',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'kalender',
                              child: Text('Hari kalender'),
                            ),
                            DropdownMenuItem(
                              value: 'kerja',
                              child: Text('Hari kerja'),
                            ),
                          ],
                          onChanged: (v) => setState(() => _satuan = v ?? 'kalender'),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'MVP hanya menghitung hari kalender. Opsi "hari kerja" disimpan untuk pengembangan lanjutan.',
                                  style: TextStyle(fontSize: 12, color: Colors.blue),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.tonalIcon(
                          onPressed: _saving ? null : _simpan,
                          icon: _saving
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            _saving ? 'Menyimpan...' : 'Simpan Pengaturan',
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
