import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/salon/presentation/salon_editor_screen.dart';
import '../../features/salon/presentation/salon_screen.dart';
import '../../features/schedule/presentation/schedule_screen.dart';
import '../../features/services/presentation/service_editor_screen.dart';
import '../../features/services/presentation/services_screen.dart';
import '../../features/shell/presentation/vendor_shell.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/staff/presentation/staff_editor_screen.dart';
import '../../features/staff/presentation/staff_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const LoginScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          VendorShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/schedule',
            builder: (context, state) => const ScheduleScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/services',
            builder: (context, state) => const ServicesScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/staff',
            builder: (context, state) => const StaffScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/salon',
            builder: (context, state) => const SalonScreen(),
          ),
        ]),
      ],
    ),
    // Full-screen editors (no bottom bar) live on the root navigator.
    // `id` is absent when creating.
    GoRoute(
      path: '/services/edit',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          ServiceEditorScreen(serviceId: state.uri.queryParameters['id']),
    ),
    GoRoute(
      path: '/staff/edit',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          StaffEditorScreen(staffId: state.uri.queryParameters['id']),
    ),
    GoRoute(
      path: '/salon/edit',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SalonEditorScreen(),
    ),
  ],
);
