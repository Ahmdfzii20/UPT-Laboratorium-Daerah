import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../providers/master_data_providers.dart';
import '../shared/widgets/dashboard_shell.dart';

class InputLaporanScreen extends ConsumerStatefulWidget {
  const InputLaporanScreen({super.key});

  @override
  ConsumerState<InputLaporanScreen> createState() => _InputLaporanScreenState();
}

class _InputLaporanScreenState extends ConsumerState<InputLaporanScreen> {
  String? _puskesmasId;
  int _tahun = DateTime.now().year;
  int _bulan = DateTime.now().month;

  @override
  Widget build(BuildContext context) {
    final puskesmas = [...(ref.watch(puskesmasListProvider).value ?? [])]
      ..sort((a, b) => a.urutan.compareTo(b.urutan));

    return DashboardShell(
      title: 'Input Laporan',
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Input Laporan Puskesmas',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Admin dapat mengisi atau memperbarui laporan untuk Puskesmas mana pun.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      initialValue: _puskesmasId,
                      decoration: const InputDecoration(
                        labelText: 'Puskesmas',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final p in puskesmas)
                          DropdownMenuItem(
                            value: p.id,
                            child: Text(p.nama),
                          ),
                      ],
                      onChanged: (value) =>
                          setState(() => _puskesmasId = value),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _tahun,
                            decoration: const InputDecoration(
                              labelText: 'Tahun',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              for (final year in [
                                DateTime.now().year,
                                DateTime.now().year - 1,
                              ])
                                DropdownMenuItem(
                                  value: year,
                                  child: Text('$year'),
                                ),
                            ],
                            onChanged: (value) => setState(
                              () => _tahun = value ?? _tahun,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _bulan,
                            decoration: const InputDecoration(
                              labelText: 'Bulan',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              for (var month = 1; month <= 12; month++)
                                DropdownMenuItem(
                                  value: month,
                                  child: Text(AppConstants.namaBulan[month - 1]),
                                ),
                            ],
                            onChanged: (value) => setState(
                              () => _bulan = value ?? _bulan,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _puskesmasId == null
                          ? null
                          : () => context.push(
                            '/labkesda/form?puskesmasId=$_puskesmasId&tahun=$_tahun&bulan=$_bulan',
                              ),
                      icon: const Icon(Icons.edit_note),
                      label: const Text('Buka Form Laporan'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
