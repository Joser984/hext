import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hext/core/repositories/in_memory_novedades_repo.dart';
import 'package:hext/core/repositories/in_memory_personal_repo.dart';
import 'package:hext/core/repositories/user_repository.dart';
import 'package:hext/core/services/auth_service.dart';
import 'package:hext/features/auth/auth_notifier.dart';
import 'router.dart';
import 'theme.dart';

class HextApp extends StatelessWidget {
  const HextApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: <ChangeNotifierProvider<dynamic>>[
        ChangeNotifierProvider<InMemoryPersonalRepo>(
          create: (_) => InMemoryPersonalRepo()..load(),
        ),
        ChangeNotifierProvider<InMemoryNovedadesRepo>(
          create: (_) => InMemoryNovedadesRepo(),
        ),
        ChangeNotifierProvider<AuthNotifier>(
          create: (_) => AuthNotifier(
            authService: AuthService(),
            userRepository: UserRepository(),
          ),
        ),
      ],
      child: Builder(
        builder: (BuildContext context) {
          final AuthNotifier authNotifier = context.watch<AuthNotifier>();
          return MaterialApp.router(
            title: 'HEXT',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            routerConfig: buildRouter(authNotifier),
          );
        },
      ),
    );
  }
}

