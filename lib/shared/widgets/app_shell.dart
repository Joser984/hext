import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hext/core/theme/hext_ui_tokens.dart';
import 'package:hext/core/catalog/pad_labels.dart';
import 'package:hext/core/models/app_user.dart';
import 'package:hext/features/auth/auth_notifier.dart';
import 'package:hext/shared/widgets/hext_mark.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum _DesktopCreateAction { newCase, newVisit, addAuxiliary }

class _ShellNavItemData {
  const _ShellNavItemData({
    required this.label,
    required this.route,
    required this.icon,
    this.badge,
  });

  final String label;
  final String route;
  final IconData icon;
  final String? badge;
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const List<_ShellNavItemData> _desktopItems = <_ShellNavItemData>[
    _ShellNavItemData(
      label: 'Dashboard',
      route: '/dashboard',
      icon: Icons.grid_view_outlined,
    ),
    _ShellNavItemData(
      label: 'Pacientes',
      route: '/cases',
      icon: Icons.people_outline,
    ),
    _ShellNavItemData(
      label: 'Agenda',
      route: '/schedule',
      icon: Icons.calendar_month_outlined,
    ),
    _ShellNavItemData(
      label: 'Pendientes',
      route: '/pending',
      icon: Icons.pending_actions_outlined,
      badge: '8',
    ),
  ];

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const String _sidebarCollapsedPrefsKey =
      'app_shell.sidebar_collapsed';

  bool _isSidebarCollapsed = false;

  @override
  void initState() {
    super.initState();
    _restoreSidebarState();
  }

