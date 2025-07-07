import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supervisor_wo/core/blocs/auth/auth.dart';
import 'package:supervisor_wo/presentation/screens/home_screen.dart';
import 'package:supervisor_wo/presentation/widgets/auto_update_wrapper.dart';
import 'package:supervisor_wo/presentation/screens/splash_screen.dart';
import 'package:supervisor_wo/presentation/screens/modern_profile_screen.dart';
import 'package:supervisor_wo/presentation/screens/reports_screen.dart';
import 'package:supervisor_wo/presentation/screens/completed_reports_screen.dart';
import 'package:supervisor_wo/presentation/screens/school_reports_screen.dart';
import 'package:supervisor_wo/presentation/screens/maintenance_screen.dart';
import 'package:supervisor_wo/presentation/screens/school_maintenance_reports_screen.dart';
import 'package:supervisor_wo/presentation/screens/report_completion_screen.dart';
import 'package:supervisor_wo/presentation/screens/maintenance_completion_screen.dart';
import 'package:supervisor_wo/presentation/screens/completion_rate_screen.dart';
import 'package:supervisor_wo/presentation/screens/edit_profile_screen.dart';
import 'package:supervisor_wo/presentation/screens/maintenance_schools_screen.dart';
import 'package:supervisor_wo/presentation/screens/maintenance_count_form_screen.dart';
import 'package:supervisor_wo/presentation/screens/damage_schools_screen.dart';
import 'package:supervisor_wo/presentation/screens/damage_count_form_screen.dart';
import 'package:supervisor_wo/presentation/screens/schools_list_screen.dart';
import 'package:supervisor_wo/presentation/screens/school_options_screen.dart';
import 'package:supervisor_wo/models/school_model.dart';
import 'package:supervisor_wo/models/maintenance_count_model.dart';
import 'package:supervisor_wo/models/damage_count_model.dart';
import 'package:supervisor_wo/models/report_model.dart';
import 'package:supervisor_wo/models/maintenance_report_model.dart';
import 'package:supervisor_wo/models/user_profile.dart';
import 'package:supervisor_wo/core/blocs/reports/reports_state.dart';

import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/stepper_signup_screen.dart';

