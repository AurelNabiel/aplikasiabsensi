import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../page/statistics_page.dart';
import '../../page/login_page.dart';
import '../../page/register_page.dart';
import '../../auth/providers/auth_providers.dart';
import '../../page/home_page.dart';
import '../../splash/splash_screen.dart';
import '../../core/models/activity.dart';
import '../../page/activity_list_page.dart';
import '../../page/activity_form_page.dart';
import '../../page/attendance_activity_list_page.dart';
import '../../page/task_list_page.dart';
import '../../page/profile_page.dart';
import '../../page/member_list_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(authRepo.authStateChanges),
    redirect: (context, state) {
      final loggedIn = authRepo.currentSession != null;
      final loc = state.matchedLocation;

      // Splash mengurus navigasinya sendiri.
      if (loc == '/splash') return null;

      final atAuthPage = loc == '/login' || loc == '/register';
      if (!loggedIn && !atAuthPage) return '/login';
      if (loggedIn && atAuthPage) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      // Rute utama (tab) memakai transisi fade agar perpindahan halus dan
      // navbar tidak hilang mendadak.
      GoRoute(
          path: '/home',
          pageBuilder: (_, s) => _fadePage(const HomeScreen(), s)),
      GoRoute(
          path: '/activities',
          pageBuilder: (_, s) => _fadePage(const ActivityListScreen(), s)),
      GoRoute(
        path: '/activity/form',
        builder: (_, state) =>
            ActivityFormScreen(activity: state.extra as Activity?),
      ),
      GoRoute(
          path: '/tasks',
          pageBuilder: (_, s) => _fadePage(const TaskListScreen(), s)),
      GoRoute(
          path: '/attendance',
          pageBuilder: (_, s) =>
              _fadePage(const AttendanceActivityListScreen(), s)),
      GoRoute(
          path: '/statistics',
          pageBuilder: (_, s) => _fadePage(const StatisticsScreen(), s)),
      GoRoute(
          path: '/profile',
          pageBuilder: (_, s) => _fadePage(const ProfileScreen(), s)),
      GoRoute(
          path: '/members',
          pageBuilder: (_, s) => _fadePage(const MemberListScreen(), s)),
    ],
  );
});

/// Halaman dengan transisi fade lembut (dipakai rute utama).
CustomTransitionPage _fadePage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (_, animation, __, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

/// Menjembatani stream auth Supabase ke Listenable milik go_router,
/// sehingga guard dievaluasi ulang tiap login/logout.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
