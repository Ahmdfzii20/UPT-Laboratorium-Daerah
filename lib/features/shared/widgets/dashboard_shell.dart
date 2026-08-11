import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';

class _Dest {
  const _Dest(this.path, this.label, this.icon, this.selectedIcon);

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

enum _MenuAction { logout }

const _adminDests = <_Dest>[
  _Dest('/labkesda/dashboard', 'Dashboard', Icons.dashboard_outlined,
      Icons.dashboard),
  _Dest('/labkesda/monitoring', 'Monitoring', Icons.grid_view_outlined,
      Icons.grid_view),
  _Dest('/labkesda/rekap', 'Rekap & Export', Icons.table_chart_outlined,
      Icons.table_chart),
  _Dest('/labkesda/master-data', 'Master Data', Icons.storage_outlined,
      Icons.storage),
  _Dest('/labkesda/akun', 'Manajemen Akun', Icons.manage_accounts_outlined,
      Icons.manage_accounts),
  _Dest('/labkesda/deadline', 'Batas Waktu', Icons.schedule_outlined,
      Icons.schedule),
];

const _puskesmasDests = <_Dest>[
  _Dest('/puskesmas/dashboard', 'Dashboard', Icons.dashboard_outlined,
      Icons.dashboard),
  _Dest('/puskesmas/form', 'Isi Laporan', Icons.edit_note_outlined,
      Icons.edit_note),
  _Dest('/puskesmas/histori', 'Histori', Icons.history_outlined,
      Icons.history),
];

class DashboardShell extends ConsumerWidget {
  const DashboardShell({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.floatingActionButton,
    this.tabBar,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? tabBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final isAdmin = user?.isAdmin ?? false;
    final dests = isAdmin ? _adminDests : _puskesmasDests;

    final path = GoRouterState.of(context).uri.path;
    final selectedIndex =
        dests.indexWhere((d) => d.path == path).clamp(0, dests.length);

    void onSelected(int i) => context.go(dests[i].path);

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 960;

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: actions,
            bottom: tabBar,
          ),
          drawer: useRail
              ? null
              : _buildDrawer(context, ref, user, dests, selectedIndex, onSelected),
          floatingActionButton: floatingActionButton,
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (useRail)
                _buildRail(context, ref, user, dests, selectedIndex, onSelected),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawer(
    BuildContext context,
    WidgetRef ref,
    UserModel? user,
    List<_Dest> dests,
    int selectedIndex,
    void Function(int) onSelected,
  ) {
    return NavigationDrawer(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProfileHeader(
            user: user,
            onTap: () => _showProfileSheet(context, ref, user),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 28, vertical: 4),
            child: Divider(),
          ),
        ],
      ),
      footer: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            onPressed: () => _logout(context, ref),
            icon: const Icon(Icons.logout),
            label: const Text('Keluar'),
          ),
        ),
      ),
      children: [
        for (var i = 0; i < dests.length; i++)
          NavigationDrawerDestination(
            icon: Icon(dests[i].icon),
            selectedIcon: Icon(dests[i].selectedIcon),
            label: Text(dests[i].label),
          ),
      ],
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
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      labelType: NavigationRailLabelType.all,
      leading: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: PopupMenuButton<_MenuAction>(
          tooltip: 'Profil & pengaturan',
          onSelected: (action) {
            if (action == _MenuAction.logout) _logout(context, ref);
          },
          itemBuilder: (context) => [
            PopupMenuItem<_MenuAction>(
              enabled: false,
              child: _MenuProfile(user: user),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<_MenuAction>(
              value: _MenuAction.logout,
              child: Row(
                children: [
                  Icon(Icons.logout, size: 20),
                  SizedBox(width: 12),
                  Text('Keluar'),
                ],
              ),
            ),
          ],
          child: _RailUser(user),
        ),
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
          child: IconButton(
            tooltip: 'Keluar',
            onPressed: () => _logout(context, ref),
            icon: const Icon(Icons.logout),
          ),
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authProvider).signOut();
    if (context.mounted) context.go('/login');
  }

  /// Bottom sheet profil admin/petugas (muncul saat profil di drawer diketuk)
  /// dengan opsi "Keluar".
  void _showProfileSheet(BuildContext context, WidgetRef ref, UserModel? user) {
    final nama = user?.nama ?? '…';
    final subtitle = user?.isAdmin == true
        ? 'Admin Labkesda'
        : 'Petugas Puskesmas';

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  _inisial(nama),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                nama,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (user?.email case final email?) ...[
                const SizedBox(height: 2),
                Text(
                  email,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _logout(context, ref);
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Keluar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({this.user, this.onTap});

  final UserModel? user;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final nama = user?.nama ?? '…';
    final subtitle = user?.isAdmin == true
        ? 'Admin Labkesda'
        : 'Petugas Puskesmas';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.primaryContainer],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: scheme.onPrimary,
                      child: Text(
                        _inisial(nama),
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.expand_more,
                      color: scheme.onPrimary.withValues(alpha: 0.85),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: scheme.onPrimary, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: scheme.onPrimary.withValues(alpha: 0.9)),
                ),
                if (user?.email case final email?) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: scheme.onPrimary.withValues(alpha: 0.7)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RailUser extends StatelessWidget {
  const _RailUser(this.user);

  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final nama = user?.nama ?? '…';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: scheme.primaryContainer,
            child: Text(
              _inisial(nama),
              style: TextStyle(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Tooltip(
            message: nama,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 56),
              child: Text(
                nama,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Header profil ringkas untuk menu popup di NavigationRail.
class _MenuProfile extends StatelessWidget {
  const _MenuProfile({this.user});

  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final nama = user?.nama ?? '…';
    final subtitle = user?.isAdmin == true
        ? 'Admin Labkesda'
        : 'Petugas Puskesmas';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: scheme.primaryContainer,
            child: Text(
              _inisial(nama),
              style: TextStyle(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                if (user?.email case final email?)
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _inisial(String nama) {
  final parts = nama.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return (parts.first.characters.first + parts.last.characters.first)
      .toUpperCase();
}
