import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hext/core/catalog/pad_labels.dart';
import 'package:hext/features/auth/auth_notifier.dart';
import 'package:provider/provider.dart';

enum _DesktopCreateAction { newCase, newVisit, addAuxiliary }

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
    if (location.startsWith('/pad/editar')) return PadUiLabels.editCaseTitle;
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

  _DesktopCreateAction? _desktopActionForRoute(String location) {
    if (location.startsWith('/schedule/personal')) {
      return _DesktopCreateAction.addAuxiliary;
    }
    if (location.startsWith('/schedule')) {
      return _DesktopCreateAction.newVisit;
    }
    if (location.startsWith('/dashboard') ||
        location.startsWith('/cases') ||
        location.startsWith('/pending') ||
        location.startsWith('/pad')) {
      return _DesktopCreateAction.newCase;
    }
    return null;
  }

  String _desktopActionLabel(_DesktopCreateAction action) {
    switch (action) {
      case _DesktopCreateAction.newCase:
        return 'Nuevo caso';
      case _DesktopCreateAction.newVisit:
        return 'Nueva visita';
      case _DesktopCreateAction.addAuxiliary:
        return 'Agregar personal';
    }
  }

  void _handleDesktopAction(BuildContext context, _DesktopCreateAction action) {
    switch (action) {
      case _DesktopCreateAction.newCase:
        context.go('/pad/nuevo');
        break;
      case _DesktopCreateAction.newVisit:
        context.go('/schedule');
        break;
      case _DesktopCreateAction.addAuxiliary:
        context.go('/schedule/personal');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int currentIndex = _currentIndex(context);
    final String location = GoRouterState.of(context).uri.toString();
    final bool isDesktop = MediaQuery.sizeOf(context).width >= 1024;
    final _DesktopCreateAction? desktopAction = _desktopActionForRoute(
      location,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForRoute(context)),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(height: 2, color: const Color(0xFF0F5C58)),
        ),
        actions: <Widget>[
          if (isDesktop && desktopAction != null)
            Tooltip(
              message: _desktopActionLabel(desktopAction),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Material(
                  color: const Color(0xFF17726D),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _handleDesktopAction(context, desktopAction),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.add, size: 18, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Crear',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (isDesktop) const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: Color(0xFF0F5C58)),
            tooltip: 'Cerrar sesion',
            onPressed: () async {
              await context.read<AuthNotifier>().signOut();
            },
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFFFFFFFF),
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
                if (!isDesktop)
                  _CenterCreateButton(onTap: () => context.go('/pad/nuevo')),
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
                  color: selected
                      ? const Color(0xFF17726D)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: selected ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: selected
                      ? const Color(0xFF17726D)
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
            color: const Color(0xFF0F5C58),
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