  Future<void> _restoreSidebarState() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool? savedValue = prefs.getBool(_sidebarCollapsedPrefsKey);
    if (!mounted || savedValue == null) return;
    setState(() {
      _isSidebarCollapsed = savedValue;
    });
  }

  Future<void> _toggleSidebarCollapsed() async {
    final bool nextValue = !_isSidebarCollapsed;
    setState(() {
      _isSidebarCollapsed = nextValue;
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sidebarCollapsedPrefsKey, nextValue);
  }

  int _currentIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();

    if (location.startsWith('/pad')) return 1;
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
      return 'Auxiliares de enfermería';
    }
    if (location.startsWith('/schedule')) return 'Agenda';
    if (location.startsWith('/pending')) return 'Pendientes';
    return 'HEXT';
  }

  String? _subtitleForRoute(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/pad/nuevo')) {
      return 'Captacion y evaluacion inicial del paciente';
    }
    if (location.startsWith('/pad/editar')) {
      return 'Actualizacion y seguimiento del candidato PAD';
    }
    if (location.startsWith('/pad/candidatos')) {
      return 'Gestion de pacientes y candidatos del programa PAD';
    }
    if (location.startsWith('/dashboard')) {
      return 'Vista ejecutiva de operacion y cuidado en salud';
    }
    if (location.startsWith('/cases')) {
      return 'Gestion integral de pacientes y seguimiento operativo';
    }
    if (location.startsWith('/schedule/personal')) {
      return 'Configuracion operativa de auxiliares y disponibilidad';
    }
    if (location.startsWith('/schedule')) {
      return 'Planeacion de visitas y agenda asistencial';
    }
    if (location.startsWith('/pending')) {
      return 'Seguimiento de tareas y eventos pendientes';
    }
    return null;
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

  String _roleLabel(AppUserRole role) {
    switch (role) {
      case AppUserRole.admin:
        return 'Administrador';
      case AppUserRole.medico:
        return 'Médico';
      case AppUserRole.directoraPrograma:
        return 'Directora del programa';
      case AppUserRole.auxiliarAdministrativa:
        return 'Coordinación operativa';
      case AppUserRole.auxiliarEnfermeria:
        return 'Auxiliar de enfermería';
      case AppUserRole.auxiliarEnfermeriaClinicaHeridas:
        return 'Clínica de heridas';
    }
  }

  @override
  Widget build(BuildContext context) {
    final int currentIndex = _currentIndex(context);
    final String location = GoRouterState.of(context).uri.toString();
    final bool isDesktop = MediaQuery.sizeOf(context).width >= 1024;
    final _DesktopCreateAction? desktopAction = _desktopActionForRoute(location);

    if (!isDesktop) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_titleForRoute(context)),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.logout_outlined),
              tooltip: 'Cerrar sesión',
              onPressed: () async {
                await context.read<AuthNotifier>().signOut();
              },
            ),
          ],
        ),
        body: widget.child,
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
                    compact: false,
                    onTap: () => _onTap(context, 0),
                  ),
                  _BottomNavItem(
                    label: 'Pacientes',
                    icon: Icons.assignment_ind_outlined,
                    selected: currentIndex == 1,
                    compact: false,
                    onTap: () => _onTap(context, 1),
                  ),
                  _CenterCreateButton(onTap: () => context.go('/pad/nuevo')),
                  _BottomNavItem(
                    label: 'Agenda',
                    icon: Icons.calendar_today_outlined,
                    selected: currentIndex == 2,
                    compact: false,
                    onTap: () => _onTap(context, 2),
                  ),
                  _BottomNavItem(
                    label: 'Pendientes',
                    icon: Icons.pending_actions_outlined,
                    selected: currentIndex == 3,
                    compact: false,
                    onTap: () => _onTap(context, 3),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final AuthNotifier auth = context.watch<AuthNotifier>();
    final AppUser? user = auth.appUser;

    return Scaffold(
      body: Row(
        children: <Widget>[
          _DesktopSidebar(
            currentIndex: currentIndex,
            items: AppShell._desktopItems,
            isCollapsed: _isSidebarCollapsed,
            onTap: (int index) => _onTap(context, index),
            onToggleCollapse: _toggleSidebarCollapsed,
          ),
          Expanded(
            child: ColoredBox(
              color: HextColors.background,
              child: Column(
                children: <Widget>[
                  _DesktopTopBar(
                    title: _titleForRoute(context),
                    subtitle: _isSidebarCollapsed
                        ? null
                        : _subtitleForRoute(context),
                    actionLabel: desktopAction == null
                        ? null
                        : _desktopActionLabel(desktopAction),
                    onActionPressed: desktopAction == null
                        ? null
                        : () => _handleDesktopAction(context, desktopAction),
                    userName: user?.nombre ?? 'Usuario Demo',
                    userRole: user == null ? 'Sesion local' : _roleLabel(user.rol),
                    onSignOut: () async {
                      await context.read<AuthNotifier>().signOut();
                    },
                  ),
                  Expanded(child: widget.child),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.currentIndex,
    required this.items,
    required this.isCollapsed,
    required this.onTap,
    required this.onToggleCollapse,
  });

  final int currentIndex;
  final List<_ShellNavItemData> items;
  final bool isCollapsed;
  final ValueChanged<int> onTap;
  final VoidCallback onToggleCollapse;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: isCollapsed
          ? HextSidebarTokens.collapsedWidth
          : HextSidebarTokens.width,
      color: HextColors.sidebarDark,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            isCollapsed ? 10 : 24,
            18,
            isCollapsed ? 10 : 18,
            22,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Align(
                alignment: isCollapsed ? Alignment.topCenter : Alignment.topLeft,
                child: isCollapsed
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          HextMark(
                            size: 36,
                            variant: HextMarkVariant.transparentMark,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 12),
                          Tooltip(
                            message: 'Expandir menú',
                            child: IconButton(
                              onPressed: onToggleCollapse,
                              iconSize: 18,
                              splashRadius: 18,
                              color: Colors.white70,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 24,
                                minHeight: 24,
                              ),
                              icon: const Icon(Icons.keyboard_double_arrow_right_rounded),
                            ),
                          ),
                        ],
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SizedBox(
                          height: 64,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              const HextMark(
                                size: 32,
                                variant: HextMarkVariant.transparentMark,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 12),
                              RichText(
                                text: const TextSpan(
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
                                    color: Colors.white,
                                    height: 1,
                                  ),
                                  children: <TextSpan>[
                                    TextSpan(text: 'HE'),
                                    TextSpan(
                                      text: 'X',
                                      style: TextStyle(color: Color(0xFFCCBA86)),
                                    ),
                                    TextSpan(text: 'T'),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Tooltip(
                                message: 'Contraer menú',
                                child: IconButton(
                                  onPressed: onToggleCollapse,
                                  iconSize: 20,
                                  splashRadius: 18,
                                  color: Colors.white70,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 24,
                                    minHeight: 24,
                                  ),
                                  icon: const Icon(Icons.keyboard_double_arrow_left_rounded),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 24),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 16),
              for (int index = 0; index < items.length; index++) ...<Widget>[
                _SidebarNavItem(
                  item: items[index],
                  selected: index == currentIndex,
                  isCollapsed: isCollapsed,
                  onTap: () => onTap(index),
                ),
                const SizedBox(height: 8),
              ],
              const Spacer(),
              if (!isCollapsed)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0x14000000),
                    borderRadius: BorderRadius.circular(
                      HextSidebarTokens.itemRadius,
                    ),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          HextMark(
                            size: 24,
                            variant: HextMarkVariant.transparentMark,
                            color: Colors.white,
                          ),
                          SizedBox(width: 10),
                          Text('HEXT', style: HextTextStyles.sidebarItem),
                        ],
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Plataforma institucional de gestion y cuidado en salud',
                        style: HextTextStyles.sidebarFooter,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  const _SidebarNavItem({
    required this.item,
    required this.selected,
    required this.isCollapsed,
    required this.onTap,
  });

  final _ShellNavItemData item;
  final bool selected;
  final bool isCollapsed;
  final VoidCallback onTap;

  Widget _buildBadge() {
    return Container(
      width: HextSidebarTokens.badgeSize,
      height: HextSidebarTokens.badgeSize,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: HextColors.secondary,
        shape: BoxShape.circle,
      ),
      child: Text(
        item.badge!,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: HextColors.sidebarDark,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget child = Material(
      color: selected ? HextColors.sidebarSelected : Colors.transparent,
      borderRadius: BorderRadius.circular(HextSidebarTokens.itemRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(HextSidebarTokens.itemRadius),
        onTap: onTap,
        child: Container(
          height: HextSidebarTokens.itemHeight,
          padding: isCollapsed
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(
                  horizontal: HextSidebarTokens.horizontalPadding,
                ),
          child: isCollapsed
              ? Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      Icon(
                        item.icon,
                        color: Colors.white,
                        size: HextSidebarTokens.iconSize,
                      ),
                      if (item.badge != null)
                        Positioned(
                          right: -10,
                          top: -8,
                          child: Transform.scale(
                            scale: 0.8,
                            child: _buildBadge(),
                          ),
                        ),
                    ],
                  ),
                )
              : Row(
                  children: <Widget>[
                    Icon(
                      item.icon,
                      color: Colors.white,
                      size: HextSidebarTokens.iconSize,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(item.label, style: HextTextStyles.sidebarItem),
                    ),
                    if (item.badge != null) _buildBadge(),
                  ],
                ),
        ),
      ),
    );

    if (isCollapsed) {
      child = Tooltip(message: item.label, child: child);
    }

    return child;
  }
}

class _DesktopTopBar extends StatelessWidget {
  const _DesktopTopBar({
    required this.title,
    required this.subtitle,
    required this.userName,
    required this.userRole,
    required this.onSignOut,
    this.actionLabel,
    this.onActionPressed,
  });

  final String title;
  final String? subtitle;
  final String userName;
  final String userRole;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final String initials = userName
        .trim()
        .split(RegExp(r'\s+'))
        .where((String token) => token.isNotEmpty)
        .take(2)
        .map((String token) => token.substring(0, 1).toUpperCase())
        .join();

    return Container(
      height: HextDimens.topBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: HextColors.sidebar,
        boxShadow: HextShadows.footer,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                    letterSpacing: 1.1,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: Color(0xCCEAF3F2),
                      fontSize: 11,
                      height: 1.0,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
              ],
            ),
          ),
          if (actionLabel != null && onActionPressed != null) ...<Widget>[
            FilledButton.icon(
              onPressed: onActionPressed,
              style: FilledButton.styleFrom(
                fixedSize: const Size.fromHeight(HextDimens.buttonHeight),
                maximumSize: const Size(double.infinity, HextDimens.buttonHeight),
                backgroundColor: Colors.white,
                foregroundColor: HextColors.sidebarDark,
                minimumSize: const Size(0, HextDimens.buttonHeight),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(HextDimens.radiusField),
                ),
              ),
              icon: const Icon(Icons.add, size: 17),
              label: Text(actionLabel!),
            ),
            const SizedBox(width: 14),
          ],
          const Icon(Icons.search, color: Colors.white, size: 18),
          const SizedBox(width: 16),
          Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              const Icon(
                Icons.notifications_none,
                color: Colors.white,
                size: 20,
              ),
              Positioned(
                right: -3,
                top: -4,
                child: Container(
                  width: 16,
                  height: 16,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: HextColors.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '3',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: HextColors.sidebarDark,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          PopupMenuButton<String>(
            tooltip: 'Menu de usuario',
            color: Colors.white,
            onSelected: (String value) async {
              if (value == 'logout') {
                await onSignOut();
              }
            },
            itemBuilder: (BuildContext context) =>
                const <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: Text('Cerrar sesion'),
                  ),
                ],
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 17,
                  backgroundColor: Colors.white,
                  foregroundColor: HextColors.sidebarDark,
                  child: Text(
                    initials.isEmpty ? 'HX' : initials,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      userRole,
                      style: const TextStyle(
                        color: Color(0xCCEAF3F2),
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 6),
                const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: compact ? 2 : 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 8 : 9,
                  vertical: compact ? 3 : 4,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF17726D)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: compact ? 18 : 20,
                  color: selected ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
              SizedBox(height: compact ? 2 : 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: compact ? 11 : 12,
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
            color: HextColors.primary,
            shape: const CircleBorder(),
            elevation: 2,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              splashColor: HextColors.primarySoft,
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
