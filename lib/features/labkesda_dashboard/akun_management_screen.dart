import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/firestore_service.dart';
import '../../../providers/master_data_providers.dart';
import '../shared/widgets/dashboard_shell.dart';

class AkunManagementScreen extends ConsumerStatefulWidget {
  const AkunManagementScreen({super.key});

  @override
  ConsumerState<AkunManagementScreen> createState() =>
      _AkunManagementScreenState();
}

class _AkunManagementScreenState extends ConsumerState<AkunManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final users = ref.watch(usersProvider).value ?? [];
    final puskesmas = ref.watch(puskesmasListProvider).value ?? [];

    final sortedUsers = [...users]
      ..sort((a, b) {
        if (a.role == b.role) return a.nama.toLowerCase().compareTo(b.nama.toLowerCase());
        return a.role == 'admin' ? -1 : 1;
      });

    return DashboardShell(
      title: 'Manajemen Akun',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _tambahAkun(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Tambah Petugas'),
      ),
      child: users.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: sortedUsers.length,
              itemBuilder: (context, index) {
                final u = sortedUsers[index];
                final namaPuskesmas = u.puskesmasId == null
                    ? ''
                    : puskesmas
                        .where((p) => p.id == u.puskesmasId)
                        .firstOrNull
                        ?.nama;
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Icon(
                        u.isAdmin ? Icons.admin_panel_settings : Icons.person,
                      ),
                    ),
                    title: Text(u.nama),
                    subtitle: Text(
                      '${u.email}\n${u.isAdmin ? 'Admin Labkesda' : 'Petugas: ${namaPuskesmas ?? '-'}'}',
                    ),
                    isThreeLine: true,
                    trailing: u.isAdmin
                        ? const Text('ADMIN',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ))
                        : Switch(
                            value: u.aktif,
                            onChanged: (v) async {
                              await FirestoreService.instance
                                  .nonaktifkanUser(u.uid, v);
                            },
                          ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _tambahAkun(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const _FormTambahAkunDialog(),
    );
    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Akun petugas berhasil dibuat.')),
      );
    }
  }
}

class _FormTambahAkunDialog extends ConsumerStatefulWidget {
  const _FormTambahAkunDialog();

  @override
  ConsumerState<_FormTambahAkunDialog> createState() =>
      _FormTambahAkunDialogState();
}

class _FormTambahAkunDialogState extends ConsumerState<_FormTambahAkunDialog> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _nama = TextEditingController();
  String? _puskesmasId;
  bool _saving = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _nama.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_puskesmasId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih puskesmas terlebih dahulu.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await FirestoreService.instance.buatAkunPuskesmas(
        email: _email.text.trim(),
        password: _password.text,
        puskesmasId: _puskesmasId!,
        nama: _nama.text.trim(),
      );
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
    final puskesmas = ref.watch(puskesmasListProvider).value ?? [];
    final aktif = puskesmas.where((p) => p.aktif).toList();
    if (_puskesmasId == null && aktif.isNotEmpty) {
      _puskesmasId = aktif.first.id;
    }

    return AlertDialog(
      title: const Text('Buat Akun Petugas Puskesmas'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nama,
                  decoration: const InputDecoration(labelText: 'Nama petugas'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'Email tidak valid' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    helperText: 'Minimal 6 karakter',
                  ),
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'Minimal 6 karakter' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _puskesmasId,
                  decoration: const InputDecoration(labelText: 'Puskesmas'),
                  items: [
                    for (final p in aktif)
                      DropdownMenuItem(value: p.id, child: Text(p.nama)),
                  ],
                  onChanged: (v) => setState(() => _puskesmasId = v),
                ),
              ],
            ),
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
          child: _saving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Buat Akun'),
        ),
      ],
    );
  }
}
