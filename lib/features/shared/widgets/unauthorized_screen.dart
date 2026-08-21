import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/auth_provider.dart';

class UnauthorizedScreen extends ConsumerWidget {
  const UnauthorizedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authStateProvider).value;
    final currentUser = ref.watch(currentUserProvider).value;
    final message = !kIsWeb && currentUser?.isAdmin == true
      ? 'Akun Admin hanya dapat digunakan melalui versi Web.'
      : authUser == null
        ? 'Sesi login tidak ditemukan. Silakan login kembali.'
        : currentUser == null
          ? 'Data akun Anda belum terdaftar di sistem. Hubungi Admin Labkesda.'
          : !currentUser.aktif
            ? 'Akun Anda sedang dinonaktifkan. Hubungi Admin Labkesda.'
            : 'Anda tidak memiliki izin untuk mengakses halaman ini.';

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block, size: 64, color: Colors.redAccent),
              const SizedBox(height: 16),
              const Text(
                'Akses Ditolak',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  ref.read(authProvider).signOut();
                },
                child: const Text('Keluar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
