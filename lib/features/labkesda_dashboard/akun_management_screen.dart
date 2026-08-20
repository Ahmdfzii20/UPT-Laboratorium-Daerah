import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/firestore_service.dart';
import '../../../providers/master_data_providers.dart';
import '../shared/widgets/admin_data_table.dart';
import '../shared/widgets/admin_portal_components.dart';
import '../shared/widgets/dashboard_shell.dart';

class AkunManagementScreen extends ConsumerStatefulWidget {
  const AkunManagementScreen({super.key});

  @override
  ConsumerState<AkunManagementScreen> createState() =>
      _AkunManagementScreenState();
}

class _AkunManagementScreenState extends ConsumerState<AkunManagementScreen> {
  String _searchQuery = '';
  String? _selectedPuskesmas;

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(usersProvider).value ?? [];
    final puskesmas = ref.watch(puskesmasListProvider).value ?? [];
    final isLoading = ref.watch(usersProvider).isLoading;

    final sortedUsers = [...users]
      ..sort((a, b) {
        if (a.role == b.role) return a.nama.toLowerCase().compareTo(b.nama.toLowerCase());
        return a.role == 'admin' ? -1 : 1;
      });

    // Filter users
    final filteredUsers = sortedUsers.where((u) {
      final matchesSearch = _searchQuery.isEmpty ||
          u.nama.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          u.email.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesPuskesmas = _selectedPuskesmas == null ||
          (_selectedPuskesmas == 'admin' && u.isAdmin) ||
          (_selectedPuskesmas != 'admin' && u.puskesmasId == _selectedPuskesmas);

      return matchesSearch && matchesPuskesmas;
    }).toList();

    // Prepare data rows
    final dataRows = filteredUsers.map((u) {
      final namaPuskesmas = u.puskesmasId == null
          ? ''
          : puskesmas.where((p) => p.id == u.puskesmasId).firstOrNull?.nama ?? '-';

      return DataRow(
        cells: [
          DataCell(
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    u.isAdmin ? Icons.admin_panel_settings : Icons.person,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        u.nama,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        u.isAdmin ? 'Analis Kesehatan' : 'Petugas Lab',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          DataCell(Text(namaPuskesmas)),
          DataCell(Text(u.email, overflow: TextOverflow.ellipsis)),
          DataCell(
            Text(
              u.aktif ? 'Aktif' : 'Nonaktif',
              style: TextStyle(
                color: u.aktif ? Colors.green.shade700 : Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          DataCell(
            Wrap(
              spacing: 4,
              children: [
                IconButton(
                  icon: const Icon(Icons.vpn_key_outlined),
                  tooltip: 'Reset Password',
                  iconSize: 18,
                  onPressed: () => _resetPassword(context, u),
                ),
                if (!u.isAdmin)
                  IconButton(
                    icon: u.aktif
                        ? const Icon(Icons.block_outlined)
                        : const Icon(Icons.check_circle_outline),
                    tooltip: u.aktif
                        ? 'Nonaktifkan Akun'
                        : 'Aktifkan Akun',
                    iconSize: 18,
                    onPressed: () => _toggleStatus(context, u),
                  ),
              ],
            ),
          ),
        ],
      );
    }).toList();

    return DashboardShell(
      title: 'Manajemen Akun',
      child: Column(
        children: [
          // Header Section
          ScreenHeader(
            title: 'Manajemen Akun',
            description: 'Kelola akses petugas Puskesmas ke Portal Labkesda.',
            trailing: ElevatedButton.icon(
              onPressed: () => _tambahAkun(context),
              icon: const Icon(Icons.person_add),
              label: const Text('Tambah Petugas'),
            ),
          ),

          // Filter Bar
          FilterBar(
            searchHint: 'Cari nama petugas atau email...',
            searchValue: _searchQuery,
            onSearchChanged: (query) {
              setState(() => _searchQuery = query);
            },
            filters: [
              FilterItem(
                label: 'Semua',
                isSelected: _selectedPuskesmas == null,
                onSelected: (_) {
                  setState(() => _selectedPuskesmas = null);
                },
              ),
              FilterItem(
                label: 'Admin',
                isSelected: _selectedPuskesmas == 'admin',
                onSelected: (_) {
                  setState(() => _selectedPuskesmas = 'admin');
                },
              ),
              ...puskesmas.map(
                (p) => FilterItem(
                  label: p.nama,
                  isSelected: _selectedPuskesmas == p.id,
                  onSelected: (_) {
                    setState(() => _selectedPuskesmas = p.id);
                  },
                ),
              ),
            ],
          ),

          // Data Table
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AdminDataTable(
                columns: [
                  const DataColumn(label: Text('Nama Petugas')),
                  const DataColumn(label: Text('Instansi / Puskesmas')),
                  const DataColumn(label: Text('Email')),
                  const DataColumn(label: Text('Status')),
                  const DataColumn(label: Text('Aksi')),
                ],
                rows: dataRows,
                isLoading: isLoading,
                emptyMessage: 'Tidak ada petugas ditemukan',
              ),
            ),
          ),
        ],
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

  Future<void> _resetPassword(BuildContext context, dynamic user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: Text(
          'Kirim link reset password ke ${user.email}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kirim'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await FirestoreService.instance.resetPassword(user.email);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Link reset password dikirim ke ${user.email}')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal: $e')),
          );
        }
      }
    }
  }

  Future<void> _toggleStatus(BuildContext context, dynamic user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah Status Akun'),
        content: Text(
          user.aktif
              ? 'Nonaktifkan akun ${user.nama}?'
              : 'Aktifkan akun ${user.nama}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ubah'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await FirestoreService.instance.nonaktifkanUser(user.uid, !user.aktif);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Status akun ${user.nama} diubah menjadi ${!user.aktif ? 'Aktif' : 'Nonaktif'}',
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal: $e')),
          );
        }
      }
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
