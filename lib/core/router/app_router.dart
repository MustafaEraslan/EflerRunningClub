import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/auth_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/runs/qr_screen.dart';
import '../../features/runs/scanner_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/home',
  redirect: (context, state) {
    final signedIn = Supabase.instance.client.auth.currentSession != null;
    final authPath =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/register' ||
        state.matchedLocation == '/forgot';
    if (!signedIn && !authPath) return '/login';
    if (signedIn && authPath) return '/home';
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (_, _) => const AuthScreen(mode: AuthMode.login),
    ),
    GoRoute(
      path: '/register',
      builder: (_, _) => const AuthScreen(mode: AuthMode.register),
    ),
    GoRoute(
      path: '/forgot',
      builder: (_, _) => const AuthScreen(mode: AuthMode.forgot),
    ),
    GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
    GoRoute(path: '/scanner', builder: (_, _) => const ScannerScreen()),
    GoRoute(
      path: '/qr/:runId',
      builder: (_, state) => QrScreen(runId: state.pathParameters['runId']!),
    ),
    GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
  ],
);
