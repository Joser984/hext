import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    if (location.startsWith('/pad/nuevo')) return 'Nuevo candidato PAD';
    if (location.startsWith('/pad/candidatos')) return 'Candidatos PAD';
    if (location.startsWith('/dashboard')) return 'Dashboard';
    if (location.startsWith('/cases')) return 'Censo';
    if (location.startsWith('/schedule')) return 'Agenda';
    if (location.startsWith('/pending')) return 'Pendientes';
    return 'HEXT';
  }

  @override
  Widget build(BuildContext context) {
    final int currentIndex = _currentIndex(context);
    final String location = GoRouterState.of(context).uri.toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForRoute(context)),
        elevation: 0,
      ),
      body: child,
      floatingActionButton: location.startsWith('/dashboard')
          ? FloatingActionButton(
              onPressed: () {
                context.push('/pad/nuevo');
              },
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: const Color(0xFF06B6D4),
          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: Color(0xFF1C2228),
                fontWeight: FontWeight.w600,
              );
            }
            return const TextStyle(
              color: Color(0xFF6B7280),
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Colors.white);
            }
            return const IconThemeData(color: Color(0xFF1C2228));
          }),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (int index) => _onTap(context, index),
          destinations: const <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Censo',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined),
              label: 'Agenda',
            ),
            NavigationDestination(
              icon: Icon(Icons.pending_actions_outlined),
              label: 'Pendientes',
            ),
          ],
        ),
      ),
    );
  }
}