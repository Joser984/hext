import 'package:flutter/material.dart';

import 'router.dart';
import 'theme.dart';

class HextApp extends StatelessWidget {
  const HextApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'HEXT',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
