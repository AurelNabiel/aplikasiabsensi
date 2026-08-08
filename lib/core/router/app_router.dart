import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/page/statistics_screen.dart';
import '../../features/auth/page/login_screen.dart';
import '../../features/auth/page/register_screen.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/home/home_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../core/models/activity.dart';
import '../../features/auth/page/activity_list_screen.dart';
import '../../features/auth/page/activity_form_screen.dart';
import '../../features/auth/page/attendance_activity_list_screen.dart';
import '../../features/auth/page/task_list_screen.dart';
import '../../features/auth/page/profile_screen.dart';
import '../../features/auth/page/member_list_screen.dart';

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
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(
          path: '/activities', builder: (_, __) => const ActivityListScreen()),
      GoRoute(
        path: '/activity/form',
        builder: (_, state) =>
            ActivityFormScreen(activity: state.extra as Activity?),
      ),
      GoRoute(path: '/tasks', builder: (_, __) => const TaskListScreen()),
      GoRoute(
          path: '/attendance',
          builder: (_, __) => const AttendanceActivityListScreen()),
      GoRoute(
          path: '/statistics', builder: (_, __) => const StatisticsScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/members', builder: (_, __) => const MemberListScreen()),
    ],
  );
});

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