/// The router configuration for the app
final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  redirect: (BuildContext context, GoRouterState state) {
    final authBloc = context.read<AuthBloc>();
    final authState = authBloc.state;
    final isAuthRoute = state.matchedLocation == '/login' ||
        state.matchedLocation == '/signup' ||
        state.matchedLocation == '/stepper-signup';
    final isSplashRoute = state.matchedLocation == '/splash';

    // Don't redirect while on splash screen and auth is still checking status
    if (isSplashRoute && authState.status == AuthStatus.initial) {
      return null;
    }

    // If not authenticated and not on an auth route or splash, redirect to login
    if (!authState.isAuthenticated && !isAuthRoute && !isSplashRoute) {
      return '/login';
    }

    // If authenticated and on an auth route or splash, redirect to home
    if (authState.isAuthenticated && (isAuthRoute || isSplashRoute)) {
      return '/';
    }

    // No redirection needed
    return null;
  },
  routes: [
    // Splash screen
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),

    // Authentication routes
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    // GoRoute(
    //   path: '/signup',
    //   name: 'signup',
    //   builder: (context, state) => const SignupScreen(),
    // ),
    GoRoute(
      path: '/stepper-signup',
      name: 'stepper_signup',
      builder: (context, state) => const StepperSignupScreen(),
    ),
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const AutoUpdateWrapper(
        child: HomeScreen(),
      ),
    ),
    GoRoute(
      path: '/reports',
      name: 'reports',
      builder: (context, state) => const ReportsScreen(),
    ),
    GoRoute(
      path: '/reports/today',
      name: 'reports_today',
      builder: (context, state) =>
          const ReportsScreen(filter: ReportFilter.today),
    ),
    GoRoute(
      path: '/reports/completed',
      name: 'reports_completed',
      builder: (context, state) => const CompletedReportsScreen(),
    ),
    GoRoute(
      path: '/reports/late-completed',
      name: 'reports_late_completed',
      builder: (context, state) =>
          const ReportsScreen(filter: ReportFilter.lateCompleted),
    ),
    GoRoute(
      path: '/reports/late',
      name: 'reports_late',
      builder: (context, state) =>
          const ReportsScreen(filter: ReportFilter.late),
    ),

    // GoRoute(
    //   path: '/profile',
    //   name: 'profile',
    //   builder: (context, state) => const ProfileScreen(),
    // ),
    GoRoute(
      path: '/modern-profile',
      name: 'modern_profile',
      builder: (context, state) => const ModernProfileScreen(),
    ),
    GoRoute(
      path: '/edit-profile',
      name: 'edit_profile',
      builder: (context, state) {
        final profile = state.extra as UserProfile;
        return EditProfileScreen(profile: profile);
      },
    ),
    GoRoute(
      path: '/maintenance',
      name: 'maintenance',
      builder: (context, state) => const MaintenanceScreen(),
    ),
    GoRoute(
      path: '/school-maintenance/:schoolId',
      name: 'school_maintenance',
      builder: (context, state) {
        final schoolId = state.pathParameters['schoolId'] ?? '';
        String? schoolName;

        // Handle both Map and String formats for backward compatibility
        if (state.extra is Map<String, dynamic>) {
          final extraData = state.extra as Map<String, dynamic>;
          schoolName = extraData['schoolName'] as String?;
        } else {
          schoolName = state.extra as String?;
        }

        return SchoolMaintenanceReportsScreen(
            schoolId: schoolId, schoolName: schoolName);
      },
    ),
    // GoRoute(
    //   path: '/schools',
    //   name: 'schools',
    //   builder: (context, state) => const SchoolsScreen(),
    // ),
    GoRoute(
      path: '/school-details',
      name: 'school_details',
      builder: (context, state) {
        final school = state.extra as School;
        // For now, we'll just show a placeholder screen
        return Scaffold(
          appBar: AppBar(title: Text(school.name)),
          body: Center(
            child: Text('School details coming soon'),
          ),
        );
      },
    ),
    GoRoute(
      path: '/school-reports',
      name: 'school_reports',
      builder: (context, state) {
        // Handle both old and new format for backward compatibility
        if (state.extra is Map<String, dynamic>) {
          final extraData = state.extra as Map<String, dynamic>;
          final schoolName = extraData['schoolName'] as String;
          final filter = extraData['filter'] as ReportFilter?;
          return SchoolReportsScreen(schoolName: schoolName, filter: filter);
        } else {
          // Legacy format - just the school name as a string
          final schoolName = state.extra as String;
          return SchoolReportsScreen(schoolName: schoolName);
        }
      },
    ),
    // Route for report completion screen
    GoRoute(
      path: '/completion-screen',
      name: 'completion_screen',
      builder: (context, state) {
        final report = state.extra as Report;
        return ReportCompletionScreen(report: report);
      },
    ),
    // Route for maintenance completion screen
    GoRoute(
      path: '/maintenance-completion-screen',
      name: 'maintenance_completion_screen',
      builder: (context, state) {
        final report = state.extra as MaintenanceReport;
        return MaintenanceCompletionScreen(report: report);
      },
    ),
    // Removed duplicate late reports route since we now use /reports/late with filter
    // GoRoute(
    //   path: '/late-reports',
    //   name: 'late_reports',
    //   builder: (context, state) => const LateReportsScreen(),
    // ),

    // Maintenance schools routes
    GoRoute(
      path: '/maintenance-schools',
      name: 'maintenance_schools',
      builder: (context, state) => const MaintenanceSchoolsScreen(),
    ),
    GoRoute(
      path: '/maintenance-count-form/:schoolId',
      name: 'maintenance_count_form',
      builder: (context, state) {
        final schoolId = state.pathParameters['schoolId'] ?? '';
        String schoolName = 'مدرسة';
        bool isEdit = false;
        MaintenanceCountModel? existingCount;

        if (state.extra is Map<String, dynamic>) {
          final extraData = state.extra as Map<String, dynamic>;
          schoolName = extraData['schoolName'] as String? ?? schoolName;
          isEdit = extraData['isEdit'] as bool? ?? false;
          existingCount = extraData['existingCount'] as MaintenanceCountModel?;
        }

        return MaintenanceCountFormScreen(
          schoolId: schoolId,
          schoolName: schoolName,
          isEdit: isEdit,
          existingCount: existingCount,
        );
      },
    ),

    // Damage count routes
    GoRoute(
      path: '/damage-schools',
      name: 'damage_schools',
      builder: (context, state) => const DamageSchoolsScreen(),
    ),
    GoRoute(
      path: '/damage-count-form/:schoolId',
      name: 'damage_count_form',
      builder: (context, state) {
        final schoolId = state.pathParameters['schoolId'] ?? '';
        String schoolName = 'مدرسة';
        bool isEdit = false;
        DamageCountModel? existingCount;

        if (state.extra is Map<String, dynamic>) {
          final extraData = state.extra as Map<String, dynamic>;
          schoolName = extraData['schoolName'] as String? ?? schoolName;
          isEdit = extraData['isEdit'] as bool? ?? false;
          existingCount = extraData['existingCount'] as DamageCountModel?;
        }

        return DamageCountFormScreen(
          schoolId: schoolId,
          schoolName: schoolName,
          isEdit: isEdit,
          existingCount: existingCount,
        );
      },
    ),

    // Completion rate screen route
    GoRoute(
      path: '/completion-rate',
      name: 'completion_rate',
      builder: (context, state) => const CompletionRateScreen(),
    ),

    // Schools list route
    GoRoute(
      path: '/schools-list',
      name: 'schools_list',
      builder: (context, state) => const SchoolsListScreen(),
    ),

    // School options route
    GoRoute(
      path: '/school-options',
      name: 'school_options',
      builder: (context, state) {
        final school = state.extra as School;
        return SchoolOptionsScreen(school: school);
      },
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Error: ${state.error}'),
    ),
  ),
);
