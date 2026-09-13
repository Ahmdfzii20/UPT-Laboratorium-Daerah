import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/forgot_password_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/labkesda_dashboard/akun_management_screen.dart';
import '../features/labkesda_dashboard/audit_trail_screen.dart';
import '../features/labkesda_dashboard/dashboard_screen.dart';
import '../features/labkesda_dashboard/input_laporan_screen.dart';
import '../features/labkesda_dashboard/master_data_screen.dart';
import '../features/labkesda_dashboard/monitoring_status_screen.dart';
import '../features/labkesda_dashboard/pengaturan_deadline_screen.dart';
import '../features/labkesda_dashboard/rekap_table_screen.dart';
import '../features/puskemas_dashboard/dashboard_screen.dart';
import '../features/puskemas_dashboard/form_laporan_screen.dart';
import '../features/puskemas_dashboard/histori_laporan_screen.dart';
import '../features/shared/widgets/unauthorized_screen.dart';
import '../providers/auth_provider.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ValueNotifier<int>(0);

  ref.listen(authStateProvider, (_, _) => notifier.value++);
  ref.listen(currentUserProvider, (_, _) => notifier.value++);

  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final isLoggedIn = ref.read(authStateProvider).value != null;
      final currentUserState = ref.read(currentUserProvider);
      final user = currentUserState.value;
      final location = state.matchedLocation;

      final isAuthPage = location == '/login' || location == '/forgot-password';

      if (isLoggedIn) {
        // Tunggu dokumen /users/{uid} termuat sebelum memutuskan redirect.
        if (currentUserState.isLoading) return null;
        if (user == null || !user.aktif) {
          return location == '/unauthorized' ? null : '/unauthorized';
        }
        
        if (user.isAdmin && !kIsWeb) {
          return location == '/unauthorized' ? null : '/unauthorized';
        }
        final home = user.isAdmin
            ? '/labkesda/dashboard'
            : '/puskesmas/dashboard';

        if (isAuthPage || location == '/') return home;

        if (user.isAdmin && location.startsWith('/puskesmas')) return home;
        if (!user.isAdmin && location.startsWith('/labkesda')) return home;

        return null;
      }

      // Belum login
      if (!isAuthPage && location != '/unauthorized') return '/login';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/unauthorized',
        builder: (context, state) => const UnauthorizedScreen(),
      ),
      GoRoute(
        path: '/puskesmas/dashboard',
        builder: (context, state) => const PuskesmasDashboardScreen(),
      ),
      GoRoute(
        path: '/puskesmas/form',
        builder: (context, state) => const FormLaporanScreen(),
      ),
      GoRoute(
        path: '/puskesmas/histori',
        builder: (context, state) => const HistoriLaporanScreen(),
      ),
      GoRoute(
        path: '/labkesda/dashboard',
        builder: (context, state) => const LabkesdaDashboardScreen(),
      ),
      GoRoute(
        path: '/labkesda/input',
        builder: (context, state) => const InputLaporanScreen(),
      ),
      GoRoute(
        path: '/labkesda/form',
        builder: (context, state) => const FormLaporanScreen(),
      ),
      GoRoute(
        path: '/labkesda/rekap',
        builder: (context, state) => const RekapTableScreen(),
      ),
      GoRoute(
        path: '/labkesda/monitoring',
        builder: (context, state) => const MonitoringStatusScreen(),
      ),
      GoRoute(
        path: '/labkesda/master-data',
        builder: (context, state) => const MasterDataScreen(),
      ),
      GoRoute(
        path: '/labkesda/akun',
        builder: (context, state) => const AkunManagementScreen(),
      ),
      GoRoute(
        path: '/labkesda/deadline',
        builder: (context, state) => const PengaturanDeadlineScreen(),
      ),
      GoRoute(
        path: '/labkesda/audit/:laporanId',
        builder: (context, state) => AuditTrailScreen(
          laporanId: state.pathParameters['laporanId']!,
        ),
      ),
    ],
  );

  ref.onDispose(notifier.dispose);
  return router;
});
