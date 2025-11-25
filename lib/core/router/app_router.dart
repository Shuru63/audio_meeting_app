import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Screens
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/login/login_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/meeting/meeting_screen.dart';
import '../../presentation/screens/admin/admin_dashboard_screen.dart';
import '../../presentation/screens/admin/user_management_screen.dart';

// Route Names
import 'route_names.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,

    routes: [
      GoRoute(
        path: RouteNames.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      GoRoute(
        path: RouteNames.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),

      GoRoute(
        path: RouteNames.home,
        name: RouteNames.home,
        builder: (context, state) => const HomeScreen(),
      ),

      GoRoute(
        path: RouteNames.meeting,
        name: RouteNames.meeting,
        builder: (context, state) {
          final extras = state.extra;

          String meetingId = "";
          bool isHost = false;

          if (extras is Map) {
            meetingId = extras["meetingId"] ?? "";
            isHost = extras["isHost"] ?? false;
          }

          return MeetingScreen(
            meetingId: meetingId,
            isHost: isHost,
          );
        },
      ),

      GoRoute(
        path: RouteNames.adminDashboard,
        name: RouteNames.adminDashboard,
        builder: (context, state) => const AdminDashboardScreen(),
      ),

      GoRoute(
        path: RouteNames.userManagement,
        name: RouteNames.userManagement,
        builder: (context, state) => const UserManagementScreen(),
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              "Page Not Found",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.error?.toString() ?? "Unknown error",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go(RouteNames.home),
              child: const Text("Go to Home"),
            )
          ],
        ),
      ),
    ),
  );
}
