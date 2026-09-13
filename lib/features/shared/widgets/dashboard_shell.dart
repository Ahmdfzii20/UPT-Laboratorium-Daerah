import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import 'app_logo.dart';

class _Dest {
  const _Dest(this.path, this.label, this.icon, this.selectedIcon);

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const _adminDests = <_Dest>[
  _Dest(
    '/labkesda/dashboard',
    'Dashboard',
    Icons.dashboard_outlined,
    Icons.dashboard,
  ),
  _Dest(
    '/labkesda/monitoring',
    'Monitoring',
    Icons.grid_view_outlined,
    Icons.grid_view,
  ),
  _Dest(
    '/labkesda/input',
    'Input Laporan',
    Icons.edit_note_outlined,
    Icons.edit_note,
  ),
  _Dest(
    '/labkesda/rekap',
    'Rekap & Export',
    Icons.table_chart_outlined,
    Icons.table_chart,
  ),
  _Dest(
    '/labkesda/master-data',
    'Master Data',
    Icons.storage_outlined,
    Icons.storage,
  ),
  _Dest(
    '/labkesda/akun',
    'Manajemen Akun',
    Icons.manage_accounts_outlined,
    Icons.manage_accounts,
  ),
  _Dest(
    '/labkesda/deadline',
    'Batas Waktu',
    Icons.schedule_outlined,
    Icons.schedule,
  ),
];

const _puskesmasDests = <_Dest>[
  _Dest(
    '/puskesmas/dashboard',
    'Beranda',
    Icons.dashboard_outlined,
    Icons.dashboard,
  ),
  _Dest('/puskesmas/histori', 'Histori', Icons.history_outlined, Icons.history),
];

class DashboardShell extends ConsumerWidget {
  const DashboardShell({
    super.key,
    required this.title,
    required this.child,
    this.sectionName,
    this.actions,
    this.floatingActionButton,
    this.tabBar,
    this.showBottomNav = true,
  });

  final String title;
  final String? sectionName;
  final Widget child;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? tabBar;
  final bool showBottomNav;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final isAdmin = user?.isAdmin ?? false;
    final dests = isAdmin ? _adminDests : _puskesmasDests;

    final currentPath = GoRouterState.of(context).uri.path;
    final selectedIndex = dests.indexWhere((d) => d.path == currentPath);

    void onSelected(int i) {
      if (i >= 0 && i < dests.length) {
        context.go(dests[i].path);
      }
    }

    final sectionSubtitle =
        sectionName ??
        (currentPath.contains('histori')
            ? 'Histori'
            : currentPath.contains('form')
            ? 'Form Input'
            : 'Beranda');

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;

        return Scaffold(
          backgroundColor: AppTheme.surfaceContainerLow,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            titleSpacing: 16,
            elevation: 0.5,
            title: Row(
              children: [
                AppHeaderTitle(subtitle: sectionSubtitle),
                const Spacer(),
                ...actions?.whereType<Widget>() ?? const [],
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showProfileSheet(context, ref, user),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _inisial(user?.nama ?? 'P'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            bottom: tabBar,
          ),
          floatingActionButton: floatingActionButton,
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isMobile)
                _buildRail(
                  context,
                  ref,
                  user,
                  dests,
                  selectedIndex,
                  onSelected,
                ),
              Expanded(
                child: SafeArea(top: false, bottom: false, child: child),
              ),
            ],
          ),
          bottomNavigationBar: (isMobile && showBottomNav)
              ? NavigationBar(
                  selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
                  onDestinationSelected: (int index) {
                    if (index < dests.length) {
                      onSelected(index);
                    } else {
                      _showProfileSheet(context, ref, user);
                    }
                  },
                  destinations: [
                    ...dests.map(
                      (d) => NavigationDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selectedIcon),
                        label: d.label,
                      ),
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.account_circle_outlined),
                      selectedIcon: Icon(Icons.account_circle),
                      label: 'Profil',
                    ),
                  ],
                )
              : null,
        );
      },
    );
  }

  Widget _buildRail(
    BuildContext context,
    WidgetRef ref,
    UserModel? user,
    List<_Dest> dests,
    int selectedIndex,
    void Function(int) onSelected,
  ) {
    return NavigationRail(
      backgroundColor: AppTheme.surface,
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      onDestinationSelected: onSelected,
      labelType: NavigationRailLabelType.all,
      indicatorColor: AppTheme.primaryContainer.withValues(alpha: 0.2),
      selectedIconTheme: const IconThemeData(color: AppTheme.primary),
      selectedLabelTextStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        color: AppTheme.primary,
        fontSize: 12,
      ),
      unselectedLabelTextStyle: const TextStyle(
        color: AppTheme.onSecondaryContainer,
        fontSize: 12,
      ),
      destinations: [
        for (final d in dests)
          NavigationRailDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.selectedIcon),
            label: Text(d.label),
          ),
      ],
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: IconButton(
              tooltip: 'Keluar',
              onPressed: () => _logout(context, ref),
              icon: const Icon(Icons.logout, color: AppTheme.error),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authProvider).signOut();
    if (context.mounted) context.go('/login');
  }

  void _showProfileSheet(BuildContext context, WidgetRef ref, UserModel? user) {
    final nama = user?.nama ?? 'Petugas Lab';
    final subtitle = user?.isAdmin == true
        ? 'Admin Labkesda'
        : 'Petugas Puskesmas';

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppTheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _inisial(nama),
                    style: const TextStyle(
                      color: AppTheme.onPrimaryContainer,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                nama,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (user?.email case final email?) ...[
                const SizedBox(height: 2),
                Text(email, style: Theme.of(context).textTheme.bodySmall),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _logout(context, ref);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: const BorderSide(color: AppTheme.error),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text('Keluar Akun'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _inisial(String nama) {
  final parts = nama.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  if (parts.isEmpty) return 'P';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return (parts.first.characters.first + parts.last.characters.first)
      .toUpperCase();
}
