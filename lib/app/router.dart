import 'package:go_router/go_router.dart';
import 'package:hext/core/models/app_user.dart';
import 'package:hext/features/agenda/personal_module_page.dart';
import 'package:hext/features/auth/auth_notifier.dart';
import 'package:hext/features/auth/login_screen.dart';
import 'package:hext/features/auth/register_screen.dart';
import 'package:hext/features/cases/cases_screen.dart';
import 'package:hext/features/dashboard/dashboard_screen.dart';
import 'package:hext/features/pad/candidatos_screen.dart';
import 'package:hext/features/pad/nuevo_pad_screen.dart';
import 'package:hext/features/pending/pending_screen.dart';
import 'package:hext/features/schedule/horarios_screen.dart';
import 'package:hext/features/schedule/schedule_screen.dart';
import 'package:hext/shared/widgets/app_shell.dart';

GoRouter buildRouter(AuthNotifier authNotifier) {
  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final bool loading = authNotifier.status == AuthStatus.loading;
      final bool authenticated = authNotifier.isAuthenticated;
      final bool goingToLogin = state.matchedLocation == '/login';
      final bool goingToRegister = state.matchedLocation == '/register';

      if (loading) return null;
      if (goingToLogin || goingToRegister) {
        return '/dashboard';
      }

      // Guards por rol (solo cuando hay sesión activa y perfil cargado)
      final AppUser? user = authNotifier.appUser;
      if (authenticated && user != null) {
        final String location = state.matchedLocation;
        if (location.startsWith('/schedule') && !user.canAccessSchedule) {
          return '/dashboard';
        }
        if (location == '/pad/nuevo' && !user.canCreatePadCandidato) {
          return '/dashboard';
        }
      }

      return null;
    },
    refreshListenable: authNotifier,
    routes: <RouteBase>[
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: <RouteBase>[
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/cases',
            builder: (context, state) =>
                CensoScreen(initialSearch: state.uri.queryParameters['q']),
          ),
          GoRoute(
            path: '/schedule',
            builder: (context, state) =>
                ScheduleScreen(initialSearch: state.uri.queryParameters['q']),
          ),
          GoRoute(
            path: '/schedule/horarios',
            builder: (context, state) => const HorariosScreen(),
          ),
          GoRoute(
            path: '/schedule/personal',
            builder: (context, state) => const PersonalModulePage(),
          ),
          GoRoute(
            path: '/pending',
            builder: (context, state) => const PendingScreen(),
          ),
          GoRoute(
            path: '/pad/candidatos',
            builder: (context, state) => const CandidatosScreen(),
          ),
          GoRoute(
            path: '/pad/nuevo',
            builder: (context, state) => const NuevoPadScreen(),
          ),
          GoRoute(
            path: '/pad/editar/:id',
            builder: (context, state) => NuevoPadScreen(
              candidatoId: state.pathParameters['id'],
              initialData: state.extra is Map<String, dynamic>
                  ? state.extra! as Map<String, dynamic>
                  : null,
            ),
          ),
        ],
      ),
    ],
  );
}
