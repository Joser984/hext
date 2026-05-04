import 'package:go_router/go_router.dart';
import 'package:flutter/widgets.dart';
import 'package:hext/core/models/app_user.dart';
import 'package:hext/features/agenda/personal_module_page.dart';
import 'package:hext/features/auth/auth_notifier.dart';
import 'package:hext/features/auth/login_screen.dart';
import 'package:hext/features/cases/cases_screen.dart';
import 'package:hext/features/dashboard/dashboard_screen.dart';
import 'package:hext/features/pad/candidatos_screen.dart';
import 'package:hext/features/pad/nuevo_pad_screen.dart';
import 'package:hext/features/pending/pending_screen.dart';
import 'package:hext/features/schedule/horarios_screen.dart';
import 'package:hext/features/schedule/schedule_screen.dart';
import 'package:hext/shared/widgets/app_shell.dart';
import 'package:hext/shared/widgets/hext_loading_screen.dart';

GoRouter buildRouter(AuthNotifier authNotifier) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (BuildContext context, GoRouterState state) {
      final bool loading = authNotifier.status == AuthStatus.loading;
      final bool authenticated = authNotifier.isAuthenticated;

      final String location = state.matchedLocation;
      final bool goingToLogin = location == '/login';
      final bool goingToRegister = location == '/register';

      if (loading) return null;

      // Sin sesión: solo puede estar en login o register
      if (!authenticated && !goingToLogin && !goingToRegister) {
        return '/login';
      }

      // Con sesión: login/register ya no aplican
      if (authenticated && (goingToLogin || goingToRegister)) {
        return '/dashboard';
      }

      // Guards por rol, solo con sesión activa
      final AppUser? user = authNotifier.appUser;
      if (authenticated && user != null) {
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
      GoRoute(
        path: '/login',
        builder: (context, state) {
          if (authNotifier.status == AuthStatus.loading) {
            return const HextLoadingScreen(
              title: 'Cargando HEXT',
              subtitle: 'Validando acceso institucional',
            );
          }
          return const LoginScreen();
        },
      ),
      // Registro deshabilitado en frontend por ADMIN_ONLY_OPERATION
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
            redirect: (context, state) => '/schedule/visitas',
          ),
          GoRoute(
            path: '/schedule/visitas',
            builder: (context, state) => ScheduleScreen(
              initialSearch: state.uri.queryParameters['q'],
              initialVisitId:
                  state.uri.queryParameters['visitId'] ??
                  state.uri.queryParameters['itemId'],
              initialPatientId: state.uri.queryParameters['patientId'],
              initialPendingId: state.uri.queryParameters['pendingId'],
              sourceContext: state.uri.queryParameters['source'],
            ),
          ),
          GoRoute(
            path: '/schedule/horarios',
            builder: (context, state) => const HorariosScreen(),
          ),
          GoRoute(
            path: '/schedule/auxiliares',
            builder: (context, state) => const PersonalModulePage(),
          ),
          GoRoute(
            path: '/schedule/personal',
            redirect: (context, state) => '/schedule/auxiliares',
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
