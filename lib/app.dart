import 'package:flutter/material.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class EfelerApp extends StatelessWidget {
  const EfelerApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Efeler Running Club',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: ThemeMode.dark,
    routerConfig: appRouter,
  );
}
