import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hext/core/catalog/pad_labels.dart';
import 'package:hext/features/auth/auth_notifier.dart';
import 'package:provider/provider.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  int _currentIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();

    if (location.startsWith('/cases')) return 1;
    if (location.startsWith('/schedule')) return 2;
    if (location.startsWith('/pending')) return 3;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/cases');
        break;
      case 2:
        context.go('/schedule');
        break;
      case 3:
        context.go('/pending');
        break;
    }
  }

  String _titleForRoute(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/pad/nuevo')) return PadUiLabels.newCaseTitle;
    if (location.startsWith('/pad/editar')) return PadUiLabels.newCaseTitle;
    if (location.startsWith('/pad/candidatos')) {
      return PadUiLabels.casesModuleTitle;
    }
    if (location.startsWith('/dashboard')) return PadUiLabels.dashboardTitle;
    if (location.startsWith('/cases')) return 'Pacientes';
    if (location.startsWith('/schedule/personal')) {
      return 'Auxiliares de enfermeria';
    }
    if (location.startsWith('/schedule')) return 'Agenda';
    if (location.startsWith('/pending')) return 'Pendientes';
    return 'HEXT';
  }

  @override
  Widget build(BuildContext context) {
    final int currentIndex = _currentIndex(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForRoute(context)),
        elevation: 0,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Cerrar sesion',
            onPressed: () async {
              await context.read<AuthNotifier>().signOut();
            },
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFFF5F7FA),
        surfaceTintColor: Colors.transparent,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 74,
            child: Row(
              children: <Widget>[
                _BottomNavItem(
                  label: 'Dashboard',
                  icon: Icons.grid_view_outlined,
                  selected: currentIndex == 0,
                  onTap: () => _onTap(context, 0),
                ),
                _BottomNavItem(
                  label: 'Pacientes',
                  icon: Icons.assignment_ind_outlined,
                  selected: currentIndex == 1,
                  onTap: () => _onTap(context, 1),
                ),
                _CenterCreateButton(
                  onTap: () => context.go('/pad/nuevo'),
                ),
                _BottomNavItem(
                  label: 'Agenda',
                  icon: Icons.calendar_today_outlined,
                  selected: currentIndex == 2,
                  onTap: () => _onTap(context, 2),
                ),
                _BottomNavItem(
                  label: 'Pendientes',
                  icon: Icons.pending_actions_outlined,
                  selected: currentIndex == 3,
                  onTap: () => _onTap(context, 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF06B6D4) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: selected ? Colors.white : const Color(0xFF1C2228),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: selected
                      ? const Color(0xFF1C2228)
                      : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterCreateButton extends StatelessWidget {
  const _CenterCreateButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Tooltip(
          message: 'Ingresar paciente',
          child: Material(
            color: const Color(0xFF1E3A66),
            shape: const CircleBorder(),
            elevation: 2,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: const SizedBox(
                width: 54,
                height: 54,
                child: Icon(Icons.add_rounded, size: 26, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
