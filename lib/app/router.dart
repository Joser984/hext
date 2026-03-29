import 'package:go_router/go_router.dart';
import 'package:hext/features/cases/cases_screen.dart';
import 'package:hext/features/dashboard/dashboard_screen.dart';
import 'package:hext/features/pad/candidatos_screen.dart';
import 'package:hext/features/pad/nuevo_pad_screen.dart';
import 'package:hext/features/pending/pending_screen.dart';
import 'package:hext/features/schedule/schedule_screen.dart';
import 'package:hext/shared/widgets/app_shell.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/dashboard',
  routes: <RouteBase>[
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: <RouteBase>[
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/cases',
          builder: (context, state) => const CensoScreen(),
        ),
        GoRoute(
          path: '/schedule',
          builder: (context, state) => const ScheduleScreen(),
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
      ],
    ),
  ],
);