import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/dead_zone/presentation/screens/dead_zone_list_screen.dart';
import '../../features/health_survey/presentation/screens/health_survey_form_screen.dart';
import '../../features/network_test/presentation/screens/network_test_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/operator_comparison/presentation/screens/operator_comparison_screen.dart';
import '../../features/report_problem/presentation/screens/report_problem_screen.dart';
import '../../features/report_status/presentation/screens/my_reports_screen.dart';
import '../../features/school_survey/presentation/screens/school_survey_form_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/signal_map/presentation/screens/signal_map_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/statistics/presentation/screens/statistics_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: false,
  routes: <RouteBase>[
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.signup,
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: AppRoutes.dashboard,
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: AppRoutes.networkTest,
      builder: (context, state) => const NetworkTestScreen(),
    ),
    GoRoute(
      path: AppRoutes.signalMap,
      builder: (context, state) => const SignalMapScreen(),
    ),
    GoRoute(
      path: AppRoutes.deadZones,
      builder: (context, state) => const DeadZoneListScreen(),
    ),
    GoRoute(
      path: AppRoutes.reportProblem,
      builder: (context, state) => const ReportProblemScreen(),
    ),
    GoRoute(
      path: AppRoutes.myReports,
      builder: (context, state) => const MyReportsScreen(),
    ),
    GoRoute(
      path: AppRoutes.operatorComparison,
      builder: (context, state) => const OperatorComparisonScreen(),
    ),
    GoRoute(
      path: AppRoutes.statistics,
      builder: (context, state) => const StatisticsScreen(),
    ),
    GoRoute(
      path: AppRoutes.schoolSurvey,
      builder: (context, state) => const SchoolSurveyFormScreen(),
    ),
    GoRoute(
      path: AppRoutes.healthSurvey,
      builder: (context, state) => const HealthSurveyFormScreen(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);

final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((ref) {
  return appRouter;
});

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String dashboard = '/dashboard';
  static const String networkTest = '/network-test';
  static const String signalMap = '/signal-map';
  static const String deadZones = '/dead-zones';
  static const String reportProblem = '/report-problem';
  static const String myReports = '/my-reports';
  static const String operatorComparison = '/operator-comparison';
  static const String statistics = '/statistics';
  static const String schoolSurvey = '/school-survey';
  static const String healthSurvey = '/health-survey';
  static const String settings = '/settings';
}
