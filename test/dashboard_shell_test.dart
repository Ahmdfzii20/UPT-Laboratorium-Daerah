import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:labkesda_app/features/shared/widgets/dashboard_shell.dart';
import 'package:labkesda_app/models/user_model.dart';
import 'package:labkesda_app/providers/auth_provider.dart';

const _admin = UserModel(
  uid: 'u1',
  email: 'admin@labkesda.id',
  role: 'admin',
  nama: 'Admin Labkesda',
  aktif: true,
);

class _Host extends StatelessWidget {
  const _Host();

  @override
  Widget build(BuildContext context) {
    return const DashboardShell(
      title: 'Test',
      child: Scaffold(body: Center(child: Text('konten'))),
    );
  }
}

void main() {
  Widget buildApp() {
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, _) => const _Host())],
    );
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => Stream<fb.User?>.value(null)),
        currentUserProvider
            .overrideWith((ref) => Stream<UserModel?>.value(_admin)),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets('mobile: menampilkan bottom nav dan profil sheet',
      (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.tap(find.text('AL'));
    await tester.pumpAndSettle();

    expect(find.text('Keluar Akun'), findsOneWidget);
  });

  testWidgets('desktop: menampilkan navigation rail dan profil sheet', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);

    await tester.tap(find.text('AL'));
    await tester.pumpAndSettle();

    expect(find.text('Keluar Akun'), findsOneWidget);
  });
}
