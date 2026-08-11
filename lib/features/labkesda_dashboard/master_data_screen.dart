import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/firestore_service.dart';
import '../../../models/exam_type_model.dart';
import '../../../models/puskesmas_model.dart';
import '../../../providers/master_data_providers.dart';
import '../shared/widgets/dashboard_shell.dart';

class MasterDataScreen extends ConsumerStatefulWidget {
  const MasterDataScreen({super.key});

  @override
  ConsumerState<MasterDataScreen> createState() => _MasterDataScreenState();
}

class _MasterDataScreenState extends ConsumerState<MasterDataScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      title: 'Master Data',
      tabBar: TabBar(
        controller: _tabController,
        tabs: const [Tab(text: 'Puskesmas'), Tab(text: 'Jenis Pemeriksaan')],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _editPuskesmas(context, ref, null);
          } else {
            _editExamType(context, ref, null);
          }
        },
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 0
            ? 'Tambah Puskesmas'
            : 'Tambah Jenis Pemeriksaan'),
      ),
      child: TabBarView(
        controller: _tabController,
        children: [
          _TabPuskesmas(onEdit: (p) => _editPuskesmas(context, ref, p)),
          _TabExamTypes(onEdit: (e) => _editExamType(context, ref, e)),
        ],
      ),
    );
  }

  Future<void> _editPuskesmas(
    BuildContext context,
    WidgetRef ref,
    PuskesmasModel? existing,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _FormPuskesmasDialog(existing: existing),
    );
    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Puskesmas disimpan.')));
    }
  }

  Future<void> _editExamType(
    BuildContext context,
    WidgetRef ref,
    ExamTypeModel? existing,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _FormExamTypeDialog(existing: existing),
    );
    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jenis pemeriksaan disimpan.')),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Puskesmas
// ---------------------------------------------------------------------------

class _TabPuskesmas extends ConsumerWidget {
  const _TabPuskesmas({required this.onEdit});

  final void Function(PuskesmasModel) onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final puskesmas = ref.watch(puskesmasListProvider).value ?? [];
    final sorted = [...puskesmas]..sort((a, b) => a.urutan.compareTo(b.urutan));

    return puskesmas.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final p = sorted[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(p.nama),
                  subtitle: Text(
                    'Kode: ${p.kode.isEmpty ? '-' : p.kode} • Kecamatan: ${p.kecamatan.isEmpty ? '-' : p.kecamatan}',
                  ),
                  leading: CircleAvatar(
                    child: Text('${index + 1}'),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => onEdit(p),
                      ),
                      Switch(
                        value: p.aktif,
                        onChanged: (v) async {
                          await FirestoreService.instance.simpanPuskesmas(
                            PuskesmasModel(
                              id: p.id,
                              nama: p.nama,
                              kode: p.kode,
                              kecamatan: p.kecamatan,
                              urutan: p.urutan,
                              aktif: v,
                            ),
                            docId: p.id,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }
}

class _FormPuskesmasDialog extends StatefulWidget {
  const _FormPuskesmasDialog({this.existing});

  final PuskesmasModel? existing;

  @override
  State<_FormPuskesmasDialog> createState() => _FormPuskesmasDialogState();
}

class _FormPuskesmasDialogState extends State<_FormPuskesmasDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nama;
  late final TextEditingController _kode;
  late final TextEditingController _kecamatan;
  late final TextEditingController _urutan;
  late bool _aktif;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nama = TextEditingController(text: widget.existing?.nama);
    _kode = TextEditingController(text: widget.existing?.kode);
    _kecamatan = TextEditingController(text: widget.existing?.kecamatan);
    _urutan = TextEditingController(
        text: (widget.existing?.urutan ?? 0).toString());
    _aktif = widget.existing?.aktif ?? true;
  }

  @override
  void dispose() {
    _nama.dispose();
    _kode.dispose();
    _kecamatan.dispose();
    _urutan.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final model = PuskesmasModel(
        id: widget.existing?.id ?? '',
        nama: _nama.text.trim(),
        kode: _kode.text.trim(),
        kecamatan: _kecamatan.text.trim(),
        urutan: int.tryParse(_urutan.text) ?? 0,
        aktif: _aktif,
      );
      await FirestoreService.instance
          .simpanPuskesmas(model, docId: widget.existing?.id);
      if (mounted) Navigator.of(context).pop(true);
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
    return AlertDialog(
      title: Text(widget.existing == null ? 'Tambah Puskesmas' : 'Edit Puskesmas'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nama,
                decoration: const InputDecoration(labelText: 'Nama'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _kode,
                decoration: const InputDecoration(labelText: 'Kode'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _kecamatan,
                decoration: const InputDecoration(labelText: 'Kecamatan'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _urutan,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Urutan'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Aktif'),
                value: _aktif,
                onChanged: (v) => setState(() => _aktif = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _saving ? null : _simpan,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Jenis pemeriksaan
// ---------------------------------------------------------------------------

class _TabExamTypes extends ConsumerWidget {
  const _TabExamTypes({required this.onEdit});

  final void Function(ExamTypeModel) onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examTypes = ref.watch(examTypesProvider).value ?? [];
    final sorted = [...examTypes]..sort((a, b) => a.urutan.compareTo(b.urutan));

    return examTypes.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final e = sorted[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(e.nama),
                  subtitle: Text(
                    'Urutan ${e.urutan}${e.kategori.isEmpty ? '' : ' • ${e.kategori}'}',
                  ),
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => onEdit(e),
                      ),
                      Switch(
                        value: e.aktif,
                        onChanged: (v) async {
                          await FirestoreService.instance.simpanExamType(
                            ExamTypeModel(
                              id: e.id,
                              nama: e.nama,
                              urutan: e.urutan,
                              kategori: e.kategori,
                              aktif: v,
                            ),
                            docId: e.id,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }
}

class _FormExamTypeDialog extends StatefulWidget {
  const _FormExamTypeDialog({this.existing});

  final ExamTypeModel? existing;

  @override
  State<_FormExamTypeDialog> createState() => _FormExamTypeDialogState();
}

class _FormExamTypeDialogState extends State<_FormExamTypeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nama;
  late final TextEditingController _urutan;
  late final TextEditingController _kategori;
  late bool _aktif;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nama = TextEditingController(text: widget.existing?.nama);
    _urutan = TextEditingController(
        text: (widget.existing?.urutan ?? 0).toString());
    _kategori = TextEditingController(text: widget.existing?.kategori);
    _aktif = widget.existing?.aktif ?? true;
  }

  @override
  void dispose() {
    _nama.dispose();
    _urutan.dispose();
    _kategori.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final model = ExamTypeModel(
        id: widget.existing?.id ?? '',
        nama: _nama.text.trim(),
        urutan: int.tryParse(_urutan.text) ?? 0,
        kategori: _kategori.text.trim(),
        aktif: _aktif,
      );
      await FirestoreService.instance
          .simpanExamType(model, docId: widget.existing?.id);
      if (mounted) Navigator.of(context).pop(true);
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
    return AlertDialog(
      title: Text(widget.existing == null
          ? 'Tambah Jenis Pemeriksaan'
          : 'Edit Jenis Pemeriksaan'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nama,
                decoration: const InputDecoration(labelText: 'Nama'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _urutan,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Urutan'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _kategori,
                decoration: const InputDecoration(
                  labelText: 'Kategori (opsional)',
                  hintText: 'Darah / Urine / Serologi, dst.',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Aktif'),
                value: _aktif,
                onChanged: (v) => setState(() => _aktif = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _saving ? null : _simpan,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
