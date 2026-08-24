import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Wajib sebelum memakai DateFormat ber-locale 'id_ID' (formatTanggal dkk).
  await initializeDateFormatting('id_ID');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Offline persistence: petugas tetap bisa isi form saat koneksi lemah (§9).
  FirebaseFirestore.instance.settings =
      const Settings(persistenceEnabled: true);
  runApp(const ProviderScope(child: LabkesdaApp()));
}

class LabkesdaApp extends ConsumerWidget {
  const LabkesdaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      title: 'Labkesmas Deli Serdang',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
